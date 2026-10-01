<?php
/**
 * Deccan Finance - Record Transaction API
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
$required = ['recipient_account', 'amount', 'type'];
foreach ($required as $field) {
    if (empty($data[$field])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Field ' . str_replace('_', ' ', $field) . ' is required.'
        ]);
        exit;
    }
}

$recipientAccount = trim($data['recipient_account']);
$amount = (float)$data['amount'];
$type = strtoupper(trim($data['type']));
$utrId = isset($data['utr_id']) ? trim($data['utr_id']) : null;

// Validate amount
if ($amount <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Amount must be greater than 0.'
    ]);
    exit;
}

// Validate type
if ($type !== 'P2P' && $type !== 'BANK_TRANSFER') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid transaction type. Must be P2P or BANK_TRANSFER.'
    ]);
    exit;
}

// If BANK_TRANSFER, get UTR ID from parameter (e.g. from bank)
if ($type === 'BANK_TRANSFER' && empty($utrId)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'UTR ID is required for bank transfer.'
    ]);
    exit;
}

$senderAppId = $_SESSION['customer_app_id'];

try {
    // Record transaction
    $remarks = isset($data['remarks']) ? trim($data['remarks']) : null;
    $txn = record_transaction($senderAppId, $recipientAccount, $amount, $type, $utrId, 'SUCCESS', null, null, null, null, $remarks);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Transaction recorded successfully.',
        'transaction_id' => $txn['transaction_id'],
        'utr_id' => $txn['utr_id']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while recording transaction: ' . $e->getMessage()
    ]);
}
