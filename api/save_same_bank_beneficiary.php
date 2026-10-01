<?php
/**
 * Deccan Finance - Save Same Bank Beneficiary API
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

// Check if customer is logged in
if (empty($_SESSION['customer_logged_in']) || empty($_SESSION['customer_app_id'])) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
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
if (empty($data['beneficiary_account_number'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Field beneficiary_account_number is required.'
    ]);
    exit;
}

$beneficiaryAccountNumber = trim($data['beneficiary_account_number']);

if (!preg_match('/^\d{11}$/', $beneficiaryAccountNumber)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Beneficiary account number must be exactly 11 digits.'
    ]);
    exit;
}

$senderAppId = $_SESSION['customer_app_id'];

try {
    // 1. Fetch beneficiary account details
    $beneficiaryAccount = get_account_by_number($beneficiaryAccountNumber);
    if (!$beneficiaryAccount) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Beneficiary account number not found in Deccan Finance.'
        ]);
        exit;
    }
    
    // 2. Prevent adding own account
    if ($beneficiaryAccount['app_id'] === $senderAppId) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'You cannot add your own account as a beneficiary.'
        ]);
        exit;
    }
    
    // 3. Resolve recipient full name
    $beneficiaryName = !empty($data['beneficiary_name']) ? trim($data['beneficiary_name']) : '';
    if (empty($beneficiaryName)) {
        $beneficiaryUser = get_application_by_id($beneficiaryAccount['app_id']);
        if ($beneficiaryUser) {
            $beneficiaryName = $beneficiaryUser['full_name'];
        } else {
            $beneficiaryName = 'Deccan Finance Account';
        }
    }
    
    // 4. Save beneficiary
    add_beneficiary($senderAppId, 'SELF_BANK', $beneficiaryName, $beneficiaryAccountNumber, null, 0.00, null, 'APPROVED');
    
    // Send push notification
    $notifyTitle = "Same Bank Beneficiary Added";
    $notifyBody = "Beneficiary " . $beneficiaryName . " (Acc: " . $beneficiaryAccountNumber . ") has been added and approved.";
    send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Updates');
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Same bank beneficiary added and approved successfully.',
        'beneficiary' => [
            'beneficiary_name' => $beneficiaryName,
            'beneficiary_account_number' => $beneficiaryAccountNumber,
            'type' => 'SELF_BANK',
            'status' => 'APPROVED'
        ]
    ]);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
