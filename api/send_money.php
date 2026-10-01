<?php
/**
 * Deccan Finance - Send Money API (P2P Money Transfer)
 * Scope: Authenticated Customer Session (Approved Account)
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

// Resolve recipient account number (allow either account_number or recipient_account_number)
$recipientAcc = '';
if (!empty($data['account_number'])) {
    $recipientAcc = trim($data['account_number']);
} elseif (!empty($data['recipient_account_number'])) {
    $recipientAcc = trim($data['recipient_account_number']);
}

// Validate input parameters
if (empty($recipientAcc)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Field account number is required.'
    ]);
    exit;
}

if (empty($data['amount'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Field amount is required.'
    ]);
    exit;
}

if (empty($data['mpin'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Field mpin is required.'
    ]);
    exit;
}

$amount = (float)$data['amount'];
$mpin = trim($data['mpin']);

if ($amount <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Amount must be greater than 0.'
    ]);
    exit;
}

$senderAppId = $_SESSION['customer_app_id'];

try {
    // 1. Fetch sender's account and application details
    $senderAccount = get_account_by_app_id($senderAppId);
    $senderUser = get_application_by_id($senderAppId);
    
    if (!$senderAccount) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Sender account is not approved.'
        ]);
        exit;
    }
    
    // 2. Verify sender's MPIN
    if (empty($senderAccount['mpin_hash'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'MPIN not set. Please create your MPIN first.'
        ]);
        exit;
    }
    
    if (!password_verify($mpin, $senderAccount['mpin_hash'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid MPIN.'
        ]);
        exit;
    }
    
    // 3. Verify sender balance
    $senderBalance = (float)$senderUser['balance'];
    if ($senderBalance < $amount) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Insufficient account balance.'
        ]);
        exit;
    }
    
    // 4. Fetch recipient account details
    $recipientAccount = get_account_by_number($recipientAcc);
    if (!$recipientAccount) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Recipient account number not found.'
        ]);
        exit;
    }
    
    $recipientAppId = $recipientAccount['app_id'];
    
    // Cannot transfer to yourself
    if ($recipientAppId === $senderAppId) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Cannot transfer funds to your own account.'
        ]);
        exit;
    }
    
    // 5. Execute P2P transfer
    execute_p2p_transfer($senderAppId, $recipientAppId, $amount);
    
    // Record transaction in DB (type P2P generates 12-digit numeric UTR)
    $remarks = isset($data['remarks']) ? trim($data['remarks']) : null;
    $txnRecord = record_transaction($senderAppId, $recipientAcc, $amount, 'P2P', null, 'SUCCESS', null, null, null, null, $remarks);
    
    // Send "Payment Received" notification to recipient
    $notifyTitle = "Payment Received";
    $notifyBody = "You have received " . number_format($amount, 2) . " INR from " . $senderUser['full_name'] . "." . ($remarks ? " Remarks: " . $remarks . "." : "") . " UTR: " . $txnRecord['utr_id'];
    send_notification_to_user($recipientAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');

    // Send "Payment Sent" notification to sender (debit alert)
    $senderNotifyTitle = "Account Debited";
    $senderNotifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for transfer to " . $recipientAcc . "." . ($remarks ? " Remarks: " . $remarks . "." : "") . " UTR: " . $txnRecord['utr_id'];
    send_notification_to_user($senderAppId, $senderNotifyTitle, $senderNotifyBody, [], null, 'Transactions');
    
    // Retrieve new balance
    $updatedSenderUser = get_application_by_id($senderAppId);
    $newBalance = (float)$updatedSenderUser['balance'];
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Transfer of ' . number_format($amount, 2) . ' INR was successful.',
        'transaction_id' => $txnRecord['transaction_id'],
        'utr_id' => $txnRecord['utr_id'],
        'new_balance' => $newBalance
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred during transfer: ' . $e->getMessage()
    ]);
}
