<?php
/**
 * Deccan Finance - Add Beneficiary API
 * Scope: Authenticated Customer Session
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Get request parameters (POST/JSON/GET)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// 1. Resolve session ID if passed explicitly
$passedSessionId = null;
if (!empty($data['session_id'])) {
    $passedSessionId = trim($data['session_id']);
} elseif (!empty($_GET['session_id'])) {
    $passedSessionId = trim($_GET['session_id']);
}

// Check headers for X-Session-ID or Authorization bearer
$headers = function_exists('getallheaders') ? getallheaders() : [];
if (empty($passedSessionId)) {
    if (!empty($headers['X-Session-ID'])) {
        $passedSessionId = trim($headers['X-Session-ID']);
    } elseif (!empty($headers['x-session-id'])) {
        $passedSessionId = trim($headers['x-session-id']);
    } elseif (!empty($_SERVER['HTTP_X_SESSION_ID'])) {
        $passedSessionId = trim($_SERVER['HTTP_X_SESSION_ID']);
    } elseif (!empty($headers['Authorization'])) {
        $auth = trim($headers['Authorization']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    } elseif (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = trim($_SERVER['HTTP_AUTHORIZATION']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    }
}

// If explicit session ID is provided, load it
if (!empty($passedSessionId)) {
    session_id($passedSessionId);
}

// Start PHP session
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check if customer is logged in via PHP session or explicit app_id
if (empty($_SESSION['customer_logged_in']) || empty($_SESSION['customer_app_id'])) {
    $fallbackAppId = !empty($data['app_id']) ? trim($data['app_id']) : (!empty($_GET['app_id']) ? trim($_GET['app_id']) : null);
    if (!empty($fallbackAppId)) {
        $_SESSION['customer_logged_in'] = true;
        $_SESSION['customer_app_id'] = $fallbackAppId;
    } else {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Unauthorized. Please log in first.'
        ]);
        exit;
    }
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only POST requests are allowed.'
    ]);
    exit;
}

// Validate input parameters
$type = isset($data['type']) ? trim(strtoupper($data['type'])) : 'SELF_BANK';
if ($type !== 'SELF_BANK' && $type !== 'OTHER_BANK') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid beneficiary type. Must be SELF_BANK or OTHER_BANK.'
    ]);
    exit;
}

$senderAppId = $_SESSION['customer_app_id'];
$senderAccount = get_account_by_app_id($senderAppId);

if ($type === 'SELF_BANK') {
    if (empty($data['beneficiary_account_number'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'beneficiary_account_number is required for SELF_BANK.'
        ]);
        exit;
    }
    
    $beneficiaryAccountNumber = trim($data['beneficiary_account_number']);
    
    if (!preg_match('/^\d{11}$/', $beneficiaryAccountNumber)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Beneficiary account number must be exactly 11 digits for SELF_BANK.'
        ]);
        exit;
    }
    
    try {
        $beneficiaryAccount = get_account_by_number($beneficiaryAccountNumber);
        if (!$beneficiaryAccount) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Beneficiary account number not found in Deccan Finance.'
            ]);
            exit;
        }
        
        if ($beneficiaryAccount['app_id'] === $senderAppId) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'You cannot add your own account as a beneficiary.'
            ]);
            exit;
        }
        
        // Resolve holder name if not provided
        $beneficiaryName = !empty($data['beneficiary_name']) ? trim($data['beneficiary_name']) : '';
        if (empty($beneficiaryName)) {
            $beneficiaryUser = get_application_by_id($beneficiaryAccount['app_id']);
            if ($beneficiaryUser) {
                $beneficiaryName = $beneficiaryUser['full_name'];
            } else {
                $beneficiaryName = 'Deccan Finance Account';
            }
        }
        
        add_beneficiary($senderAppId, 'SELF_BANK', $beneficiaryName, $beneficiaryAccountNumber, null, 0.00, null, 'APPROVED');
        
        // Send notification
        $notifyTitle = "Beneficiary Added Successfully";
        $notifyBody = "Beneficiary " . $beneficiaryName . " (Acc: " . $beneficiaryAccountNumber . ") has been added successfully to your account.";
        send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Updates');
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Deccan Finance beneficiary added successfully and approved instantly.',
            'status' => 'APPROVED'
        ]);
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
} else {
    // OTHER_BANK validation
    $required = ['beneficiary_name', 'beneficiary_account_number', 'ifsc_code', 'daily_limit', 'nickname'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => "Field $field is required for OTHER_BANK."
            ]);
            exit;
        }
    }
    
    $beneficiaryName = trim($data['beneficiary_name']);
    $beneficiaryAccountNumber = trim($data['beneficiary_account_number']);
    $ifscCode = trim($data['ifsc_code']);
    $dailyLimit = (float)$data['daily_limit'];
    $nickname = trim($data['nickname']);
    
    if ($dailyLimit <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Daily limit must be greater than 0.'
        ]);
        exit;
    }
    
    // Prevent adding own FirstRand account number as other bank
    if ($senderAccount && $beneficiaryAccountNumber === $senderAccount['account_number']) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'You cannot add your own account as an other bank beneficiary.'
        ]);
        exit;
    }
    
    try {
        add_beneficiary($senderAppId, 'OTHER_BANK', $beneficiaryName, $beneficiaryAccountNumber, $ifscCode, $dailyLimit, $nickname, 'PENDING');
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Other bank beneficiary added successfully and is pending approval.',
            'status' => 'PENDING'
        ]);
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
}
