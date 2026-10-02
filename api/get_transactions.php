<?php
/**
 * Deccan Finance - Get User Transactions API
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

// Resolve session ID if passed explicitly
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

// Allow both GET and POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only GET or POST requests are allowed.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    $transactions = get_transactions_by_app_id($appId);
    
    $formatted = [];
    foreach ($transactions as $t) {
        $formatted[] = [
            'id' => (int)$t['id'],
            'transaction_id' => $t['transaction_id'],
            'sender_app_id' => $t['sender_app_id'],
            'sender_name' => $t['sender_name'],
            'recipient_account' => $t['recipient_account'],
            'recipient_name' => $t['recipient_name'],
            'amount' => (float)$t['amount'],
            'type' => $t['type'],
            'flow_type' => $t['flow_type'],
            'utr_id' => $t['utr_id'],
            'status' => ($t['status'] === 'FAILED_HELD') ? 'PENDING' : $t['status'],
            'remarks' => $t['remarks'],
            'created_at' => $t['created_at']
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'transactions' => $formatted
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while retrieving transactions: ' . $e->getMessage()
    ]);
}
