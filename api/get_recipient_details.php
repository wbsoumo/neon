<?php
/**
 * Deccan Finance - Get Recipient Details by Account Number API
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

// Validate account number
$accountNumber = isset($data['account_number']) ? trim($data['account_number']) : '';
if (empty($accountNumber)) {
    $accountNumber = isset($_GET['account_number']) ? trim($_GET['account_number']) : '';
}

if (empty($accountNumber)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Account number is required.'
    ]);
    exit;
}

try {
    // Fetch recipient account details
    $recipientAccount = get_account_by_number($accountNumber);
    if (!$recipientAccount) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Recipient account number not found.'
        ]);
        exit;
    }
    
    $recipientAppId = $recipientAccount['app_id'];
    $recipientUser = get_application_by_id($recipientAppId);
    
    if (!$recipientUser) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Recipient profile details not found.'
        ]);
        exit;
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'recipient' => [
            'full_name' => $recipientUser['full_name'],
            'account_number' => $recipientAccount['account_number']
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while fetching recipient details: ' . $e->getMessage()
    ]);
}
