<?php
/**
 * Deccan Finance - PayIn Webhook Handler
 * Receives deposit callback alerts from the payment gateway provider.
 * SUCCESS transitions transaction to SUCCESS, credits balance, and alerts the customer.
 */

header('Content-Type: application/json');
require_once 'db_helper.php';
require_once 'email_service.php';

// Retrieve payload (JSON or urlencoded POST)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// Log webhook request for debugging/audit trails
$logDir = __DIR__ . '/logs';
if (!is_dir($logDir)) {
    mkdir($logDir, 0777, true);
}
$logEntry = [
    'time' => date('Y-m-d H:i:s'),
    'ip' => get_client_ip(),
    'payload' => $data
];
file_put_contents($logDir . '/payin_webhook.log', json_encode($logEntry) . "\n", FILE_APPEND);

// Extract parameters (with fallback keys)
$orderId = !empty($data['order_id']) ? trim($data['order_id']) : (!empty($data['transaction_id']) ? trim($data['transaction_id']) : '');
$amount = isset($data['amount']) ? (float)$data['amount'] : (isset($data['txn_amount']) ? (float)$data['txn_amount'] : 0.00);
$status = !empty($data['status']) ? trim($data['status']) : (!empty($data['txn_status']) ? trim($data['txn_status']) : '');
$utr = !empty($data['utr']) ? trim($data['utr']) : (!empty($data['utr_id']) ? trim($data['utr_id']) : (!empty($data['ref_no']) ? trim($data['ref_no']) : null));
$msg = !empty($data['msg']) ? trim($data['msg']) : (!empty($data['message']) ? trim($data['message']) : 'Payin status update');

if (empty($orderId)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing order_id or transaction_id parameter.'
    ]);
    exit;
}

try {
    $pdo = get_db_connection();
    
    // Find if transaction already exists in our system
    $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :order_id LIMIT 1");
    $stmt->execute([':order_id' => $orderId]);
    $txn = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $statusUpper = strtoupper($status);
    
    if ($txn) {
        // Webhook handles status updates for existing transactions
        if ($txn['status'] === 'SUCCESS') {
            echo json_encode([
                'success' => true,
                'message' => 'Transaction already processed as SUCCESS.'
            ]);
            exit;
        }
        
        if ($statusUpper === 'SUCCESS') {
            update_transaction_status($orderId, 'SUCCESS', $utr, 'Payin completed via webhook');
            echo json_encode([
                'success' => true,
                'message' => 'Transaction marked as SUCCESS and user balance credited.'
            ]);
        } else if ($statusUpper === 'FAILED' || $statusUpper === 'REJECTED') {
            update_transaction_status($orderId, 'FAILED', $utr, $msg);
            echo json_encode([
                'success' => true,
                'message' => 'Transaction marked as FAILED.'
            ]);
        } else {
            echo json_encode([
                'success' => true,
                'message' => 'Ignored non-terminal status callback: ' . $status
            ]);
        }
    } else {
        // Transaction not pre-registered. Attempt to resolve customer from metadata
        $appId = !empty($data['app_id']) ? trim($data['app_id']) : (!empty($data['sender_app_id']) ? trim($data['sender_app_id']) : (!empty($data['customer_id']) ? trim($data['customer_id']) : ''));
        $accountNum = !empty($data['account_number']) ? trim($data['account_number']) : '';
        
        $customer = null;
        if (!empty($appId)) {
            $customer = get_application_by_id($appId);
        } elseif (!empty($accountNum)) {
            $accRecord = get_account_by_number($accountNum);
            if ($accRecord) {
                $appId = $accRecord['app_id'];
                $customer = get_application_by_id($appId);
            }
        }
        
        if (!$customer || empty($appId)) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Transaction record not found and customer could not be resolved.'
            ]);
            exit;
        }
        
        if ($statusUpper !== 'SUCCESS') {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Transaction ignored because status was not SUCCESS and no pre-registered record exists.'
            ]);
            exit;
        }
        
        // Retrieve account details
        $accRecord = get_account_by_app_id($appId);
        $accountNumber = $accRecord ? $accRecord['account_number'] : '';
        
        if (empty($accountNumber)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Resolved customer does not have an active bank account number.'
            ]);
            exit;
        }
        
        // Record new deposit transaction and credit balance
        $pdo->beginTransaction();
        
        // Insert transaction
        $stmtInsert = $pdo->prepare("INSERT INTO transactions (transaction_id, sender_app_id, recipient_account, amount, type, utr_id, status, recipient_name, ifsc_code, provider, status_details) 
                                     VALUES (:transaction_id, 'SYSTEM', :recipient_account, :amount, 'DEPOSIT', :utr_id, 'SUCCESS', :recipient_name, NULL, 'bharat4u', 'Payin completed via webhook')");
        $stmtInsert->execute([
            ':transaction_id' => $orderId,
            ':recipient_account' => $accountNumber,
            ':amount' => $amount,
            ':utr_id' => $utr,
            ':recipient_name' => $customer['full_name']
        ]);
        
        // Credit balance
        $stmtCredit = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :app_id");
        $stmtCredit->execute([
            ':amount' => $amount,
            ':app_id' => $appId
        ]);
        
        $pdo->commit();
        
        // Trigger alerts
        try {
            EmailService::sendNotificationEmail($accountNumber, 'credit', $amount, $utr, 'Deposit completed via gateway callback');
        } catch (Exception $mailEx) {
            error_log("Failed to send payin email alert: " . $mailEx->getMessage());
        }
        
        try {
            $notifyTitle = "Account Credited";
            $notifyBody = "Your account has been credited by " . number_format($amount, 2) . " INR. UTR: " . $utr;
            send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
        } catch (Exception $notifEx) {
            error_log("Failed to send payin push notification alert: " . $notifEx->getMessage());
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'New transaction recorded as SUCCESS and user balance credited.'
        ]);
    }
} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error processing payin webhook: ' . $e->getMessage()
    ]);
}
