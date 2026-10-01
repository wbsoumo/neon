<?php
/**
 * Deccan Finance - Cron Payout V4 Status Checker
 * Polls the Bharat4u status check V4 API for PENDING, PROCESSING, or FAILED_HELD bank transfers.
 * SUCCESS transitions to SUCCESS (with UTR).
 * FAILED/REJECTED transitions to FAILED_HELD (quarantined/reviewed by admin).
 * 
 * Supports manual single transaction checks when a specific 'order_id' or 'transaction_id' is passed.
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Security check: restrict to localhost, whitelisted IPs, or CLI execution.
$clientIp = get_client_ip();
$whitelisted = get_whitelisted_ips();
if (!in_array($clientIp, $whitelisted) && php_sapi_name() !== 'cli') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden. Access restricted.']);
    exit;
}

// Get input parameters (allows calling on demand for specific order)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$orderIdParam = null;
if (!empty($data['order_id'])) {
    $orderIdParam = trim($data['order_id']);
} elseif (!empty($data['transaction_id'])) {
    $orderIdParam = trim($data['transaction_id']);
} elseif (!empty($_GET['order_id'])) {
    $orderIdParam = trim($_GET['order_id']);
} elseif (!empty($_GET['transaction_id'])) {
    $orderIdParam = trim($_GET['transaction_id']);
}

try {
    $pdo = get_db_connection();
    
    // Select transactions (Join applications to get sender full name)
    if (!empty($orderIdParam)) {
        // Checking specific transaction supplied by the client
        $stmt = $pdo->prepare("SELECT t.*, a.full_name as sender_name FROM transactions t LEFT JOIN applications a ON t.sender_app_id = a.app_id WHERE t.transaction_id = :order_id AND t.type = 'BANK_TRANSFER'");
        $stmt->execute([':order_id' => $orderIdParam]);
        $txns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } else {
        // Bulk checking: select PENDING, PROCESSING, or FAILED_HELD bank transfer transactions
        $stmt = $pdo->prepare("SELECT t.*, a.full_name as sender_name FROM transactions t LEFT JOIN applications a ON t.sender_app_id = a.app_id WHERE t.status IN ('PENDING', 'PROCESSING', 'FAILED_HELD') AND t.type = 'BANK_TRANSFER'");
        $stmt->execute();
        $txns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    $checkedCount = 0;
    $updatedCount = 0;
    $results = [];
    
    foreach ($txns as $txn) {
        $orderId = $txn['transaction_id'];
        $currentStatus = strtoupper($txn['status']);
        $checkedCount++;
        
        $baseResult = [
            'order_id' => $orderId,
            'sender_app_id' => $txn['sender_app_id'],
            'sender_name' => $txn['sender_name'] ?: 'Unknown',
            'amount' => (float)$txn['amount'],
            'old_status' => $currentStatus
        ];
        
        try {
            $txProvider = !empty($txn['provider']) ? strtolower(trim($txn['provider'])) : 'bharat4u';
            if ($txProvider === 'jiopay') {
                $res = check_jiopay_payout_status($orderId);
            } else {
                $res = check_bharat4u_payout_status_v4($orderId);
            }
            
            if (isset($res['status']) && $res['status'] === true) {
                $resData = isset($res['data']) ? $res['data'] : [];
                
                $apiStatus = '';
                if (isset($res['txn_status'])) {
                    $apiStatus = strtoupper($res['txn_status']);
                } elseif (isset($resData['txn_status'])) {
                    $apiStatus = strtoupper($resData['txn_status']);
                } elseif (isset($res['status']) && is_string($res['status'])) {
                    $apiStatus = strtoupper($res['status']);
                } elseif (isset($resData['status'])) {
                    $apiStatus = strtoupper($resData['status']);
                }
                
                $utr = isset($res['utr']) ? trim($res['utr']) : (isset($resData['utr']) ? trim($resData['utr']) : null);
                
                if ($apiStatus === 'SUCCESS') {
                    // Update to SUCCESS and set UTR
                    $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'SUCCESS', utr_id = :utr, status_details = 'Payout completed successfully' WHERE transaction_id = :order_id");
                    $stmtUpdate->execute([':utr' => $utr, ':order_id' => $orderId]);
                    
                    // Trigger push notification to user
                    try {
                        $appId = $txn['sender_app_id'];
                        $amount = (float)$txn['amount'];
                        $notifyTitle = "Payout Successful";
                        $notifyBody = "Your payout transfer of " . number_format($amount, 2) . " INR to account " . $txn['recipient_account'] . " has been completed. UTR: " . ($utr ?: 'N/A');
                        send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                    } catch (Exception $notifEx) {
                        error_log("Failed to send payout success notification: " . $notifEx->getMessage());
                    }
                    
                    $updatedCount++;
                    $results[] = array_merge($baseResult, [
                        'new_status' => 'SUCCESS',
                        'utr' => $utr
                    ]);
                } elseif ($apiStatus === 'FAILED' || $apiStatus === 'REJECTED') {
                    // If current status is FAILED_HELD, keep it as FAILED_HELD
                    if ($currentStatus === 'FAILED_HELD') {
                        $results[] = array_merge($baseResult, [
                            'new_status' => 'FAILED_HELD',
                            'message' => 'Status remains FAILED_HELD as it did not get success'
                        ]);
                    } else {
                        // Update to FAILED_HELD (quarantine)
                        $msg = isset($res['msg']) ? $res['msg'] : 'Payout failed at provider';
                        $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :order_id");
                        $stmtUpdate->execute([':details' => $msg, ':order_id' => $orderId]);
                        
                        $updatedCount++;
                        $results[] = array_merge($baseResult, [
                            'new_status' => 'FAILED_HELD',
                            'message' => $msg
                        ]);
                    }
                } else {
                    // Pending / Processing / other intermediate states: keep as is
                    $results[] = array_merge($baseResult, [
                        'new_status' => $currentStatus,
                        'message' => 'API returned pending/processing state'
                    ]);
                }
            } else {
                // If API returned status false or error, keep failed_held as is, or quarantine pending/processing ones
                $msg = isset($res['msg']) ? $res['msg'] : 'Status check request returned error status';
                
                if ($currentStatus === 'FAILED_HELD') {
                    $results[] = array_merge($baseResult, [
                        'new_status' => 'FAILED_HELD',
                        'message' => $msg
                    ]);
                } else {
                    $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :order_id");
                    $stmtUpdate->execute([':details' => $msg, ':order_id' => $orderId]);
                    $updatedCount++;
                    $results[] = array_merge($baseResult, [
                        'new_status' => 'FAILED_HELD',
                        'message' => $msg
                    ]);
                }
            }
        } catch (Exception $e) {
            error_log("Cron V4 status check error for order $orderId: " . $e->getMessage());
            $results[] = array_merge($baseResult, [
                'error' => $e->getMessage()
            ]);
        }
    }
    
    update_last_sync_time();
    
    echo json_encode([
        'success' => true,
        'checked' => $checkedCount,
        'updated' => $updatedCount,
        'details' => $results,
        'last_sync_time' => time()
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Internal server error: ' . $e->getMessage()
    ]);
}
