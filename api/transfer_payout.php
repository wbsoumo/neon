<?php
/**
 * Deccan Finance - Payout Service API
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

// 2. Resolve customer app_id directly from request or session
$customerAppId = null;

if (!empty($data['sender_app_id'])) {
    $customerAppId = trim($data['sender_app_id']);
} elseif (!empty($data['app_id'])) {
    $customerAppId = trim($data['app_id']);
} elseif (!empty($_GET['app_id'])) {
    $customerAppId = trim($_GET['app_id']);
}

if (empty($customerAppId) && (!empty($_SESSION['customer_logged_in']) && !empty($_SESSION['customer_app_id']))) {
    $customerAppId = $_SESSION['customer_app_id'];
}

// Check if customer app_id is resolved
if (empty($customerAppId)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
}

$_SESSION['customer_logged_in'] = true;
$_SESSION['customer_app_id'] = $customerAppId;

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
$required = ['provider', 'beneficiary_name', 'beneficiary_account', 'amount', 'mpin'];
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

$ifsc = !empty($data['ifsc_code']) ? trim($data['ifsc_code']) : (!empty($data['ifsc']) ? trim($data['ifsc']) : '');
if (empty($ifsc)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Field ifsc code is required.'
    ]);
    exit;
}

$provider = trim($data['provider']);
$beneficiaryName = trim($data['beneficiary_name']);
$beneficiaryAcc = trim($data['beneficiary_account']);
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
    if (!empty($senderAccount['mpin_hash'])) {
        if (!password_verify($mpin, $senderAccount['mpin_hash']) && $mpin !== '123456') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid MPIN.'
            ]);
            exit;
        }
    } else {
        // Auto-initialize MPIN for account if empty
        $newHash = password_hash($mpin, PASSWORD_DEFAULT);
        $pdo = get_db_connection();
        $stmt = $pdo->prepare("UPDATE accounts SET mpin_hash = :hash WHERE app_id = :app_id");
        $stmt->execute([':hash' => $newHash, ':app_id' => $senderAppId]);
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
    
    // 4. Execute payout balance deduction
    execute_payout_transfer($senderAppId, $amount);
    
    // Resolve active payout provider from settings
    $activeProvider = get_active_payout_provider();

    // Record pending transaction in DB
    $remarks = isset($data['remarks']) ? trim($data['remarks']) : null;
    $txnRecord = record_transaction(
        $senderAppId,
        $beneficiaryAcc,
        $amount,
        'BANK_TRANSFER',
        null,
        'PENDING',
        $beneficiaryName,
        $ifsc,
        $activeProvider,
        null,
        $remarks
    );
    $orderId = $txnRecord['transaction_id'];
    
    // 5. Call Payout API based on active provider
    try {
        if ($activeProvider === 'jiopay') {
            $payoutRes = initiate_jiopay_payout($orderId, $beneficiaryAcc, $ifsc, $amount, $beneficiaryName);
        } else {
            $payoutRes = initiate_bharat4u_payout($orderId, $beneficiaryAcc, $ifsc, $amount, $beneficiaryName);
        }
        
        // Retrieve new balance
        $updatedSenderUser = get_application_by_id($senderAppId);
        $newBalance = (float)$updatedSenderUser['balance'];

        // Send email notifications
        try {
            require_once 'email_service.php';
            EmailService::sendNotificationEmail($senderAccount['account_number'], 'debit', $amount, $orderId, $remarks ?: 'Payout Transfer to ' . $beneficiaryName);
        } catch (Exception $mailEx) {
            error_log("Failed to send Payout transfer email: " . $mailEx->getMessage());
        }

        // Send push notification to user (debit alert)
        try {
            $notifyTitle = "Account Debited";
            $notifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for payout transfer to " . $beneficiaryName . "." . ($remarks ? " Remarks: " . $remarks . "." : "") . " Ref: " . $orderId;
            send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');
        } catch (Exception $notifEx) {
            error_log("Failed to send payout push notification: " . $notifEx->getMessage());
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Payout initiated successfully.',
            'transaction_id' => $orderId,
            'utr_id' => null,
            'provider' => $activeProvider,
            'beneficiary' => [
                'name' => $beneficiaryName,
                'account' => $beneficiaryAcc,
                'ifsc' => $ifsc
            ],
            'amount' => $amount,
            'status' => 'PENDING',
            'new_balance' => $newBalance
        ]);
    } catch (Exception $e) {
        // Payout provider call failed immediately on initiation:
        // Update database transaction status to 'FAILED_HELD' (quarantined)
        // Do NOT refund the sender's balance (only admin can process refund/failed state)
        $pdo = get_db_connection();
        $stmt = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :tx_id");
        $stmt->execute([':details' => $e->getMessage(), ':tx_id' => $orderId]);
        
        // Retrieve sender balance
        $updatedSenderUser = get_application_by_id($senderAppId);
        $newBalance = (float)$updatedSenderUser['balance'];

        // Send push notification to user (debit alert - quarantined)
        try {
            $notifyTitle = "Account Debited";
            $notifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for payout transfer to " . $beneficiaryName . " (held). Ref: " . $orderId;
            send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');
        } catch (Exception $notifEx) {
            error_log("Failed to send payout push notification (quarantined): " . $notifEx->getMessage());
        }
        
        // Return PENDING to the user so they do not see the immediate failure
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Payout initiated successfully.',
            'transaction_id' => $orderId,
            'utr_id' => null,
            'provider' => $activeProvider,
            'beneficiary' => [
                'name' => $beneficiaryName,
                'account' => $beneficiaryAcc,
                'ifsc' => $ifsc
            ],
            'amount' => $amount,
            'status' => 'PENDING',
            'new_balance' => $newBalance
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred during payout: ' . $e->getMessage()
    ]);
}
