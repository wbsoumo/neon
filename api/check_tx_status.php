<?php
/**
 * Deccan Finance - Transaction Allowed Status Check API
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
        'allowed' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
}

// Validate POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'allowed' => false,
        'message' => 'Method Not Allowed. Only POST requests are allowed.'
    ]);
    exit;
}

$senderAppId = $_SESSION['customer_app_id'];

// Resolve transaction details from request parameters
$recipientAcc = '';
if (!empty($data['recipient_account'])) {
    $recipientAcc = trim($data['recipient_account']);
} elseif (!empty($data['recipient_account_number'])) {
    $recipientAcc = trim($data['recipient_account_number']);
} elseif (!empty($data['account_number'])) {
    $recipientAcc = trim($data['account_number']);
}

$amount = (float)($data['amount'] ?? 0);
$type = strtoupper(trim($data['type'] ?? 'P2P'));
$recipientName = !empty($data['recipient_name']) ? trim($data['recipient_name']) : null;
$ifsc = !empty($data['ifsc_code']) ? trim($data['ifsc_code']) : (!empty($data['ifsc']) ? trim($data['ifsc']) : null);

// Check transaction enablement status
$txStatus = check_user_tx_status($senderAppId);

if (!$txStatus['enabled']) {
    $errMsg = $txStatus['message'];
    
    // Log a FAILED transaction in the database
    try {
        $txnRecord = record_transaction(
            $senderAppId,
            $recipientAcc ?: 'N/A',
            $amount,
            $type ?: 'P2P',
            null,
            'FAILED',
            $recipientName,
            $ifsc,
            null,
            $errMsg,
            'Transaction disabled'
        );
        $transactionId = $txnRecord['transaction_id'];
    } catch (\Exception $dbEx) {
        $transactionId = null;
    }
    
    // Fetch sender info for alerts
    try {
        $user = get_application_by_id($senderAppId);
        $account = get_account_by_app_id($senderAppId);
        $accountNumber = $account ? $account['account_number'] : '';

        // 1. Send Push Notification
        $notifTitle = "Transaction Failed";
        $notifBody = "Your transaction of " . number_format($amount, 2) . " INR to " . ($recipientAcc ?: 'N/A') . " failed. Reason: " . $errMsg;
        send_notification_to_user($senderAppId, $notifTitle, $notifBody, [], null, 'Security');
    } catch (\Exception $e) {
        error_log("Failed to send push notification: " . $e->getMessage());
    }

    // 2. Send Email
    try {
        if ($user && $accountNumber) {
            require_once 'email_service.php';
            EmailService::sendNotificationEmail($accountNumber, 'failed', $amount, $errMsg, $recipientAcc);
        }
    } catch (\Exception $e) {
        error_log("Failed to send email notification: " . $e->getMessage());
    }

    http_response_code(400);
    echo json_encode([
        'success' => false,
        'allowed' => false,
        'message' => 'Payment Failed: ' . $errMsg,
        'transaction_id' => $transactionId
    ]);
    exit;
}

// Transaction is allowed
http_response_code(200);
echo json_encode([
    'success' => true,
    'allowed' => true,
    'message' => 'Transaction allowed.'
]);
exit;
