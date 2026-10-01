<?php
/**
 * Deccan Finance - Payout Webhook Handler
 * Receives callback alerts from the payout gateway provider.
 * SUCCESS transitions transaction to SUCCESS (with UTR).
 * FAILED/REJECTED transitions transaction to FAILED_HELD (quarantined).
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

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
file_put_contents($logDir . '/payout_webhook.log', json_encode($logEntry) . "\n", FILE_APPEND);

// Extract parameters
$orderId = !empty($data['order_id']) ? trim($data['order_id']) : (!empty($data['transaction_id']) ? trim($data['transaction_id']) : '');
$status = !empty($data['status']) ? trim($data['status']) : (!empty($data['txn_status']) ? trim($data['txn_status']) : '');
$utr = !empty($data['utr']) ? trim($data['utr']) : (!empty($data['utr_id']) ? trim($data['utr_id']) : null);
$msg = !empty($data['msg']) ? trim($data['msg']) : (!empty($data['message']) ? trim($data['message']) : 'Webhook status update');

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
    
    // Find transaction
    $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :order_id LIMIT 1");
    $stmt->execute([':order_id' => $orderId]);
    $txn = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$txn) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Transaction record not found.'
        ]);
        exit;
    }
    
    // Webhook should only update PENDING transactions
    if ($txn['status'] !== 'PENDING') {
        echo json_encode([
            'success' => true,
            'message' => 'Transaction already processed. Current status: ' . $txn['status']
        ]);
        exit;
    }
    
    $statusUpper = strtoupper($status);
    
    if ($statusUpper === 'SUCCESS') {
        // Mark as SUCCESS and save UTR
        $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'SUCCESS', utr_id = :utr, status_details = 'Payout completed via webhook' WHERE transaction_id = :order_id");
        $stmtUpdate->execute([':utr' => $utr, ':order_id' => $orderId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Transaction marked as SUCCESS.'
        ]);
    } else if ($statusUpper === 'FAILED' || $statusUpper === 'REJECTED') {
        // Mark as FAILED_HELD (quarantine for admin manual check/action)
        $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :order_id");
        $stmtUpdate->execute([':details' => $msg, ':order_id' => $orderId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Transaction marked as FAILED_HELD and quarantined.'
        ]);
    } else {
        // Do nothing if it is still PENDING or some other status
        echo json_encode([
            'success' => true,
            'message' => 'Ignored non-terminal status callback: ' . $status
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error processing webhook: ' . $e->getMessage()
    ]);
}
