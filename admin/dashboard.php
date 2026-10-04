<?php
/**
 * Deccan Finance - AdminLTE 3 Onboarding Console
 * Handles application approvals, rejection, and stats.
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

// Session authorization guard
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        header('Content-Type: application/json');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized administrator access.']);
        exit;
    }
    header('Location: login.php');
    exit;
}

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Administrator';
$initials = strtoupper(substr($username, 0, 2));

// Handle Action Requests (Approve/Reject/Edit Profile/Balance) via AJAX/POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    $action = $_POST['action'];
    $appId = isset($_POST['app_id']) ? $_POST['app_id'] : null;

    if ($action === 'APPROVE') {
        $success = update_application_status($appId, 'APPROVED');
        if ($success) {
            log_admin_activity($username, 'APPROVE_APPLICATION', "Approved application: $appId");
        }
        echo json_encode(['success' => $success, 'status' => 'APPROVED']);
    } elseif ($action === 'REJECT') {
        $success = update_application_status($appId, 'REJECTED');
        if ($success) {
            log_admin_activity($username, 'REJECT_APPLICATION', "Rejected application: $appId");
        }
        echo json_encode(['success' => $success, 'status' => 'REJECTED']);
    } elseif ($action === 'UPDATE_PROFILE') {
        $data = [
            'full_name' => trim($_POST['full_name']),
            'email' => trim($_POST['email']),
            'phone' => trim($_POST['phone']),
            'address' => trim($_POST['address']),
            'national_id' => trim($_POST['national_id']),
            'aadhaar_number' => trim($_POST['aadhaar_number']),
        ];
        if (isset($_POST['dob'])) $data['dob'] = trim($_POST['dob']);
        if (isset($_POST['gender'])) $data['gender'] = trim($_POST['gender']);
        if (isset($_POST['business_name'])) $data['business_name'] = trim($_POST['business_name']);
        if (isset($_POST['business_reg_no'])) $data['business_reg_no'] = trim($_POST['business_reg_no']);
        if (isset($_POST['expected_turnover'])) $data['expected_turnover'] = trim($_POST['expected_turnover']);

        $success = update_application_profile($appId, $data);
        if ($success) {
            log_admin_activity($username, 'UPDATE_PROFILE', "Updated profile details for application: $appId");
        }
        echo json_encode(['success' => $success]);
    } elseif ($action === 'ADJUST_BALANCE') {
        $amount = (float)$_POST['amount'];
        $type = $_POST['type']; // 'DEPOSIT' or 'WITHDRAW'
        
        // Fetch current application
        $apps = get_applications();
        $app = null;
        foreach ($apps as $a) {
            if ($a['app_id'] === $appId) {
                $app = $a;
                break;
            }
        }
        
        if (!$app) {
            echo json_encode(['success' => false, 'message' => 'Application not found.']);
            exit;
        }
        
        $currentBalance = (float)$app['balance'];
        if ($type === 'DEPOSIT') {
            $newBalance = $currentBalance + $amount;
        } elseif ($type === 'WITHDRAW') {
            if ($amount > $currentBalance) {
                echo json_encode(['success' => false, 'message' => 'Insufficient funds.']);
                exit;
            }
            $newBalance = $currentBalance - $amount;
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid transaction type.']);
            exit;
        }
        
        $success = update_application_balance($appId, $newBalance);
        if ($success) {
            $logDesc = ($type === 'DEPOSIT') ? "Deposited $amount INR (New balance: $newBalance INR) for application: $appId" : "Withdrew $amount INR (New balance: $newBalance INR) for application: $appId";
            log_admin_activity($username, 'ADJUST_BALANCE', $logDesc);

            // Trigger email notification
            try {
                require_once '../api/email_service.php';
                $custAccount = get_account_by_app_id($appId);
                if ($custAccount) {
                    $mailType = ($type === 'DEPOSIT') ? 'credit' : 'debit';
                    $remarks = ($type === 'DEPOSIT') ? 'Account Adjustment (Credit)' : 'Account Adjustment (Debit)';
                    EmailService::sendNotificationEmail($custAccount['account_number'], $mailType, $amount, null, $remarks);
                }
            } catch (Exception $mailEx) {
                error_log("Failed to send balance adjustment email: " . $mailEx->getMessage());
            }

            // Trigger push notification
            try {
                $notifTitle = ($type === 'DEPOSIT') ? "Account Credited" : "Account Debited";
                $notifBody = ($type === 'DEPOSIT') ? "Your account has been credited by " . number_format($amount, 2) . " INR. New Balance: " . number_format($newBalance, 2) . " INR." : "Your account has been debited by " . number_format($amount, 2) . " INR. New Balance: " . number_format($newBalance, 2) . " INR.";
                send_notification_to_user($appId, $notifTitle, $notifBody, [], null, 'Transactions');
            } catch (Exception $notifEx) {
                error_log("Failed to send push notification: " . $notifEx->getMessage());
            }
        }
        echo json_encode(['success' => $success, 'new_balance' => $newBalance]);
    } elseif ($action === 'VERIFY_RECIPIENT_TEST') {
        $accountNumber = isset($_POST['recipient_account_number']) ? trim($_POST['recipient_account_number']) : '';
        if (empty($accountNumber)) {
            echo json_encode(['success' => false, 'message' => 'Account number is required.']);
            exit;
        }
        $recipientAccount = get_account_by_number($accountNumber);
        if (!$recipientAccount) {
            echo json_encode(['success' => false, 'message' => 'Recipient account not found.']);
            exit;
        }
        $recipientUser = get_application_by_id($recipientAccount['app_id']);
        if (!$recipientUser) {
            echo json_encode(['success' => false, 'message' => 'Recipient profile details not found.']);
            exit;
        }
        echo json_encode([
            'success' => true,
            'full_name' => $recipientUser['full_name'],
            'account_number' => $recipientAccount['account_number']
        ]);
        exit;
    } elseif ($action === 'EXECUTE_P2P_TEST') {
        $senderAppId = isset($_POST['sender_app_id']) ? trim($_POST['sender_app_id']) : '';
        $recipientAcc = isset($_POST['recipient_account_number']) ? trim($_POST['recipient_account_number']) : '';
        $amount = isset($_POST['amount']) ? (float)$_POST['amount'] : 0.0;
        $mpin = isset($_POST['mpin']) ? trim($_POST['mpin']) : '';

        if (empty($senderAppId) || empty($recipientAcc) || empty($mpin)) {
            echo json_encode(['success' => false, 'message' => 'All fields (sender, recipient account, amount, mpin) are required.']);
            exit;
        }

        if ($amount <= 0) {
            echo json_encode(['success' => false, 'message' => 'Amount must be greater than 0.']);
            exit;
        }

        try {
            $senderAccount = get_account_by_app_id($senderAppId);
            $senderUser = get_application_by_id($senderAppId);
            
            if (!$senderAccount) {
                echo json_encode(['success' => false, 'message' => 'Sender account is not approved or doesn\'t exist.']);
                exit;
            }

            if (empty($senderAccount['mpin_hash'])) {
                echo json_encode(['success' => false, 'message' => 'Sender MPIN is not set.']);
                exit;
            }

            if (!password_verify($mpin, $senderAccount['mpin_hash'])) {
                echo json_encode(['success' => false, 'message' => 'Invalid MPIN.']);
                exit;
            }

            $senderBalance = (float)$senderUser['balance'];
            if ($senderBalance < $amount) {
                echo json_encode(['success' => false, 'message' => 'Insufficient sender account balance.']);
                exit;
            }

            $recipientAccount = get_account_by_number($recipientAcc);
            if (!$recipientAccount) {
                echo json_encode(['success' => false, 'message' => 'Recipient account number not found.']);
                exit;
            }

            $recipientAppId = $recipientAccount['app_id'];
            if ($recipientAppId === $senderAppId) {
                echo json_encode(['success' => false, 'message' => 'Cannot transfer funds to the same account.']);
                exit;
            }

            execute_p2p_transfer($senderAppId, $recipientAppId, $amount);
            $txnRecord = record_transaction($senderAppId, $recipientAcc, $amount, 'P2P');

            // Send "Payment Received" notification to recipient (User B)
            $notifyTitle = "Payment Received";
            $notifyBody = "You have received " . number_format($amount, 2) . " INR from " . $senderUser['full_name'] . ". UTR: " . $txnRecord['utr_id'];
            send_notification_to_user($recipientAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');

            // Send "Payment Sent" notification to sender (debit alert)
            $senderNotifyTitle = "Account Debited";
            $senderNotifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for transfer to " . $recipientAcc . ". UTR: " . $txnRecord['utr_id'];
            send_notification_to_user($senderAppId, $senderNotifyTitle, $senderNotifyBody, [], null, 'Transactions');

            $updatedSender = get_application_by_id($senderAppId);
            $newBalance = (float)$updatedSender['balance'];

            // Send transactional email notifications
            try {
                require_once '../api/email_service.php';
                EmailService::sendNotificationEmail($senderAccount['account_number'], 'debit', $amount, $txnRecord['utr_id'], 'P2P Transfer to ' . $recipientAcc);
                EmailService::sendNotificationEmail($recipientAcc, 'credit', $amount, $txnRecord['utr_id'], 'P2P Transfer from ' . $senderAccount['account_number']);
            } catch (Exception $mailEx) {
                error_log("Failed to send P2P test emails: " . $mailEx->getMessage());
            }

            log_admin_activity($username, 'EXECUTE_P2P_TEST', "Executed P2P test transfer of $amount INR from $senderAppId to account $recipientAcc");

            echo json_encode([
                'success' => true,
                'message' => 'P2P test transfer successful.',
                'transaction_id' => $txnRecord['transaction_id'],
                'utr_id' => $txnRecord['utr_id'],
                'new_balance' => $newBalance
            ]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Error processing transfer: ' . $e->getMessage()]);
        }
        exit;
    } elseif ($action === 'EXECUTE_PAYOUT_TEST') {
        $senderAppId = isset($_POST['sender_app_id']) ? trim($_POST['sender_app_id']) : '';
        $beneficiaryName = isset($_POST['beneficiary_name']) ? trim($_POST['beneficiary_name']) : '';
        $beneficiaryAcc = isset($_POST['beneficiary_account']) ? trim($_POST['beneficiary_account']) : '';
        $ifsc = isset($_POST['ifsc_code']) ? trim($_POST['ifsc_code']) : '';
        $amount = isset($_POST['amount']) ? (float)$_POST['amount'] : 0.0;
        $mpin = isset($_POST['mpin']) ? trim($_POST['mpin']) : '';

        if (empty($senderAppId) || empty($beneficiaryName) || empty($beneficiaryAcc) || empty($ifsc) || empty($mpin)) {
            echo json_encode(['success' => false, 'message' => 'All fields (sender, beneficiary name, account, IFSC, amount, mpin) are required.']);
            exit;
        }

        if ($amount <= 0) {
            echo json_encode(['success' => false, 'message' => 'Amount must be greater than 0.']);
            exit;
        }

        try {
            $senderAccount = get_account_by_app_id($senderAppId);
            $senderUser = get_application_by_id($senderAppId);
            
            if (!$senderAccount) {
                echo json_encode(['success' => false, 'message' => 'Sender account is not approved or doesn\'t exist.']);
                exit;
            }

            if (empty($senderAccount['mpin_hash'])) {
                echo json_encode(['success' => false, 'message' => 'Sender MPIN is not set.']);
                exit;
            }

            if (!password_verify($mpin, $senderAccount['mpin_hash'])) {
                echo json_encode(['success' => false, 'message' => 'Invalid MPIN.']);
                exit;
            }

            $senderBalance = (float)$senderUser['balance'];
            if ($senderBalance < $amount) {
                echo json_encode(['success' => false, 'message' => 'Insufficient sender account balance.']);
                exit;
            }

            // Execute balance deduction
            execute_payout_transfer($senderAppId, $amount);

            $activeProvider = get_active_payout_provider();
            // Record transaction as PENDING
            $txnRecord = record_transaction(
                $senderAppId,
                $beneficiaryAcc,
                $amount,
                'BANK_TRANSFER',
                null,
                'PENDING',
                $beneficiaryName,
                $ifsc,
                $activeProvider
            );
            $orderId = $txnRecord['transaction_id'];

            try {
                if ($activeProvider === 'jiopay') {
                    $providerRes = initiate_jiopay_payout($orderId, $beneficiaryAcc, $ifsc, $amount, $beneficiaryName);
                } else {
                    $providerRes = initiate_bharat4u_payout($orderId, $beneficiaryAcc, $ifsc, $amount, $beneficiaryName);
                }
                
                $updatedSender = get_application_by_id($senderAppId);
                $newBalance = (float)$updatedSender['balance'];

                // Send push notification to user (debit alert)
                try {
                    $notifyTitle = "Account Debited";
                    $notifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for payout transfer to " . $beneficiaryName . ". Ref: " . $orderId;
                    send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (Exception $notifEx) {
                    error_log("Failed to send test payout push notification: " . $notifEx->getMessage());
                }

                log_admin_activity($username, 'EXECUTE_PAYOUT_TEST', "Executed test payout of $amount INR for sender $senderAppId. Transaction: $orderId. Status: PENDING.");

                echo json_encode([
                    'success' => true,
                    'message' => 'Payout initiated successfully via test environment.',
                    'transaction_id' => $orderId,
                    'status' => 'PENDING',
                    'new_balance' => $newBalance,
                    'provider_response' => $providerRes
                ]);
            } catch (Exception $ex) {
                // Payout provider call failed immediately on initiation:
                // Update database transaction status to 'FAILED_HELD' (quarantined)
                // Do NOT refund the sender's balance (only admin can process refund/failed state)
                $pdo = get_db_connection();
                $stmt = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :tx_id");
                $stmt->execute([':details' => $ex->getMessage(), ':tx_id' => $orderId]);
                
                $updatedSender = get_application_by_id($senderAppId);
                $newBalance = (float)$updatedSender['balance'];

                // Send push notification to user (debit alert - quarantined)
                try {
                    $notifyTitle = "Account Debited";
                    $notifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR for payout transfer to " . $beneficiaryName . " (held). Ref: " . $orderId;
                    send_notification_to_user($senderAppId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (Exception $notifEx) {
                    error_log("Failed to send test payout push notification (quarantined): " . $notifEx->getMessage());
                }

                log_admin_activity($username, 'EXECUTE_PAYOUT_TEST_QUARANTINED', "Test payout quarantined for transaction $orderId: " . $ex->getMessage());

                echo json_encode([
                    'success' => true,
                    'message' => 'Payout initiated (quarantined in test environment).',
                    'transaction_id' => $orderId,
                    'status' => 'PENDING',
                    'new_balance' => $newBalance,
                    'provider_response' => [
                        'status' => false,
                        'message' => $ex->getMessage()
                    ]
                ]);
            }
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    } elseif ($action === 'CHECK_PAYOUT_STATUS_TEST') {
        $txnId = isset($_POST['transaction_id']) ? trim($_POST['transaction_id']) : '';
        if (empty($txnId)) {
            echo json_encode(['success' => false, 'message' => 'Transaction ID is required.']);
            exit;
        }

        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :txn_id LIMIT 1");
            $stmt->execute([':txn_id' => $txnId]);
            $txn = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$txn) {
                echo json_encode(['success' => false, 'message' => 'Transaction record not found in database.']);
                exit;
            }

            $providerRes = null;
            $txProvider = !empty($txn['provider']) ? strtolower(trim($txn['provider'])) : 'bharat4u';
            try {
                if ($txProvider === 'jiopay') {
                    $providerRes = check_jiopay_payout_status($txnId);
                } else {
                    $providerRes = check_bharat4u_payout_status($txnId);
                }
                
                // Sync status to database if txn is PENDING
                if ($txn['status'] === 'PENDING') {
                    if (isset($providerRes['status']) && $providerRes['status'] === true) {
                        $data = isset($providerRes['data']) ? $providerRes['data'] : [];
                        $txnStatus = isset($data['status']) ? strtoupper($data['status']) : (isset($data['txn_status']) ? strtoupper($data['txn_status']) : '');
                        $utr = isset($data['utr']) ? $data['utr'] : null;
                        
                        if ($txnStatus === 'SUCCESS') {
                            $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'SUCCESS', utr_id = :utr, status_details = 'Payout completed via status check test' WHERE transaction_id = :order_id");
                            $stmtUpdate->execute([':utr' => $utr, ':order_id' => $txnId]);
                        } elseif ($txnStatus === 'FAILED' || $txnStatus === 'REJECTED') {
                            $msg = isset($providerRes['msg']) ? $providerRes['msg'] : 'Payout failed at provider';
                            $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :order_id");
                            $stmtUpdate->execute([':details' => $msg, ':order_id' => $txnId]);
                        }
                    } else {
                        $msg = isset($providerRes['msg']) ? $providerRes['msg'] : 'Status check returned failure';
                        $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :order_id");
                        $stmtUpdate->execute([':details' => $msg, ':order_id' => $txnId]);
                    }
                }

                // Fetch updated transaction details
                $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :txn_id LIMIT 1");
                $stmt->execute([':txn_id' => $txnId]);
                $updatedTxn = $stmt->fetch(PDO::FETCH_ASSOC);

                echo json_encode([
                    'success' => true,
                    'message' => 'Status checked successfully.',
                    'transaction' => $updatedTxn,
                    'provider_response' => $providerRes
                ]);
            } catch (Exception $ex) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Provider status check error: ' . $ex->getMessage(),
                    'provider_response' => [
                        'status' => false,
                        'message' => $ex->getMessage()
                    ]
                ]);
            }
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    } elseif ($action === 'APPROVE_BENEFICIARY') {
        $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
        if ($id <= 0) {
            echo json_encode(['success' => false, 'message' => 'Beneficiary ID is required.']);
            exit;
        }
        
        // Fetch beneficiary details to send notification
        $pdo = get_db_connection();
        $stmt = $pdo->prepare("SELECT * FROM beneficiaries WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $ben = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $success = update_beneficiary_status($id, 'APPROVED');
        if ($success) {
            log_admin_activity($username, 'APPROVE_BENEFICIARY', "Approved beneficiary mapping ID: $id");
            if ($ben) {
                $notifyTitle = "Beneficiary Added Successfully";
                $notifyBody = "Beneficiary " . $ben['beneficiary_name'] . " (Acc: " . $ben['beneficiary_account_number'] . ") has been added successfully to your account.";
                send_notification_to_user($ben['sender_app_id'], $notifyTitle, $notifyBody, [], null, 'Updates');
            }
        }
        echo json_encode(['success' => $success]);
        exit;
    } elseif ($action === 'REJECT_BENEFICIARY') {
        $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
        if ($id <= 0) {
            echo json_encode(['success' => false, 'message' => 'Beneficiary ID is required.']);
            exit;
        }
        $success = update_beneficiary_status($id, 'REJECTED');
        if ($success) {
            log_admin_activity($username, 'REJECT_BENEFICIARY', "Rejected beneficiary mapping ID: $id");
        }
        echo json_encode(['success' => $success]);
        exit;
    } elseif ($action === 'SEND_NOTIFICATION') {
        $fcmToken = '';
        if (isset($_POST['fcm_token'])) {
            $fcmToken = trim($_POST['fcm_token']);
        } elseif (isset($_POST['fmc_token'])) {
            $fcmToken = trim($_POST['fmc_token']);
        }
        $title = isset($_POST['title']) ? trim($_POST['title']) : '';
        $body = isset($_POST['body']) ? trim($_POST['body']) : '';
        $category = isset($_POST['category']) ? trim($_POST['category']) : 'Updates';
        
        if (empty($title) || empty($body)) {
            echo json_encode(['success' => false, 'message' => 'Notification Title and Body/Message are required.']);
            exit;
        }
        
        $res = send_fcm_notification($fcmToken, $title, $body, ['app_id' => $appId], null, $category);
        if ($res['success']) {
            log_admin_activity($username, 'SEND_NOTIFICATION', "Sent push notification to application: $appId (Title: $title)");
        }
        echo json_encode($res);
        exit;
    } elseif ($action === 'SEND_BULK_NOTIFICATION') {
        $target = isset($_POST['target']) ? trim($_POST['target']) : 'SINGLE'; // 'SINGLE' or 'ALL'
        $targetAppId = isset($_POST['target_app_id']) ? trim($_POST['target_app_id']) : '';
        $title = isset($_POST['title']) ? trim($_POST['title']) : '';
        $body = isset($_POST['body']) ? trim($_POST['body']) : '';
        $category = isset($_POST['category']) ? trim($_POST['category']) : 'Updates';
        
        if (empty($title) || empty($body)) {
            echo json_encode(['success' => false, 'message' => 'Notification Title and Message/Body are required.']);
            exit;
        }
        
        // Handle optional photo attachment upload
        $imageUrl = null;
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
            $fileTmpPath = $_FILES['photo']['tmp_name'];
            $fileName = $_FILES['photo']['name'];
            $fileSize = $_FILES['photo']['size'];
            $fileType = $_FILES['photo']['type'];
            
            $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
            $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
            
            if (!in_array($fileExtension, $allowedExtensions)) {
                echo json_encode(['success' => false, 'message' => 'Invalid file format. Only JPG, JPEG, PNG, and GIF images are allowed.']);
                exit;
            }
            
            // Enforce 5MB limit
            if ($fileSize > 5 * 1024 * 1024) {
                echo json_encode(['success' => false, 'message' => 'Image size exceeds maximum limit of 5MB.']);
                exit;
            }
            
            $uploadDir = '../uploads/notifications/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }
            
            $newFileName = 'notify_' . time() . '_' . mt_rand(1000, 9999) . '.' . $fileExtension;
            $destPath = $uploadDir . $newFileName;
            
            if (move_uploaded_file($fileTmpPath, $destPath)) {
                // Generate public image URL
                $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
                $imageUrl = $protocol . '://' . $_SERVER['HTTP_HOST'] . '/uploads/notifications/' . $newFileName;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to save uploaded image.']);
                exit;
            }
        }
        
        $tokens = [];
        if ($target === 'ALL') {
            $tokens = get_all_fcm_tokens();
        } else {
            // Find application token for targetAppId
            if (empty($targetAppId)) {
                echo json_encode(['success' => false, 'message' => 'Please select a recipient user.']);
                exit;
            }
            $targetApp = get_application_by_id($targetAppId);
            if (!$targetApp) {
                echo json_encode(['success' => false, 'message' => 'Recipient user not found.']);
                exit;
            }
            
            // Get fcm_token from accounts or applications
            $acc = get_account_by_app_id($targetAppId);
            $tokenVal = null;
            if ($acc && !empty($acc['fcm_token'])) {
                $tokenVal = $acc['fcm_token'];
            } elseif (!empty($targetApp['fcm_token'])) {
                $tokenVal = $targetApp['fcm_token'];
            }

            
            $tokens[] = [
                'app_id' => $targetAppId,
                'fcm_token' => $tokenVal,
                'full_name' => $targetApp['full_name']
            ];
        }
        
        if (empty($tokens)) {
            echo json_encode(['success' => false, 'message' => 'No active recipient devices found with registered FCM tokens.']);
            exit;
        }
        
        $sentCount = 0;
        $lastError = 'FCM dispatch failed.';
        foreach ($tokens as $t) {
            $res = send_fcm_notification($t['fcm_token'], $title, $body, ['app_id' => $t['app_id']], $imageUrl, $category);
            if ($res['success']) {
                $sentCount++;
            } else {
                if (!empty($res['message'])) {
                    $lastError = $res['message'];
                }
            }
        }
        
        if ($sentCount === 0) {
            echo json_encode([
                'success' => false,
                'message' => $lastError
            ]);
            exit;
        }
        
        log_admin_activity($username, 'SEND_BULK_NOTIFICATION', "Sent push notification (Target: $target, Image: " . ($imageUrl ? 'Yes' : 'No') . ") to $sentCount users.");
        echo json_encode([
            'success' => true, 
            'message' => "Successfully sent push notification to $sentCount users.", 
            'sent_count' => $sentCount,
            'image_url' => $imageUrl
        ]);
        exit;
    } elseif ($action === 'RETRY_PAYOUT') {
        $txnId = isset($_POST['transaction_id']) ? trim($_POST['transaction_id']) : '';
        if (empty($txnId)) {
            echo json_encode(['success' => false, 'message' => 'Transaction ID is required.']);
            exit;
        }
        
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :txn_id LIMIT 1");
            $stmt->execute([':txn_id' => $txnId]);
            $txn = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$txn) {
                echo json_encode(['success' => false, 'message' => 'Transaction not found.']);
                exit;
            }
            
            if ($txn['status'] !== 'FAILED_HELD') {
                echo json_encode(['success' => false, 'message' => 'Only failed/held payouts can be retried.']);
                exit;
            }
            
            // Set status to PENDING before retrying
            $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'PENDING', status_details = 'Retrying payout...' WHERE transaction_id = :txn_id");
            $stmtUpdate->execute([':txn_id' => $txnId]);
            
            try {
                $txProvider = !empty($txn['provider']) ? strtolower(trim($txn['provider'])) : 'bharat4u';
                if ($txProvider === 'jiopay') {
                    initiate_jiopay_payout($txnId, $txn['recipient_account'], $txn['ifsc_code'], $txn['amount'], $txn['recipient_name']);
                } else {
                    initiate_bharat4u_payout($txnId, $txn['recipient_account'], $txn['ifsc_code'], $txn['amount'], $txn['recipient_name']);
                }
                log_admin_activity($username, 'RETRY_PAYOUT', "Retried payout for transaction: $txnId. Status is PENDING.");
                echo json_encode(['success' => true, 'message' => 'Payout retry initiated successfully. Status is now PENDING.']);
            } catch (Exception $ex) {
                // Revert to FAILED_HELD with new failure details
                $stmtRevert = $pdo->prepare("UPDATE transactions SET status = 'FAILED_HELD', status_details = :details WHERE transaction_id = :txn_id");
                $stmtRevert->execute([':details' => 'Retry failed: ' . $ex->getMessage(), ':txn_id' => $txnId]);
                log_admin_activity($username, 'RETRY_PAYOUT_FAILED', "Retry failed for transaction: $txnId. Error: " . $ex->getMessage());
                echo json_encode(['success' => false, 'message' => 'Retry failed: ' . $ex->getMessage()]);
            }
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    } elseif ($action === 'REFUND_PAYOUT') {
        $txnId = isset($_POST['transaction_id']) ? trim($_POST['transaction_id']) : '';
        if (empty($txnId)) {
            echo json_encode(['success' => false, 'message' => 'Transaction ID is required.']);
            exit;
        }
        
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :txn_id LIMIT 1");
            $stmt->execute([':txn_id' => $txnId]);
            $txn = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$txn) {
                echo json_encode(['success' => false, 'message' => 'Transaction not found.']);
                exit;
            }
            
            if ($txn['status'] !== 'FAILED_HELD') {
                echo json_encode(['success' => false, 'message' => 'Only failed/held payouts can be refunded.']);
                exit;
            }
            
            $pdo->beginTransaction();
            
            // Mark status as FAILED
            $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = 'FAILED', status_details = 'Marked as failed and refunded' WHERE transaction_id = :txn_id");
            $stmtUpdate->execute([':txn_id' => $txnId]);
            
            // Add back to sender's balance
            $stmtRefund = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :sender_app_id");
            $stmtRefund->execute([
                ':amount' => $txn['amount'],
                ':sender_app_id' => $txn['sender_app_id']
            ]);
            
            $pdo->commit();
            
            // Send push notification to the user about the refund without using the word admin or administrator
            $notifyTitle = "Payment Refunded";
            $notifyBody = "Your payout transaction of " . number_format($txn['amount'], 2) . " INR has failed, and the amount has been refunded to your account balance.";
            send_notification_to_user($txn['sender_app_id'], $notifyTitle, $notifyBody, [], null, 'Transactions');
            
            log_admin_activity($username, 'REFUND_PAYOUT', "Marked payout transaction $txnId as FAILED and refunded {$txn['amount']} INR to sender {$txn['sender_app_id']}");
            echo json_encode(['success' => true, 'message' => 'Transaction marked as FAILED and balance refunded successfully.']);
        } catch (Exception $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            echo json_encode(['success' => false, 'message' => 'Error refunding payout: ' . $e->getMessage()]);
        }
        exit;
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid Action']);
    }
    exit;
}

// Determine current page
$page = isset($_GET['page']) ? $_GET['page'] : 'dashboard';

if ($page === 'notifications') {
    header('Location: notifications.php');
    exit;
}

// Fetch all applications
$applications = get_applications();

// Fetch sender choices for testing if page is p2p_test or payout_test
$senderOptions = [];
$recentPayouts = [];
if ($page === 'p2p_test' || $page === 'payout_test') {
    $approvedApps = get_applications('APPROVED');
    foreach ($approvedApps as $app) {
        $acc = get_account_by_app_id($app['app_id']);
        if ($acc) {
            $senderOptions[] = [
                'app_id' => $app['app_id'],
                'full_name' => $app['full_name'],
                'account_number' => $acc['account_number'],
                'balance' => $app['balance'],
                'has_mpin' => !empty($acc['mpin_hash'])
            ];
        }
    }
    
    if ($page === 'payout_test') {
        $pdo = get_db_connection();
        $stmtRecent = $pdo->query("SELECT transaction_id, recipient_name, amount, created_at, status FROM transactions WHERE type='BANK_TRANSFER' ORDER BY created_at DESC LIMIT 15");
        $recentPayouts = $stmtRecent->fetchAll(PDO::FETCH_ASSOC);
    }
}

$pendingBeneficiaries = [];
if ($page === 'beneficiary_approvals') {
    $pendingBeneficiaries = get_pending_beneficiaries();
}

// Calculate stats (based on all applications)
$total = count($applications);
$pending = 0;
$approved = 0;
$rejected = 0;

foreach ($applications as $app) {
    if ($app['status'] === 'PENDING') $pending++;
    elseif ($app['status'] === 'APPROVED') $approved++;
    elseif ($app['status'] === 'REJECTED') $rejected++;
}

// Determine filter from query string
$filter = isset($_GET['filter']) ? strtoupper($_GET['filter']) : 'ALL';
if ($filter === 'SAVINGS') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'SAVINGS';
    });
} elseif ($filter === 'CURRENT') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'CURRENT';
    });
} elseif ($filter === 'NRI') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'NRI';
    });
} elseif ($filter === 'CORPORATE') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'CORPORATE';
    });
} else {
    $filteredApps = $applications;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Admin Console</title>

    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- Ionicons -->
    <link rel="stylesheet" href="https://code.ionicframework.com/ionicons/2.0.1/css/ionicons.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">
    <link rel="icon" type="image/png" href="favicon.png">

    <style>
        /* Table styles */
        .table-middle td, .table-middle th {
            vertical-align: middle !important;
        }

        /* Biometrics Viewers */
        .detail-img-frame {
            border: 2px solid #ccd6dd;
            border-radius: 4px;
            padding: 4px;
            background-color: #f8fafc;
            max-width: 100%;
        }
    </style>
</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

    <!-- Top Navbar -->
    <nav class="main-header navbar navbar-expand navbar-white navbar-light">
        <!-- Left navbar links -->
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
            </li>
            <li class="nav-item d-none d-sm-inline-block">
                <a href="../index.html" class="nav-link">Main Website</a>
            </li>
        </ul>

        <!-- Right navbar links -->
        <ul class="navbar-nav ml-auto">
            <li class="nav-item d-none d-sm-inline-block">
                <a href="logout.php" class="nav-link text-warning font-weight-bold"><i class="fas fa-sign-out-alt mr-1"></i> Logout</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" data-widget="fullscreen" href="#" role="button">
                    <i class="fas fa-expand-arrows-alt"></i>
                </a>
            </li>
        </ul>
    </nav>
    <!-- /.navbar -->

    <!-- Main Sidebar Container -->
    <aside class="main-sidebar sidebar-light-primary elevation-4">
        <!-- Brand Logo -->
        <a href="#" class="brand-link">
            <img src="../assets/7PzcYdFs3fE3HNk64pDrpdmsSOk.svg" alt="Neon Logo" onerror="this.src='../logo.png';" style="height: 32px; width: auto;">
            <span class="brand-text" style="font-weight: 800; color: #ffffff;"><span style="color: #00f2fe;">neon</span> finance</span>
        </a>

        <!-- Sidebar -->
        <div class="sidebar">
            <!-- Sidebar user panel -->
            <div class="user-panel mt-3 pb-3 mb-3 d-flex">
                <div class="image">
                    <span class="img-circle elevation-2 text-white bg-warning d-flex align-items-center justify-content-center" style="width: 32px; height: 32px; font-weight: 700;"><?= $initials ?></span>
                </div>
                <div class="info">
                    <a href="#" class="d-block"><?= htmlspecialchars($username) ?></a>
                </div>
            </div>

            <!-- Sidebar Menu -->
            <nav class="mt-2">
                <ul class="nav nav-pills nav-sidebar flex-column" role="menu">
                    <li class="nav-header">MANAGEMENT</li>
                    <li class="nav-item">
                        <a href="dashboard.php" class="nav-link <?= ($page === 'dashboard' && !isset($_GET['filter'])) ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-tachometer-alt"></i>
                            <p>Dashboard</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="user_profiles.php" class="nav-link">
                            <i class="nav-icon fas fa-users-cog"></i>
                            <p>User Profiles</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="transactions.php" class="nav-link <?= ($page === 'transactions') ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-exchange-alt"></i>
                            <p>All Transactions</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="settings.php" class="nav-link">
                            <i class="nav-icon fas fa-shield-alt"></i>
                            <p>Security Settings</p>
                        </a>
                    </li>
                    <li class="nav-header">APPLICATIONS</li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=all" class="nav-link <?= (isset($_GET['filter']) && $filter === 'ALL') || ($page === 'dashboard' && isset($_GET['filter']) && $filter === 'ALL') ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-list-ul"></i>
                            <p>All Applications</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=savings" class="nav-link <?= (isset($_GET['filter']) && $filter === 'SAVINGS') ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-user-shield"></i>
                            <p>Savings Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=current" class="nav-link <?= (isset($_GET['filter']) && $filter === 'CURRENT') ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-briefcase"></i>
                            <p>Current Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=nri" class="nav-link <?= (isset($_GET['filter']) && $filter === 'NRI') ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-globe"></i>
                            <p>NRI Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=corporate" class="nav-link <?= (isset($_GET['filter']) && $filter === 'CORPORATE') ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-building"></i>
                            <p>Corporate Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=beneficiary_approvals" class="nav-link <?= $page === 'beneficiary_approvals' ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-user-check"></i>
                            <p>Beneficiary Approvals</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=failed_payouts" class="nav-link <?= $page === 'failed_payouts' ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-exclamation-triangle"></i>
                            <p>Failed Payouts Queue</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="notifications.php" class="nav-link">
                            <i class="nav-icon fas fa-bell"></i>
                            <p>Send Notifications</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=statements" class="nav-link <?= $page === 'statements' ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-file-invoice"></i>
                            <p>Generated Statements</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="compliance.php" class="nav-link">
                            <i class="nav-icon fas fa-file-contract"></i>
                            <p>Compliance Manager</p>
                        </a>
                    </li>
                    <li class="nav-header">EMAIL SYSTEM</li>
                    <li class="nav-item">
                        <a href="email_settings.php" class="nav-link">
                            <i class="nav-icon fas fa-envelope-open-text"></i>
                            <p>Email Settings</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="send_email.php" class="nav-link">
                            <i class="nav-icon fas fa-paper-plane"></i>
                            <p>Send Email</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="email_logs.php" class="nav-link">
                            <i class="nav-icon fas fa-history"></i>
                            <p>Email Logs</p>
                        </a>
                    </li>
                    <li class="nav-header">TESTING</li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=p2p_test" class="nav-link <?= $page === 'p2p_test' ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-exchange-alt"></i>
                            <p>P2P Transfer Test</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=payout_test" class="nav-link <?= $page === 'payout_test' ? 'active' : '' ?>">
                            <i class="nav-icon fas fa-wallet"></i>
                            <p>Payout Transfer Test</p>
                        </a>
                    </li>
                    <li class="nav-header">SESSION</li>
                    <li class="nav-item">
                        <a href="logout.php" class="nav-link">
                            <i class="nav-icon fas fa-sign-out-alt text-warning"></i>
                            <p>Logout</p>
                        </a>
                    </li>
                </ul>
            </nav>
        </div>
        <!-- /.sidebar -->
    </aside>

    <?php
    $pageTitle = 'Onboarding Management';
    $breadcrumb = 'Applications';
    if ($page === 'p2p_test') {
        $pageTitle = 'P2P Money Transfer Testing Suite';
        $breadcrumb = 'P2P Transfer Test';
    } elseif ($page === 'payout_test') {
        $pageTitle = 'P2B Payout Testing & Status Suite';
        $breadcrumb = 'Payout Test';
    } elseif ($page === 'beneficiary_approvals') {
        $pageTitle = 'Beneficiary Approvals';
        $breadcrumb = 'Beneficiary Approvals';
    } elseif ($page === 'failed_payouts') {
        $pageTitle = 'Failed Payouts Quarantine Queue';
        $breadcrumb = 'Failed Payouts';
    } elseif ($page === 'notifications') {
        $pageTitle = 'Push Notification Dispatcher';
        $breadcrumb = 'Send Notifications';
    } elseif ($page === 'statements') {
        $pageTitle = 'Generated Bank Statements Log';
        $breadcrumb = 'Statements Log';
    }
    ?>

    <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <div class="content-header">
            <div class="container-fluid">
                <div class="row mb-2">
                    <div class="col-sm-6">
                        <h1 class="m-0 text-navy font-weight-bold"><?= htmlspecialchars($pageTitle) ?></h1>
                    </div>
                    <div class="col-sm-6">
                        <ol class="breadcrumb float-sm-right">
                            <li class="breadcrumb-item"><a href="#">Admin</a></li>
                            <li class="breadcrumb-item active"><?= htmlspecialchars($breadcrumb) ?></li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>
        <!-- /.content-header -->

        <!-- Main content -->
        <div class="content">
            <div class="container-fluid">
                
                <?php if ($page === 'failed_payouts'): 
                    $failedPayouts = get_failed_payouts();
                    $lastSync = get_last_sync_time();
                    $elapsed = time() - $lastSync;
                    $remaining = 120 - $elapsed;
                    if ($remaining <= 0 || $lastSync === 0) {
                        $remaining = 120;
                    }
                    $min = floor($remaining / 60);
                    $sec = $remaining % 60;
                    $timeStr = sprintf("%02d:%02d", $min, $sec);
                ?>
                    <!-- Payout Auto-Sync Status Checker Card -->
                    <div class="row mb-4">
                        <div class="col-12">
                            <div class="card card-default shadow-sm border-left-info" style="border-left: 4px solid #17a2b8;">
                                <div class="card-header bg-light d-flex align-items-center py-2">
                                    <h3 class="card-title font-weight-bold text-navy mb-0" style="font-size: 1.1rem;">
                                        <i class="fas fa-sync-alt mr-2 text-info"></i> Payout Auto-Sync Status Checker
                                    </h3>
                                    <button id="btn-manual-sync" class="btn btn-sm btn-success font-weight-bold ml-auto">
                                        <i class="fas fa-sync-alt mr-1"></i> Sync Now
                                    </button>
                                </div>
                                <div class="card-body py-3">
                                    <div class="d-flex align-items-center flex-wrap">
                                        <span class="font-weight-bold text-muted mr-3">Auto-Sync status check runs every 2 minutes.</span>
                                        <div class="d-flex align-items-center">
                                            <span class="mr-2 text-navy font-weight-bold">Next Auto-Sync in:</span>
                                            <span id="sync-timer" class="badge badge-warning font-weight-bold px-3 py-2" style="font-size: 100%; border-radius: 4px;"><?= $timeStr ?></span>
                                        </div>
                                    </div>
                                    
                                    <!-- Checked Transactions Log -->
                                    <div id="sync-log-container" class="mt-3" style="display:none;">
                                        <h5 class="font-weight-bold small text-navy mb-2"><i class="fas fa-history mr-1"></i> Last Checked Transactions</h5>
                                        <div class="table-responsive">
                                            <table class="table table-sm table-striped table-bordered mb-0 small" style="font-size: 90%;">
                                                <thead class="bg-navy text-white" style="background-color: #031f73;">
                                                    <tr>
                                                        <th>Transaction ID</th>
                                                        <th>User (ID)</th>
                                                        <th>Amount</th>
                                                        <th>Old Status</th>
                                                        <th>Current Status</th>
                                                        <th>Remarks / Result</th>
                                                    </tr>
                                                </thead>
                                                <tbody id="sync-log-body">
                                                    <!-- Dynamically populated -->
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                    
                                    <div id="sync-empty-log" class="mt-3 small text-muted">
                                        <i class="fas fa-info-circle mr-1"></i> No status check has run in this admin session yet.
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Failed Payouts Queue Card -->
                    <div class="row">
                        <div class="col-12">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-exclamation-triangle mr-2"></i> Failed Payouts Quarantine Queue
                                    </h3>
                                </div>
                                <div class="card-body p-0">
                                    <?php if (empty($failedPayouts)): ?>
                                        <div class="text-center py-5 text-muted">
                                            <i class="fas fa-check-circle fa-3x mb-3 text-success"></i>
                                            <p class="mb-0 font-weight-bold">No failed payouts in quarantine.</p>
                                        </div>
                                    <?php else: ?>
                                        <div class="table-responsive">
                                            <table class="table table-hover table-bordered table-striped table-middle mb-0">
                                                <thead>
                                                    <tr>
                                                        <th>Transaction ID</th>
                                                        <th>Sender (App ID)</th>
                                                        <th>Beneficiary Name</th>
                                                        <th>Account Number</th>
                                                        <th>IFSC Code</th>
                                                        <th>Amount</th>
                                                        <th>Failure Reason</th>
                                                        <th>Date</th>
                                                        <th>Actions</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <?php foreach ($failedPayouts as $payout): ?>
                                                        <tr id="payout-row-<?= htmlspecialchars($payout['transaction_id']) ?>">
                                                            <td><strong><?= htmlspecialchars($payout['transaction_id']) ?></strong></td>
                                                            <td><?= htmlspecialchars($payout['sender_name']) ?> (<?= htmlspecialchars($payout['sender_app_id']) ?>)</td>
                                                            <td><?= htmlspecialchars($payout['recipient_name']) ?></td>
                                                            <td><code><?= htmlspecialchars($payout['recipient_account']) ?></code></td>
                                                            <td><code><?= htmlspecialchars($payout['ifsc_code']) ?></code></td>
                                                            <td><strong><?= number_format($payout['amount'], 2) ?> INR</strong></td>
                                                            <td><span class="text-danger font-weight-bold small"><?= htmlspecialchars($payout['status_details'] ?: 'Unknown Error') ?></span></td>
                                                            <td><?= date('M d, Y H:i', strtotime($payout['created_at'])) ?></td>
                                                            <td>
                                                                <button class="btn btn-xs btn-success font-weight-bold px-2 py-1 mr-1" onclick="retryPayout('<?= htmlspecialchars($payout['transaction_id']) ?>')">
                                                                    <i class="fas fa-redo mr-1"></i> Try Again
                                                                </button>
                                                                <button class="btn btn-xs btn-danger font-weight-bold px-2 py-1" onclick="refundPayout('<?= htmlspecialchars($payout['transaction_id']) ?>')">
                                                                    <i class="fas fa-undo-alt mr-1"></i> Mark Failed & Refund
                                                                </button>
                                                            </td>
                                                        </tr>
                                                    <?php endforeach; ?>
                                                </tbody>
                                            </table>
                                        </div>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php elseif ($page === 'beneficiary_approvals'): ?>
                    <!-- Beneficiary Approvals Card -->
                    <div class="row">
                        <div class="col-12">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-user-check mr-2"></i> Pending Other Bank Beneficiaries
                                    </h3>
                                </div>
                                <div class="card-body p-0">
                                    <?php if (empty($pendingBeneficiaries)): ?>
                                        <div class="text-center py-5 text-muted">
                                            <i class="fas fa-check-double fa-3x mb-3 text-success"></i>
                                            <p class="mb-0 font-weight-bold">No pending beneficiaries require approval.</p>
                                        </div>
                                    <?php else: ?>
                                        <table class="table table-hover table-bordered table-striped table-middle mb-0">
                                            <thead>
                                                <tr>
                                                    <th>ID</th>
                                                    <th>Sender (App ID)</th>
                                                    <th>Beneficiary Holder Name</th>
                                                    <th>Account Number</th>
                                                    <th>IFSC Code</th>
                                                    <th>Daily Limit</th>
                                                    <th>Nickname</th>
                                                    <th>Submission Date</th>
                                                    <th>Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <?php foreach ($pendingBeneficiaries as $ben): ?>
                                                    <tr id="ben-row-<?= $ben['id'] ?>">
                                                        <td><strong><?= htmlspecialchars($ben['id']) ?></strong></td>
                                                        <td><?= htmlspecialchars($ben['sender_name']) ?> (<?= htmlspecialchars($ben['sender_app_id']) ?>)</td>
                                                        <td><?= htmlspecialchars($ben['beneficiary_name']) ?></td>
                                                        <td><code><?= htmlspecialchars($ben['beneficiary_account_number']) ?></code></td>
                                                        <td><code><?= htmlspecialchars($ben['ifsc_code']) ?></code></td>
                                                        <td><?= number_format($ben['daily_limit'], 2) ?> INR</td>
                                                        <td><span class="badge badge-secondary"><?= htmlspecialchars($ben['nickname']) ?></span></td>
                                                        <td><?= date('M d, Y H:i', strtotime($ben['created_at'])) ?></td>
                                                        <td>
                                                            <button class="btn btn-xs btn-success font-weight-bold px-2 py-1 mr-1" onclick="approveBeneficiary(<?= $ben['id'] ?>)">
                                                                <i class="fas fa-check-circle mr-1"></i> Approve
                                                            </button>
                                                            <button class="btn btn-xs btn-danger font-weight-bold px-2 py-1" onclick="rejectBeneficiary(<?= $ben['id'] ?>)">
                                                                <i class="fas fa-times-circle mr-1"></i> Reject
                                                            </button>
                                                        </td>
                                                    </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                        </table>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php elseif ($page === 'p2p_test'): ?>
                    <!-- P2P Transfer Testing Suite Form Card -->
                    <div class="row">
                        <div class="col-md-8 offset-md-2">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-exchange-alt mr-2"></i> Execute P2P Transfer (Test)
                                    </h3>
                                </div>
                                <div class="card-body p-4">
                                    <form id="p2p-testing-form">
                                        <!-- Sender selection -->
                                        <div class="form-group">
                                            <label for="sender_app_id" class="font-weight-bold text-navy">Sender Account</label>
                                            <select class="form-control" id="sender_app_id" name="sender_app_id" required>
                                                <option value="">-- Select Sender Account --</option>
                                                <?php foreach ($senderOptions as $sender): ?>
                                                    <option value="<?= htmlspecialchars($sender['app_id']) ?>" 
                                                            data-balance="<?= htmlspecialchars($sender['balance']) ?>"
                                                            data-number="<?= htmlspecialchars($sender['account_number']) ?>">
                                                        <?= htmlspecialchars($sender['full_name']) ?> (Acc: <?= htmlspecialchars($sender['account_number']) ?>) - Balance: <?= number_format($sender['balance'], 2) ?> INR <?= $sender['has_mpin'] ? '[MPIN Set]' : '[NO MPIN SET]' ?>
                                                    </option>
                                                <?php endforeach; ?>
                                            </select>
                                            <small class="form-text text-muted" id="sender-balance-help">Please select an approved sender account. The account must have an MPIN set to complete transfers.</small>
                                        </div>

                                        <!-- Recipient account number -->
                                        <div class="form-group">
                                            <label for="recipient_account_number" class="font-weight-bold text-navy">Recipient Account Number</label>
                                            <div class="input-group">
                                                <input type="text" class="form-control" id="recipient_account_number" name="recipient_account_number" placeholder="Enter 11-digit Recipient Account Number" required pattern="\d{11}">
                                                <div class="input-group-append">
                                                    <button class="btn btn-outline-primary" type="button" id="btn-verify-recipient-test">
                                                        <i class="fas fa-search mr-1"></i> Verify Recipient
                                                    </button>
                                                </div>
                                            </div>
                                            <div class="mt-2" id="recipient-verification-result" style="display:none;"></div>
                                        </div>

                                        <!-- Transfer amount -->
                                        <div class="form-group">
                                            <label for="amount" class="font-weight-bold text-navy">Transfer Amount (INR)</label>
                                            <input type="number" step="0.01" min="0.01" class="form-control" id="amount" name="amount" placeholder="0.00" required>
                                        </div>

                                        <!-- Sender's 6-digit MPIN -->
                                        <div class="form-group">
                                            <label for="mpin" class="font-weight-bold text-navy">Sender's 6-Digit MPIN</label>
                                            <input type="password" class="form-control" id="mpin" name="mpin" placeholder="******" maxlength="6" pattern="\d{6}" required>
                                            <small class="form-text text-muted">Verification requires the sender's 6-digit MPIN code.</small>
                                        </div>

                                        <button type="submit" class="btn btn-block btn-warning font-weight-bold text-navy py-2" style="background-color: #fecb00; border-color: #fecb00;" id="btn-submit-transfer">
                                            <i class="fas fa-paper-plane mr-2"></i> Send Money
                                        </button>
                                    </form>

                                    <!-- Transaction receipt alert -->
                                    <div class="mt-4" id="p2p-test-receipt" style="display:none;">
                                        <div class="card card-outline card-success shadow-sm">
                                            <div class="card-header bg-light">
                                                <h5 class="m-0 font-weight-bold text-success"><i class="fas fa-check-circle mr-1"></i> Transfer Receipt (Successful)</h5>
                                            </div>
                                            <div class="card-body p-3">
                                                <table class="table table-striped table-sm mb-0">
                                                    <tbody>
                                                        <tr>
                                                            <td class="font-weight-bold" width="40%">Status</td>
                                                            <td><span class="badge badge-success px-2 py-1">COMPLETED</span></td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Transaction ID</td>
                                                            <td id="receipt-txn-id">TXN-XXXXXX</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">UTR (12-Digit Numeric)</td>
                                                            <td id="receipt-utr-id">000000000000</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Amount Transferred</td>
                                                            <td id="receipt-amount">0.00 INR</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">New Sender Balance</td>
                                                            <td id="receipt-sender-balance">0.00 INR</td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php elseif ($page === 'payout_test'): ?>
                    <!-- P2B Payout Testing Suite Layout -->
                    <div class="row">
                        <!-- Left Column: Payout Initiation Form -->
                        <div class="col-lg-6">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header bg-navy text-white">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-wallet mr-2"></i> Execute P2B Bank Payout (Test)
                                    </h3>
                                </div>
                                <div class="card-body p-4">
                                    <form id="payout-testing-form">
                                        <!-- Sender Selection -->
                                        <div class="form-group">
                                            <label for="payout_sender_app_id" class="font-weight-bold text-navy">Sender Account</label>
                                            <select class="form-control" id="payout_sender_app_id" name="sender_app_id" required>
                                                <option value="">-- Select Sender Account --</option>
                                                <?php foreach ($senderOptions as $sender): ?>
                                                    <option value="<?= htmlspecialchars($sender['app_id']) ?>" 
                                                            data-balance="<?= htmlspecialchars($sender['balance']) ?>">
                                                        <?= htmlspecialchars($sender['full_name']) ?> (Acc: <?= htmlspecialchars($sender['account_number']) ?>) - Balance: <?= number_format($sender['balance'], 2) ?> INR <?= $sender['has_mpin'] ? '[MPIN Set]' : '[NO MPIN SET]' ?>
                                                    </option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>

                                        <!-- Beneficiary Details -->
                                        <div class="form-group">
                                            <label for="payout_beneficiary_name" class="font-weight-bold text-navy">Beneficiary Legal Name</label>
                                            <input type="text" class="form-control" id="payout_beneficiary_name" name="beneficiary_name" placeholder="e.g. Raju Rastogi" required>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="payout_beneficiary_account" class="font-weight-bold text-navy">Account Number</label>
                                                    <input type="text" class="form-control" id="payout_beneficiary_account" name="beneficiary_account" placeholder="e.g. 20437390017" required>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="payout_ifsc_code" class="font-weight-bold text-navy">Bank IFSC Code</label>
                                                    <input type="text" class="form-control" id="payout_ifsc_code" name="ifsc_code" placeholder="e.g. SBIN0015935" required pattern="^[A-Za-z]{4}0[A-Za-z0-9]{6}$" title="IFSC must be 11 characters (e.g. SBIN0015935)">
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Payout Amount -->
                                        <div class="form-group">
                                            <label for="payout_amount" class="font-weight-bold text-navy">Payout Amount (INR)</label>
                                            <input type="number" step="0.01" min="0.01" class="form-control" id="payout_amount" name="amount" placeholder="0.00" required>
                                        </div>

                                        <!-- Sender's 6-digit MPIN -->
                                        <div class="form-group">
                                            <label for="payout_mpin" class="font-weight-bold text-navy">Sender's 6-Digit MPIN</label>
                                            <input type="password" class="form-control" id="payout_mpin" name="mpin" placeholder="******" maxlength="6" pattern="\d{6}" required>
                                        </div>

                                        <button type="submit" class="btn btn-block btn-navy font-weight-bold py-2 text-white" style="background-color: #031f73;" id="btn-submit-payout">
                                            <i class="fas fa-paper-plane mr-2"></i> Initiate Payout Transfer
                                        </button>
                                    </form>

                                    <!-- Initiation Result & Raw Response Panel -->
                                    <div class="mt-4" id="payout-test-result-panel" style="display:none;">
                                        <div class="card card-outline shadow-sm" id="payout-result-card">
                                            <div class="card-header bg-light">
                                                <h5 class="m-0 font-weight-bold text-navy" id="payout-result-title">Initiation Status</h5>
                                            </div>
                                            <div class="card-body p-3">
                                                <table class="table table-striped table-sm mb-3">
                                                    <tbody>
                                                        <tr>
                                                            <td class="font-weight-bold" width="40%">Status</td>
                                                            <td><span class="badge px-2 py-1" id="payout-result-badge">PENDING</span></td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Transaction ID</td>
                                                            <td id="payout-result-txn-id">-</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Balance Remaining</td>
                                                            <td id="payout-result-balance">0.00 INR</td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                                
                                                <label class="font-weight-bold text-navy small">Raw API Response received from Provider:</label>
                                                <pre style="background-color: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 6px; overflow-x: auto; max-height: 180px;" class="small mb-0"><code id="payout-provider-json">{}</code></pre>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Right Column: Status Query Console -->
                        <div class="col-lg-6">
                            <!-- Status checker card -->
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header bg-navy text-white">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-search-dollar mr-2"></i> Query Payout Gateway Status
                                    </h3>
                                </div>
                                <div class="card-body p-4">
                                    <form id="payout-status-form">
                                        <!-- Recent transactions dropdown selection helper -->
                                        <div class="form-group">
                                            <label for="recent_payout_select" class="font-weight-bold text-navy">Select Recent Payout</label>
                                            <select class="form-control" id="recent_payout_select">
                                                <option value="">-- Choose Payout Transaction --</option>
                                                <?php foreach ($recentPayouts as $p): ?>
                                                    <option value="<?= htmlspecialchars($p['transaction_id']) ?>">
                                                        <?= htmlspecialchars($p['transaction_id']) ?> - <?= htmlspecialchars($p['recipient_name']) ?> (<?= number_format($p['amount'], 2) ?> INR) [<?= htmlspecialchars($p['status']) ?>]
                                                    </option>
                                                <?php endforeach; ?>
                                            </select>
                                            <small class="form-text text-muted">Select a payout from the list to copy its ID automatically.</small>
                                        </div>

                                        <!-- Direct Transaction/Order ID Input -->
                                        <div class="form-group">
                                            <label for="status_transaction_id" class="font-weight-bold text-navy">Transaction / Order ID</label>
                                            <input type="text" class="form-control" id="status_transaction_id" name="transaction_id" placeholder="e.g. TXN-FA0A443DC6" required>
                                        </div>

                                        <button type="submit" class="btn btn-block btn-warning font-weight-bold text-navy py-2" style="background-color: #fecb00; border-color: #fecb00;" id="btn-submit-status-check">
                                            <i class="fas fa-search mr-2"></i> Check Provider Status
                                        </button>
                                    </form>

                                    <!-- Status Result Display Panel -->
                                    <div class="mt-4" id="status-test-result-panel" style="display:none;">
                                        <div class="card card-outline shadow-sm" id="status-result-card">
                                            <div class="card-header bg-light">
                                                <h5 class="m-0 font-weight-bold text-navy"><i class="fas fa-info-circle mr-1"></i> Gateway Status Summary</h5>
                                            </div>
                                            <div class="card-body p-3">
                                                <!-- Visual Status Progress Timeline -->
                                                <div class="text-center mb-4">
                                                    <label class="font-weight-bold text-muted small d-block mb-3">Transaction Lifecycle Visual Timeline</label>
                                                    <div class="d-flex justify-content-between align-items-center position-relative px-4" style="max-width: 400px; margin: 0 auto;">
                                                        <!-- Line -->
                                                        <div class="position-absolute" style="top: 15px; left: 40px; right: 40px; height: 3px; background-color: #e0e0e0; z-index: 1;"></div>
                                                        <div class="position-absolute" id="timeline-progress-line" style="top: 15px; left: 40px; width: 0%; height: 3px; background-color: #28a745; z-index: 2; transition: width 0.4s ease;"></div>
                                                        
                                                        <!-- Step 1 -->
                                                        <div class="text-center" style="z-index: 3;">
                                                            <div class="rounded-circle d-flex align-items-center justify-content-center bg-success text-white" style="width: 32px; height: 32px; border: 3px solid #fff; font-weight: bold; font-size: 12px;" title="Initiated">1</div>
                                                            <span class="small font-weight-bold mt-1 d-block">Initiated</span>
                                                        </div>
                                                        
                                                        <!-- Step 2 -->
                                                        <div class="text-center" style="z-index: 3;">
                                                            <div class="rounded-circle d-flex align-items-center justify-content-center bg-secondary text-white" id="timeline-step-2" style="width: 32px; height: 32px; border: 3px solid #fff; font-weight: bold; font-size: 12px; transition: background-color 0.4s ease;" title="Pending">2</div>
                                                            <span class="small font-weight-bold mt-1 d-block">Pending</span>
                                                        </div>
                                                        
                                                        <!-- Step 3 -->
                                                        <div class="text-center" style="z-index: 3;">
                                                            <div class="rounded-circle d-flex align-items-center justify-content-center bg-secondary text-white" id="timeline-step-3" style="width: 32px; height: 32px; border: 3px solid #fff; font-weight: bold; font-size: 12px; transition: background-color 0.4s ease;" title="Completed">3</div>
                                                            <span class="small font-weight-bold mt-1 d-block" id="timeline-step-3-label">Success</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Status fields grid -->
                                                <table class="table table-striped table-sm mb-3">
                                                    <tbody>
                                                        <tr>
                                                            <td class="font-weight-bold" width="40%">System Status</td>
                                                            <td><span class="badge px-2 py-1" id="status-display-badge">PENDING</span></td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">UTR ID</td>
                                                            <td id="status-display-utr">-</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Recipient Name</td>
                                                            <td id="status-display-recipient">-</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Account / IFSC</td>
                                                            <td id="status-display-account-ifsc">-</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">Amount Details</td>
                                                            <td id="status-display-amount">0.00 INR</td>
                                                        </tr>
                                                        <tr>
                                                            <td class="font-weight-bold">System Log Reason</td>
                                                            <td id="status-display-reason" class="text-muted small">-</td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                                
                                                <label class="font-weight-bold text-navy small">Raw Status Response received from Provider API:</label>
                                                <pre style="background-color: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 6px; overflow-x: auto; max-height: 180px;" class="small mb-0"><code id="status-provider-json">{}</code></pre>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php elseif ($page === 'notifications'): ?>
                    <!-- Dedicated Send Notifications Card -->
                    <div class="row">
                        <div class="col-md-8 offset-md-2">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-bell mr-2"></i> Dispatch Push Notification
                                    </h3>
                                </div>
                                <div class="card-body p-4">
                                    <form id="bulk-notifications-form" enctype="multipart/form-data">
                                        <input type="hidden" name="action" value="SEND_BULK_NOTIFICATION">
                                        
                                        <!-- Target Audience Selection -->
                                        <div class="form-group">
                                            <label class="font-weight-bold text-navy">Target Audience</label>
                                            <div class="mt-2">
                                                <div class="custom-control custom-radio custom-control-inline">
                                                    <input type="radio" id="target_single" name="target" value="SINGLE" class="custom-control-input" checked>
                                                    <label class="custom-control-label" for="target_single">Single User</label>
                                                </div>
                                                <div class="custom-control custom-radio custom-control-inline">
                                                    <input type="radio" id="target_all" name="target" value="ALL" class="custom-control-input">
                                                    <label class="custom-control-label" for="target_all">All Users (Broadcast)</label>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <!-- Single User Selection Dropdown -->
                                        <div class="form-group" id="single-user-select-group">
                                            <label for="target_app_id" class="font-weight-bold text-navy">Select Recipient User</label>
                                            <select class="form-control" id="target_app_id" name="target_app_id" required>
                                                <option value="">-- Choose User --</option>
                                                <?php
                                                // Fetch all users
                                                $allApps = get_applications();
                                                foreach ($allApps as $app) {
                                                    $acc = get_account_by_app_id($app['app_id']);
                                                    $hasToken = (!empty($app['fcm_token']) || ($acc && !empty($acc['fcm_token'])));
                                                    $tokenStatus = $hasToken ? "Active Device Token" : "No Token (Will be logged only)";
                                                    echo '<option value="' . htmlspecialchars($app['app_id']) . '">' . 
                                                        htmlspecialchars($app['full_name']) . ' (' . htmlspecialchars($app['app_id']) . ') - ' . $tokenStatus . 
                                                        '</option>';
                                                }
                                                ?>
                                            </select>
                                        </div>
                                        
                                        <!-- Notification Title -->
                                        <div class="form-group">
                                            <label for="notification_title" class="font-weight-bold text-navy">Notification Title</label>
                                            <input type="text" class="form-control" id="notification_title" name="title" placeholder="Enter alert title" required>
                                        </div>
                                        
                                        <!-- Category Select -->
                                        <div class="form-group">
                                            <label for="notification_category" class="font-weight-bold text-navy">Category</label>
                                            <select class="form-control" id="notification_category" name="category" required>
                                                <option value="Updates" selected>Updates</option>
                                                <option value="Transactions">Transactions</option>
                                                <option value="Offers">Offers</option>
                                                <option value="Security">Security</option>
                                            </select>
                                        </div>
                                        
                                        <!-- Notification Message -->
                                        <div class="form-group">
                                            <label for="notification_body" class="font-weight-bold text-navy">Message Body</label>
                                            <textarea class="form-control" id="notification_body" name="body" rows="4" placeholder="Enter notification message body" required></textarea>
                                        </div>
                                        
                                        <!-- Photo Attachment -->
                                        <div class="form-group">
                                            <label for="notification_photo" class="font-weight-bold text-navy">Attach Photo (Optional)</label>
                                            <div class="custom-file">
                                                <input type="file" class="custom-file-input" id="notification_photo" name="photo" accept="image/*">
                                                <label class="custom-file-label" for="notification_photo">Choose image file...</label>
                                            </div>
                                            <small class="text-muted">Supported formats: JPG, JPEG, PNG, GIF. Max file size: 5MB.</small>
                                            <div id="image-preview-wrapper" class="mt-3 text-center" style="display: none;">
                                                <img id="image-preview" src="#" alt="Preview" class="img-thumbnail" style="max-height: 200px;">
                                            </div>
                                        </div>
                                        
                                        <!-- Submit Button -->
                                        <button type="submit" class="btn btn-primary btn-block font-weight-bold shadow-sm" id="btn-bulk-send">
                                            <i class="fas fa-paper-plane mr-1"></i> Dispatch Notification
                                        </button>
                                    </form>
                                    
                                    <!-- Receipt Details Card -->
                                    <div class="card mt-4 bg-light shadow-sm" id="bulk-receipt-card" style="display: none; border-left: 5px solid #28a745;">
                                        <div class="card-body">
                                            <h5 class="text-success font-weight-bold mb-3"><i class="fas fa-check-circle mr-1"></i> Dispatch Success Receipt</h5>
                                            <table class="table table-bordered table-sm mb-0 bg-white">
                                                <tbody>
                                                    <tr>
                                                        <td class="font-weight-bold" style="width: 150px;">Status</td>
                                                        <td><span class="badge badge-success">DELIVERED (SIMULATED)</span></td>
                                                    </tr>
                                                    <tr>
                                                        <td class="font-weight-bold">Recipients Notified</td>
                                                        <td id="receipt-recipients">0 users</td>
                                                    </tr>
                                                    <tr>
                                                        <td class="font-weight-bold">Attached Photo</td>
                                                        <td id="receipt-photo-attachment">None</td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php elseif ($page === 'statements'): ?>
                    <!-- Generated Statements List Card -->
                    <div class="row">
                        <div class="col-12">
                            <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                                <div class="card-header bg-navy text-white">
                                    <h3 class="card-title font-weight-bold">
                                        <i class="fas fa-file-invoice mr-2"></i> Generated Bank Statements Log
                                    </h3>
                                </div>
                                <div class="card-body p-0">
                                    <?php
                                    $dir = dirname(__DIR__) . '/uploads/statements';
                                    $files = [];
                                    if (is_dir($dir)) {
                                        $files = array_diff(scandir($dir), ['.', '..', '.DS_Store']);
                                    }
                                    
                                    $statementsLog = [];
                                    foreach ($files as $f) {
                                        if (preg_match('/^statement_(FR-\d+)_(20\d{6})_(\d{6})\.pdf$/', $f, $matches)) {
                                            $appId = $matches[1];
                                            $dateStr = $matches[2];
                                            $timeStr = $matches[3];
                                            
                                            $timestamp = DateTime::createFromFormat('Ymd His', $dateStr . ' ' . $timeStr);
                                            $formattedDate = $timestamp ? $timestamp->format('M d, Y H:i:s') : 'Unknown';
                                            
                                            $user = get_application_by_id($appId);
                                            $userName = $user ? $user['full_name'] : 'Unknown User';
                                            $phone = $user ? $user['phone'] : 'N/A';
                                            
                                            $statementsLog[] = [
                                                'filename' => $f,
                                                'app_id' => $appId,
                                                'user_name' => $userName,
                                                'phone' => $phone,
                                                'generated_at' => $formattedDate,
                                                'timestamp' => $timestamp ? $timestamp->getTimestamp() : 0,
                                                'url' => '../uploads/statements/' . $f
                                            ];
                                        }
                                    }
                                    
                                    usort($statementsLog, function($a, $b) {
                                        return $b['timestamp'] - $a['timestamp'];
                                    });
                                    ?>
                                    
                                    <?php if (empty($statementsLog)): ?>
                                        <div class="text-center py-5 text-muted">
                                            <i class="far fa-file-pdf fa-3x mb-3 text-navy"></i>
                                            <p class="mb-0 font-weight-bold">No generated statements found on the server.</p>
                                        </div>
                                    <?php else: ?>
                                        <table class="table table-hover table-bordered table-striped mb-0 text-dark">
                                            <thead>
                                                <tr>
                                                    <th>Applicant ID</th>
                                                    <th>Customer Name</th>
                                                    <th>Phone</th>
                                                    <th>Filename</th>
                                                    <th>Generated At</th>
                                                    <th>Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <?php foreach ($statementsLog as $s): ?>
                                                    <tr>
                                                        <td><strong><?= htmlspecialchars($s['app_id']) ?></strong></td>
                                                        <td><?= htmlspecialchars($s['user_name']) ?></td>
                                                        <td><?= htmlspecialchars($s['phone']) ?></td>
                                                        <td><code class="small"><?= htmlspecialchars($s['filename']) ?></code></td>
                                                        <td><?= htmlspecialchars($s['generated_at']) ?></td>
                                                        <td>
                                                            <a href="<?= htmlspecialchars($s['url']) ?>" class="btn btn-sm btn-primary font-weight-bold" target="_blank">
                                                                <i class="fas fa-file-download mr-1"></i> View / Download
                                                            </a>
                                                        </td>
                                                    </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                        </table>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php else: ?>
                    <!-- Info boxes / KPI Cards -->
                    <div class="row">
                    <div class="col-lg-3 col-6">
                        <div class="small-box brand-navy">
                            <div class="inner">
                                <h3><?= $total ?></h3>
                                <p>Total Applications</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-document-text"></i>
                            </div>
                            <a href="dashboard.php?filter=all" class="small-box-footer">View All <i class="fas fa-arrow-circle-right"></i></a>
                        </div>
                    </div>
                    
                    <div class="col-lg-3 col-6">
                        <div class="small-box brand-gold">
                            <div class="inner">
                                <h3><?= $pending ?></h3>
                                <p>In Review (Pending)</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-clock"></i>
                            </div>
                            <a href="#" class="small-box-footer" style="color:#031f73 !important;">Onboarding Checks <i class="fas fa-circle"></i></a>
                        </div>
                    </div>

                    <div class="col-lg-3 col-6">
                        <div class="small-box bg-success">
                            <div class="inner">
                                <h3><?= $approved ?></h3>
                                <p>Approved Accounts</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-checkmark-circled"></i>
                            </div>
                            <a href="#" class="small-box-footer">Onboarded <i class="fas fa-check"></i></a>
                        </div>
                    </div>

                    <div class="col-lg-3 col-6">
                        <div class="small-box bg-danger">
                            <div class="inner">
                                <h3><?= $rejected ?></h3>
                                <p>Rejected / Declined</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-close-circled"></i>
                            </div>
                            <a href="#" class="small-box-footer">Declined <i class="fas fa-times"></i></a>
                        </div>
                    </div>
                </div>
                <!-- /.row -->

                <!-- Applications Data Table Card -->
                <div class="row">
                    <div class="col-12">
                        <div class="card card-navy-brand card-primary">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">
                                    <i class="fas fa-folder-open mr-2"></i> 
                                    Incoming Requests (Filter: <?= htmlspecialchars($filter) ?>)
                                </h3>
                            </div>
                            <!-- /.card-header -->
                            <div class="card-body p-0">
                                <?php if (empty($filteredApps)): ?>
                                    <div class="text-center py-5 text-muted">
                                        <i class="far fa-folder-open fa-3x mb-3"></i>
                                        <p class="mb-0">No application submissions matching this filter.</p>
                                    </div>
                                <?php else: ?>
                                    <table class="table table-hover table-bordered table-striped table-middle mb-0">
                                        <thead>
                                            <tr>
                                                <th>App ID</th>
                                                <th>Applicant Name</th>
                                                <th>Account Type</th>
                                                <th>Contact Phone</th>
                                                <th>Verification Status</th>
                                                <th>Submission Date</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ($filteredApps as $app): ?>
                                                <tr id="row-<?= $app['app_id'] ?>">
                                                    <td><strong><?= htmlspecialchars($app['app_id']) ?></strong></td>
                                                    <td><?= htmlspecialchars($app['full_name']) ?></td>
                                                    <td>
                                                        <span class="badge badge-info py-1 px-2">
                                                            <i class="fas <?= ($app['account_type'] === 'SAVINGS' || $app['account_type'] === 'NRI') ? 'fa-user' : 'fa-building' ?> mr-1"></i>
                                                            <?= htmlspecialchars($app['account_type']) ?>
                                                        </span>
                                                    </td>
                                                    <td><?= htmlspecialchars($app['phone']) ?></td>
                                                    <td>
                                                        <?php if ($app['status'] === 'PENDING'): ?>
                                                            <span class="badge badge-warning py-1 px-2 text-dark"><i class="fas fa-sync-alt fa-spin mr-1"></i> PENDING</span>
                                                        <?php elseif ($app['status'] === 'APPROVED'): ?>
                                                            <span class="badge badge-success py-1 px-2"><i class="fas fa-check mr-1"></i> APPROVED</span>
                                                        <?php else: ?>
                                                            <span class="badge badge-danger py-1 px-2"><i class="fas fa-times mr-1"></i> REJECTED</span>
                                                        <?php endif; ?>
                                                    </td>
                                                    <td><?= date('M d, Y H:i', strtotime($app['created_at'])) ?></td>
                                                    <td>
                                                        <button class="btn btn-sm btn-primary" onclick="viewApplication('<?= base64_encode(json_encode($app)) ?>')">
                                                            <i class="fas fa-search-plus mr-1"></i> View & Process
                                                        </button>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                <?php endif; ?>
                            </div>
                            <!-- /.card-body -->
                        </div>
                        <!-- /.card -->
                    </div>
                </div>
                <?php endif; ?>

            </div><!-- /.container-fluid -->
        </div>
        <!-- /.content -->
    </div>
    <!-- /.content-wrapper -->

    <!-- Main Footer -->
    <footer class="main-footer">
        <div class="float-right d-none d-sm-inline">
            Deccan Finance Limited
        </div>
        <strong>Copyright &copy; 2026 Deccan Finance.</strong> All rights reserved.
    </footer>
</div>
<!-- ./wrapper -->

<!-- Application Review Bootstrap 4 Modal -->
<div class="modal fade" id="reviewModal" tabindex="-1" role="dialog" aria-labelledby="reviewModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header modal-header-brand">
                <h5 class="modal-title font-weight-bold" id="reviewModalLabel"><i class="fas fa-user-check mr-2"></i> Review Application</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body p-4" id="modal-details-body">
                <!-- Injected via JS -->
            </div>
            <div class="modal-footer bg-light" id="modal-footer-actions">
                <button type="button" class="btn btn-warning font-weight-bold mr-auto" id="btn-action-edit"><i class="fas fa-edit mr-1"></i> Edit Profile</button>
                <button type="button" class="btn btn-primary font-weight-bold mr-2" id="btn-action-statement" style="display: none;"><i class="fas fa-file-pdf mr-1"></i> Download Statement</button>
                <button type="button" class="btn btn-info font-weight-bold" id="btn-action-notify" style="display: none;"><i class="fas fa-bell mr-1"></i> Send Notification</button>
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-danger font-weight-bold" id="btn-action-reject"><i class="fas fa-user-slash mr-1"></i> Reject Applicant</button>
                <button type="button" class="btn btn-success font-weight-bold" id="btn-action-approve"><i class="fas fa-user-plus mr-1"></i> Approve Account</button>
            </div>
        </div>
    </div>
</div>

<!-- Send Notification Bootstrap 4 Modal -->
<div class="modal fade" id="sendNotificationModal" tabindex="-1" role="dialog" aria-labelledby="sendNotificationModalLabel" aria-hidden="true" style="z-index: 1060;">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header bg-navy text-white" style="background-color: #031f73 !important; color: white !important; border-bottom: 4px solid #fecb00 !important;">
                <h5 class="modal-title font-weight-bold" id="sendNotificationModalLabel"><i class="fas fa-bell mr-2"></i> Send FCM Push Notification</h5>
                <button type="button" class="close text-white" onclick="$('#sendNotificationModal').modal('hide')" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="notificationForm">
                <div class="modal-body p-4">
                    <div class="form-group">
                        <label class="font-weight-bold">FCM Device Token</label>
                        <input type="text" class="form-control bg-light" id="notify-fcm-token" readonly required>
                        <small class="form-text text-muted">The unique registration token identifying the user's active login session device.</small>
                    </div>
                    <div class="form-group">
                        <label for="notify-title" class="font-weight-bold">Notification Title</label>
                        <input type="text" class="form-control" id="notify-title" placeholder="e.g. Transaction Alert" required>
                    </div>
                    <div class="form-group">
                        <label for="notify-category" class="font-weight-bold">Category</label>
                        <select class="form-control" id="notify-category" required>
                            <option value="Updates" selected>Updates</option>
                            <option value="Transactions">Transactions</option>
                            <option value="Offers">Offers</option>
                            <option value="Security">Security</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="notify-body" class="font-weight-bold">Notification Message (Body)</label>
                        <textarea class="form-control" id="notify-body" rows="4" placeholder="Enter message body here..." required></textarea>
                    </div>
                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary font-weight-bold" onclick="$('#sendNotificationModal').modal('hide')">Cancel</button>
                    <button type="submit" class="btn btn-info font-weight-bold" id="btn-send-notification-submit"><i class="fas fa-paper-plane mr-1"></i> Send Push Notification</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Profile Bootstrap 4 Modal -->
<div class="modal fade" id="editProfileModal" tabindex="-1" role="dialog" aria-labelledby="editProfileModalLabel" aria-hidden="true" style="z-index: 1060;">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header modal-header-brand" style="background-color: #031f73 !important; color: white !important; border-bottom: 4px solid #fecb00 !important;">
                <h5 class="modal-title font-weight-bold" id="editProfileModalLabel"><i class="fas fa-edit mr-2"></i> Edit Profile Details</h5>
                <button type="button" class="close text-white" onclick="$('#editProfileModal').modal('hide')" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="edit-profile-form">
                <div class="modal-body p-4">
                    <div class="form-group">
                        <label for="edit-full-name" class="small font-weight-bold text-navy">Full Name</label>
                        <input type="text" class="form-control form-control-sm" id="edit-full-name" name="full_name" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-email" class="small font-weight-bold text-navy">Email Address</label>
                        <input type="email" class="form-control form-control-sm" id="edit-email" name="email" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-phone" class="small font-weight-bold text-navy">Phone Number</label>
                        <input type="text" class="form-control form-control-sm" id="edit-phone" name="phone" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-address" class="small font-weight-bold text-navy">Mailing Address</label>
                        <textarea class="form-control form-control-sm" id="edit-address" name="address" rows="2" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="edit-national-id" class="small font-weight-bold text-navy">PAN / ID Number</label>
                        <input type="text" class="form-control form-control-sm" id="edit-national-id" name="national_id" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-aadhaar-number" class="small font-weight-bold text-navy">Aadhaar Number</label>
                        <input type="text" class="form-control form-control-sm" id="edit-aadhaar-number" name="aadhaar_number" required>
                    </div>
                    
                    <!-- Dynamic fields based on account type -->
                    <div id="edit-savings-fields" style="display:none;">
                        <div class="form-group">
                            <label for="edit-dob" class="small font-weight-bold text-navy">Date of Birth</label>
                            <input type="date" class="form-control form-control-sm" id="edit-dob" name="dob">
                        </div>
                        <div class="form-group">
                            <label for="edit-gender" class="small font-weight-bold text-navy">Gender</label>
                            <select class="form-control form-control-sm" id="edit-gender" name="gender">
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>
                    
                    <div id="edit-current-fields" style="display:none;">
                        <div class="form-group">
                            <label for="edit-business-name" class="small font-weight-bold text-navy">Business Name</label>
                            <input type="text" class="form-control form-control-sm" id="edit-business-name" name="business_name">
                        </div>
                        <div class="form-group">
                            <label for="edit-business-reg-no" class="small font-weight-bold text-navy">GST / Registration No.</label>
                            <input type="text" class="form-control form-control-sm" id="edit-business-reg-no" name="business_reg_no">
                        </div>
                        <div class="form-group">
                            <label for="edit-expected-turnover" class="small font-weight-bold text-navy">Expected Turnover (INR)</label>
                            <input type="number" step="0.01" class="form-control form-control-sm" id="edit-expected-turnover" name="expected_turnover">
                        </div>
                    </div>
                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary btn-sm" onclick="$('#editProfileModal').modal('hide')">Cancel</button>
                    <button type="submit" class="btn btn-warning btn-sm font-weight-bold" style="color: #031f73;"><i class="fas fa-save mr-1"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- REQUIRED SCRIPTS -->
<!-- jQuery -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<!-- Bootstrap 4 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<!-- AdminLTE App -->
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
    let currentAppId = null;
    let activeApp = null;

    function viewApplication(appBase64) {
        let app;
        try {
            app = JSON.parse(atob(appBase64));
        } catch(e) {
            console.error("Failed to parse application data: ", e);
            alert("Error: Failed to parse applicant data.");
            return;
        }
        currentAppId = app.app_id;
        activeApp = app;
        
        let statusBadge = '';
        if (app.status === 'PENDING') {
            statusBadge = '<span class="badge badge-warning text-dark"><i class="fas fa-sync-alt fa-spin mr-1"></i> PENDING</span>';
        } else if (app.status === 'APPROVED') {
            statusBadge = '<span class="badge badge-success"><i class="fas fa-check mr-1"></i> APPROVED</span>';
        } else {
            statusBadge = '<span class="badge badge-danger"><i class="fas fa-times mr-1"></i> REJECTED</span>';
        }

        // Build HTML details structure
        let html = `
            <div class="row mb-4">
                <div class="col-sm-6">
                    <h5 class="text-navy font-weight-bold">Application ID: ${app.app_id}</h5>
                </div>
                <div class="col-sm-6 text-sm-right">
                    ${statusBadge}
                </div>
            </div>
            
            <div class="row">
                <!-- Data Fields Column -->
                <div class="col-md-7">
                    <div class="card card-outline card-primary">
                        <div class="card-body p-0">
                            <table class="table table-striped table-sm mb-0">
                                <tbody>
                                    <tr>
                                        <td class="font-weight-bold pl-3" width="40%">Account Type</td>
                                        <td>${app.account_type}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Full Name</td>
                                        <td>${escapeHtml(app.full_name)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Email Address</td>
                                        <td>${escapeHtml(app.email)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Phone Number</td>
                                        <td>${escapeHtml(app.phone)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Mailing Address</td>
                                        <td>${escapeHtml(app.address)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">PAN / ID No.</td>
                                        <td>${escapeHtml(app.national_id)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Aadhaar Number</td>
                                        <td>${escapeHtml(app.aadhaar_number || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3 text-danger">User Password</td>
                                        <td class="text-danger font-weight-bold">${escapeHtml(app.password_hash || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">FCM Token</td>
                                        <td><code style="font-size: 85%; word-break: break-all;">${escapeHtml(app.fcm_token || app.fmc_token || 'NOT_REGISTERED')}</code></td>
                                    </tr>
        `;

        if (app.account_type === 'SAVINGS' || app.account_type === 'NRI') {
            html += `
                                    <tr>
                                        <td class="font-weight-bold pl-3">Date of Birth</td>
                                        <td>${escapeHtml(app.dob || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Gender</td>
                                        <td>${escapeHtml(app.gender || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Initial Deposit</td>
                                        <td>${app.initial_deposit ? parseFloat(app.initial_deposit).toLocaleString() + ' INR' : '0.00 INR'}</td>
                                    </tr>
            `;
        } else {
            html += `
                                    <tr>
                                        <td class="font-weight-bold pl-3">Business Name</td>
                                        <td>${escapeHtml(app.business_name || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">GST / Reg No.</td>
                                        <td>${escapeHtml(app.business_reg_no || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Turnover Volume</td>
                                        <td>${app.expected_turnover ? parseFloat(app.expected_turnover).toLocaleString() + ' INR' : 'N/A'}</td>
                                    </tr>
            `;
        }

        html += `
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Photo & Signature Column -->
                <div class="col-md-5">
                    <div class="card card-outline card-warning">
                        <div class="card-body text-center p-3">
                            <h6 class="font-weight-bold text-navy mb-2"><i class="fas fa-camera mr-1"></i> Portrait Photo Capture</h6>
                            <img src="../${app.photo_path}" class="detail-img-frame rounded-circle mb-3" style="width: 130px; height: 130px; object-fit: cover;">
                            
                            <h6 class="font-weight-bold text-navy mb-2"><i class="fas fa-signature mr-1"></i> Drawn Signature</h6>
                            <img src="../${app.signature_path}" class="detail-img-frame" style="width: 100%; height: 90px; object-fit: contain;">
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- KYC Documents Capture Row -->
            <div class="row mt-3">
                <div class="col-12">
                    <div class="card card-outline card-info">
                        <div class="card-body p-3">
                            <h6 class="font-weight-bold text-navy mb-3"><i class="fas fa-file-contract mr-1"></i> Live KYC Documents (Front)</h6>
                            <div class="row text-center">
                                <div class="col-sm-6 mb-2">
                                    <div class="font-weight-bold text-muted small mb-1">PAN Card / Business ID</div>
                                    <img src="../${app.doc_pan_path}" class="detail-img-frame" style="width: 100%; height: 180px; object-fit: cover;">
                                </div>
                                <div class="col-sm-6">
                                    <div class="font-weight-bold text-muted small mb-1">Aadhaar Card / Address Proof</div>
                                    <img src="../${app.doc_aadhaar_path}" class="detail-img-frame" style="width: 100%; height: 180px; object-fit: cover;">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        if (app.status === 'APPROVED') {
            html += `
            <!-- Financial Balance Management Block -->
            <div class="row mt-3">
                <div class="col-12">
                    <div class="card card-outline card-success">
                        <div class="card-header py-2">
                            <h6 class="card-title font-weight-bold text-success m-0"><i class="fas fa-wallet mr-1"></i> Balance Management</h6>
                        </div>
                        <div class="card-body p-3">
                            <div class="row align-items-center">
                                <div class="col-sm-5 mb-2 mb-sm-0">
                                    <span class="text-muted d-block small">CURRENT BALANCE</span>
                                    <span class="h4 font-weight-bold text-navy mb-0" id="current-balance-display">${parseFloat(app.balance || 0).toLocaleString()} INR</span>
                                </div>
                                <div class="col-sm-7">
                                    <div class="form-inline justify-content-sm-end">
                                        <div class="input-group input-group-sm mr-2 mb-2 mb-sm-0">
                                            <input type="number" step="0.01" min="0.01" class="form-control" id="adjust-amount" placeholder="Amount (INR)" required style="height: 31px; border-radius: 4px;">
                                        </div>
                                        <button type="button" class="btn btn-sm btn-success font-weight-bold mr-1" id="btn-balance-add"><i class="fas fa-plus mr-1"></i> Add</button>
                                        <button type="button" class="btn btn-sm btn-danger font-weight-bold" id="btn-balance-deduct"><i class="fas fa-minus mr-1"></i> Deduct</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            `;
        }

        document.getElementById('modal-details-body').innerHTML = html;

        // Set up balance adjustment buttons
        const btnBalanceAdd = document.getElementById('btn-balance-add');
        const btnBalanceDeduct = document.getElementById('btn-balance-deduct');
        if (btnBalanceAdd && btnBalanceDeduct) {
            const handleAdjustment = (type) => {
                const amountInput = document.getElementById('adjust-amount');
                const amount = parseFloat(amountInput.value);
                if (isNaN(amount) || amount <= 0) {
                    alert('Please enter a valid amount greater than 0.');
                    return;
                }
                
                const formData = new FormData();
                formData.append('app_id', currentAppId);
                formData.append('action', 'ADJUST_BALANCE');
                formData.append('amount', amount);
                formData.append('type', type);
                
                fetch('dashboard.php', {
                    method: 'POST',
                    body: formData
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        alert(`Successfully processed: ${type === 'DEPOSIT' ? 'Added' : 'Deducted'} ${amount} INR`);
                        // Update display in modal
                        document.getElementById('current-balance-display').textContent = parseFloat(data.new_balance).toLocaleString() + ' INR';
                        // Update balance in local object representation
                        activeApp.balance = data.new_balance;
                        // Clear input field
                        amountInput.value = '';
                    } else {
                        alert('Transaction failed: ' + (data.message || 'Unknown error'));
                    }
                })
                .catch(err => {
                    alert('Network error: Transaction could not be completed.');
                });
            };
            
            btnBalanceAdd.addEventListener('click', () => handleAdjustment('DEPOSIT'));
            btnBalanceDeduct.addEventListener('click', () => handleAdjustment('WITHDRAW'));
        }

        // Toggle action buttons in footer based on PENDING status
        const footer = document.getElementById('modal-footer-actions');
        const btnReject = document.getElementById('btn-action-reject');
        const btnApprove = document.getElementById('btn-action-approve');
        const btnNotify = document.getElementById('btn-action-notify');
        const btnStatement = document.getElementById('btn-action-statement');
        
        if (app.status === 'APPROVED' || app.status === 'PENDING') {
            btnStatement.style.display = 'inline-block';
        } else {
            btnStatement.style.display = 'none';
        }
        
        if (app.status === 'PENDING') {
            btnReject.style.display = 'inline-block';
            btnApprove.style.display = 'inline-block';
            btnNotify.style.display = 'none';
        } else if (app.status === 'APPROVED') {
            btnReject.style.display = 'none';
            btnApprove.style.display = 'none';
            btnNotify.style.display = 'inline-block';
        } else {
            btnReject.style.display = 'none';
            btnApprove.style.display = 'none';
            btnNotify.style.display = 'none';
        }

        // Show Modal
        $('#reviewModal').modal('show');
    }

    // Modal Actions handlers
    document.getElementById('btn-action-approve').addEventListener('click', () => {
        updateApplicationStatus(currentAppId, 'APPROVE');
    });

    document.getElementById('btn-action-statement').addEventListener('click', () => {
        if (!currentAppId) return;
        window.open('../api/get_statement.php?download=1&app_id=' + currentAppId, '_blank');
    });

    document.getElementById('btn-action-reject').addEventListener('click', () => {
        updateApplicationStatus(currentAppId, 'REJECT');
    });

    document.getElementById('btn-action-edit').addEventListener('click', () => {
        if (!activeApp) return;
        
        // Populate form fields
        document.getElementById('edit-full-name').value = activeApp.full_name;
        document.getElementById('edit-email').value = activeApp.email;
        document.getElementById('edit-phone').value = activeApp.phone;
        document.getElementById('edit-address').value = activeApp.address;
        document.getElementById('edit-national-id').value = activeApp.national_id;
        document.getElementById('edit-aadhaar-number').value = activeApp.aadhaar_number || '';
        
        if (activeApp.account_type === 'SAVINGS' || activeApp.account_type === 'NRI') {
            document.getElementById('edit-savings-fields').style.display = 'block';
            document.getElementById('edit-current-fields').style.display = 'none';
            document.getElementById('edit-dob').value = activeApp.dob || '';
            document.getElementById('edit-gender').value = activeApp.gender || 'Male';
        } else {
            document.getElementById('edit-savings-fields').style.display = 'none';
            document.getElementById('edit-current-fields').style.display = 'block';
            document.getElementById('edit-business-name').value = activeApp.business_name || '';
            document.getElementById('edit-business-reg-no').value = activeApp.business_reg_no || '';
            document.getElementById('edit-expected-turnover').value = activeApp.expected_turnover || '';
        }
        
        // Show Edit Modal
        $('#editProfileModal').modal('show');
    });

    document.getElementById('edit-profile-form').addEventListener('submit', (e) => {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        formData.append('app_id', activeApp.app_id);
        formData.append('action', 'UPDATE_PROFILE');
        
        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                $('#editProfileModal').modal('hide');
                $('#reviewModal').modal('hide');
                alert('Profile details updated successfully!');
                window.location.reload();
            } else {
                alert('Error updating profile: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(err => {
            alert('Server error: Failed to save changes.');
        });
    });

    document.getElementById('btn-action-notify').addEventListener('click', () => {
        if (!activeApp) return;
        
        // Hide review modal
        $('#reviewModal').modal('hide');
        
        // Populate FCM token field
        document.getElementById('notify-fcm-token').value = activeApp.fcm_token || activeApp.fmc_token || '';
        document.getElementById('notify-title').value = '';
        document.getElementById('notify-body').value = '';
        
        if (!activeApp.fcm_token && !activeApp.fmc_token) {
            alert("Warning: This user does not have a registered FCM Device Token yet. Notification will be mock-recorded in database logs but cannot be delivered to a device.");
        }
        
        // Show notification modal
        $('#sendNotificationModal').modal('show');
    });

    document.getElementById('notificationForm').addEventListener('submit', (e) => {
        e.preventDefault();
        
        const fcmToken = document.getElementById('notify-fcm-token').value;
        const title = document.getElementById('notify-title').value;
        const category = document.getElementById('notify-category').value;
        const body = document.getElementById('notify-body').value;
        
        const btnSubmit = document.getElementById('btn-send-notification-submit');
        btnSubmit.disabled = true;
        btnSubmit.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Sending...';
        
        const formData = new FormData();
        formData.append('action', 'SEND_NOTIFICATION');
        formData.append('app_id', currentAppId);
        formData.append('fcm_token', fcmToken);
        formData.append('title', title);
        formData.append('category', category);
        formData.append('body', body);
        
        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            btnSubmit.disabled = false;
            btnSubmit.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Send Push Notification';
            
            if (data.success) {
                alert('Success: ' + data.message);
                $('#sendNotificationModal').modal('hide');
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(err => {
            btnSubmit.disabled = false;
            btnSubmit.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Send Push Notification';
            alert('Network error while sending notification.');
        });
    });

    function updateApplicationStatus(appId, action) {
        if (!confirm(`Are you sure you want to ${action.toLowerCase()} application ${appId}?`)) {
            return;
        }

        const formData = new FormData();
        formData.append('app_id', appId);
        formData.append('action', action);

        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                $('#reviewModal').modal('hide');
                // Refresh to reload stats and tables
                window.location.reload();
            } else {
                alert('Error updating application: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(err => {
            alert('Server error: Failed to complete request.');
        });
    }

    function escapeHtml(str) {
        if (str === null || str === undefined) return '';
        str = String(str);
        return str
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    // P2P Testing Suite Scripting
    const p2pForm = document.getElementById('p2p-testing-form');
    if (p2pForm) {
        const btnVerifyRecipient = document.getElementById('btn-verify-recipient-test');
        const recipientInput = document.getElementById('recipient_account_number');
        const verificationResult = document.getElementById('recipient-verification-result');
        const receiptDiv = document.getElementById('p2p-test-receipt');

        // Function to perform recipient verification
        const verifyRecipient = () => {
            const recipientAcc = recipientInput.value.trim();
            if (recipientAcc.length !== 11 || isNaN(recipientAcc)) {
                verificationResult.style.display = 'block';
                verificationResult.className = 'text-danger font-weight-bold small';
                verificationResult.innerHTML = '<i class="fas fa-exclamation-circle mr-1"></i> Account number must be exactly 11 digits.';
                return;
            }

            verificationResult.style.display = 'block';
            verificationResult.className = 'text-muted small';
            verificationResult.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Verifying account...';

            const formData = new FormData();
            formData.append('action', 'VERIFY_RECIPIENT_TEST');
            formData.append('recipient_account_number', recipientAcc);

            fetch('dashboard.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    verificationResult.className = 'text-success font-weight-bold small';
                    verificationResult.innerHTML = `<i class="fas fa-check-circle mr-1"></i> Verified: <strong>${escapeHtml(data.full_name)}</strong> (Acc: ${escapeHtml(data.account_number)})`;
                } else {
                    verificationResult.className = 'text-danger font-weight-bold small';
                    verificationResult.innerHTML = `<i class="fas fa-times-circle mr-1"></i> Verification failed: ${escapeHtml(data.message || 'Account not found')}`;
                }
            })
            .catch(err => {
                verificationResult.className = 'text-danger font-weight-bold small';
                verificationResult.innerHTML = '<i class="fas fa-exclamation-triangle mr-1"></i> Network error during verification.';
            });
        };

        btnVerifyRecipient.addEventListener('click', verifyRecipient);
        
        // Form submit handler to execute transfer
        p2pForm.addEventListener('submit', (e) => {
            e.preventDefault();
            
            // Hide previous receipt
            receiptDiv.style.display = 'none';

            const senderSelect = document.getElementById('sender_app_id');
            const selectedOption = senderSelect.options[senderSelect.selectedIndex];
            
            if (!senderSelect.value) {
                alert('Please select a sender account.');
                return;
            }

            const senderAppId = senderSelect.value;
            const recipientAcc = recipientInput.value.trim();
            const amount = parseFloat(document.getElementById('amount').value);
            const mpin = document.getElementById('mpin').value.trim();

            if (recipientAcc.length !== 11) {
                alert('Recipient account must be exactly 11 digits.');
                return;
            }

            if (mpin.length !== 6) {
                alert('MPIN must be exactly 6 digits.');
                return;
            }

            if (amount <= 0 || isNaN(amount)) {
                alert('Please enter a valid amount.');
                return;
            }

            const btnSubmit = document.getElementById('btn-submit-transfer');
            const originalBtnText = btnSubmit.innerHTML;
            btnSubmit.disabled = true;
            btnSubmit.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Processing Transfer...';

            const formData = new FormData();
            formData.append('action', 'EXECUTE_P2P_TEST');
            formData.append('sender_app_id', senderAppId);
            formData.append('recipient_account_number', recipientAcc);
            formData.append('amount', amount);
            formData.append('mpin', mpin);

            fetch('dashboard.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = originalBtnText;

                if (data.success) {
                    alert('Transfer completed successfully!');
                    
                    // Show receipt details
                    document.getElementById('receipt-txn-id').textContent = data.transaction_id;
                    document.getElementById('receipt-utr-id').textContent = data.utr_id;
                    document.getElementById('receipt-amount').textContent = amount.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' INR';
                    document.getElementById('receipt-sender-balance').textContent = parseFloat(data.new_balance).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' INR';
                    
                    receiptDiv.style.display = 'block';

                    // Update option balance in dropdown list to keep UI synchronized
                    selectedOption.setAttribute('data-balance', data.new_balance);
                    selectedOption.text = `${selectedOption.text.split(' - Balance:')[0]} - Balance: ${parseFloat(data.new_balance).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} INR ${selectedOption.text.includes('[MPIN Set]') ? '[MPIN Set]' : '[NO MPIN SET]'}`;

                    // Reset amount and mpin inputs
                    document.getElementById('amount').value = '';
                    document.getElementById('mpin').value = '';
                    verificationResult.style.display = 'none';
                } else {
                    alert('Transfer failed: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(err => {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = originalBtnText;
                alert('Server error: Could not complete transfer request.');
            });
        });
    }

    // P2B Payout Testing Suite Scripting
    const payoutForm = document.getElementById('payout-testing-form');
    if (payoutForm) {
        const payoutResultPanel = document.getElementById('payout-test-result-panel');
        const payoutResultCard = document.getElementById('payout-result-card');
        const payoutResultBadge = document.getElementById('payout-result-badge');
        const payoutResultTxnId = document.getElementById('payout-result-txn-id');
        const payoutResultBalance = document.getElementById('payout-result-balance');
        const payoutProviderJson = document.getElementById('payout-provider-json');
        
        payoutForm.addEventListener('submit', (e) => {
            e.preventDefault();
            payoutResultPanel.style.display = 'none';

            const senderSelect = document.getElementById('payout_sender_app_id');
            const selectedOption = senderSelect.options[senderSelect.selectedIndex];

            if (!senderSelect.value) {
                alert('Please select a sender account.');
                return;
            }

            const senderAppId = senderSelect.value;
            const beneficiaryName = document.getElementById('payout_beneficiary_name').value.trim();
            const beneficiaryAccount = document.getElementById('payout_beneficiary_account').value.trim();
            const ifscCode = document.getElementById('payout_ifsc_code').value.trim().toUpperCase();
            const amount = parseFloat(document.getElementById('payout_amount').value);
            const mpin = document.getElementById('payout_mpin').value.trim();

            const btnSubmit = document.getElementById('btn-submit-payout');
            const originalBtnText = btnSubmit.innerHTML;
            btnSubmit.disabled = true;
            btnSubmit.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Initiating Payout...';

            const formData = new FormData();
            formData.append('action', 'EXECUTE_PAYOUT_TEST');
            formData.append('sender_app_id', senderAppId);
            formData.append('beneficiary_name', beneficiaryName);
            formData.append('beneficiary_account', beneficiaryAccount);
            formData.append('ifsc_code', ifscCode);
            formData.append('amount', amount);
            formData.append('mpin', mpin);

            fetch('dashboard.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = originalBtnText;

                payoutResultPanel.style.display = 'block';
                payoutProviderJson.textContent = JSON.stringify(data.provider_response, null, 2);

                if (data.success) {
                    payoutResultCard.className = 'card card-outline card-success shadow-sm';
                    payoutResultBadge.className = 'badge badge-success px-2 py-1';
                    payoutResultBadge.textContent = data.status || 'PENDING';
                    payoutResultTxnId.textContent = data.transaction_id;
                    payoutResultBalance.textContent = parseFloat(data.new_balance).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' INR';
                    
                    // Update balance in dropdown
                    selectedOption.setAttribute('data-balance', data.new_balance);
                    selectedOption.text = `${selectedOption.text.split(' - Balance:')[0]} - Balance: ${parseFloat(data.new_balance).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} INR ${selectedOption.text.includes('[MPIN Set]') ? '[MPIN Set]' : '[NO MPIN SET]'}`;

                    // Reset values
                    document.getElementById('payout_amount').value = '';
                    document.getElementById('payout_mpin').value = '';
                    alert('Payout initiated successfully via test environment!');
                } else {
                    payoutResultCard.className = 'card card-outline card-danger shadow-sm';
                    payoutResultBadge.className = 'badge badge-danger px-2 py-1';
                    payoutResultBadge.textContent = data.status || 'FAILED';
                    payoutResultTxnId.textContent = data.transaction_id || 'FAILED';
                    payoutResultBalance.textContent = parseFloat(data.new_balance).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' INR';
                    alert('Payout Failed: ' + data.message);
                }
            })
            .catch(err => {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = originalBtnText;
                alert('Network error during payout initiation.');
            });
        });
    }

    const payoutStatusForm = document.getElementById('payout-status-form');
    if (payoutStatusForm) {
        const recentSelect = document.getElementById('recent_payout_select');
        const inputTxnId = document.getElementById('status_transaction_id');
        const statusResultPanel = document.getElementById('status-test-result-panel');
        
        const timelineProgress = document.getElementById('timeline-progress-line');
        const step2Circle = document.getElementById('timeline-step-2');
        const step3Circle = document.getElementById('timeline-step-3');
        const step3Label = document.getElementById('timeline-step-3-label');

        const badgeSystem = document.getElementById('status-display-badge');
        const textUtr = document.getElementById('status-display-utr');
        const textRecipient = document.getElementById('status-display-recipient');
        const textAccountIfsc = document.getElementById('status-display-account-ifsc');
        const textAmount = document.getElementById('status-display-amount');
        const textReason = document.getElementById('status-display-reason');
        const statusJson = document.getElementById('status-provider-json');

        // Dropdown select change handler to copy ID to input
        recentSelect.addEventListener('change', () => {
            if (recentSelect.value) {
                inputTxnId.value = recentSelect.value;
            }
        });

        payoutStatusForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const txnId = inputTxnId.value.trim();
            if (!txnId) {
                alert('Please enter a Transaction ID.');
                return;
            }

            const btnCheck = document.getElementById('btn-submit-status-check');
            const originalBtnText = btnCheck.innerHTML;
            btnCheck.disabled = true;
            btnCheck.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Checking Status...';

            const formData = new FormData();
            formData.append('action', 'CHECK_PAYOUT_STATUS_TEST');
            formData.append('transaction_id', txnId);

            fetch('dashboard.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btnCheck.disabled = false;
                btnCheck.innerHTML = originalBtnText;

                if (!data.success && !data.transaction) {
                    alert('Error checking status: ' + data.message);
                    return;
                }

                statusResultPanel.style.display = 'block';
                statusJson.textContent = JSON.stringify(data.provider_response, null, 2);

                const txn = data.transaction || {};
                const statusStr = (txn.status || 'PENDING').toUpperCase();
                
                // Update Badge
                badgeSystem.textContent = statusStr;
                if (statusStr === 'SUCCESS') {
                    badgeSystem.className = 'badge badge-success px-2 py-1';
                } else if (statusStr === 'PENDING') {
                    badgeSystem.className = 'badge badge-warning px-2 py-1';
                } else if (statusStr === 'FAILED_HELD') {
                    badgeSystem.className = 'badge badge-warning bg-orange text-white px-2 py-1';
                } else {
                    badgeSystem.className = 'badge badge-danger px-2 py-1';
                }

                // Update text fields
                textUtr.textContent = txn.utr_id || '-';
                textRecipient.textContent = txn.recipient_name || '-';
                textAccountIfsc.textContent = `${txn.recipient_account || '-'} / ${txn.ifsc_code || '-'}`;
                textAmount.textContent = parseFloat(txn.amount || 0).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' INR';
                textReason.textContent = txn.status_details || '-';

                // Adjust Visual Timeline Progress
                if (statusStr === 'SUCCESS') {
                    timelineProgress.style.width = '100%';
                    step2Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-success text-white';
                    step3Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-success text-white';
                    step3Label.textContent = 'Success';
                    step3Label.className = 'small font-weight-bold mt-1 d-block text-success';
                } else if (statusStr === 'PENDING') {
                    timelineProgress.style.width = '50%';
                    step2Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-warning text-white';
                    step3Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-secondary text-white';
                    step3Label.textContent = 'Success';
                    step3Label.className = 'small font-weight-bold mt-1 d-block';
                } else if (statusStr === 'FAILED_HELD') {
                    timelineProgress.style.width = '100%';
                    step2Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-success text-white';
                    step3Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-warning text-white';
                    step3Label.textContent = 'Quarantined';
                    step3Label.className = 'small font-weight-bold mt-1 d-block text-warning';
                } else {
                    timelineProgress.style.width = '100%';
                    step2Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-success text-white';
                    step3Circle.className = 'rounded-circle d-flex align-items-center justify-content-center bg-danger text-white';
                    step3Label.textContent = 'Failed';
                    step3Label.className = 'small font-weight-bold mt-1 d-block text-danger';
                }
            })
            .catch(err => {
                btnCheck.disabled = false;
                btnCheck.innerHTML = originalBtnText;
                alert('Network error during status check.');
            });
        });
    }

    // Payout Quarantine Queue Actions
    window.retryPayout = function(txnId) {
        if (!confirm(`Are you sure you want to retry payout for transaction ${txnId}?`)) return;
        
        const formData = new FormData();
        formData.append('action', 'RETRY_PAYOUT');
        formData.append('transaction_id', txnId);
        
        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                alert('Success: ' + data.message);
                window.location.reload();
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(err => {
            alert('Server error occurred during retry request.');
        });
    };

    window.refundPayout = function(txnId) {
        if (!confirm(`Are you sure you want to mark transaction ${txnId} as FAILED and refund the sender's balance?`)) return;
        
        const formData = new FormData();
        formData.append('action', 'REFUND_PAYOUT');
        formData.append('transaction_id', txnId);
        
        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                alert('Success: ' + data.message);
                window.location.reload();
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(err => {
            alert('Server error occurred during refund request.');
        });
    };

    // Beneficiary Approval Actions
    window.approveBeneficiary = function(id) {
        if (!confirm('Are you sure you want to approve this beneficiary?')) return;
        updateBeneficiaryStatus(id, 'APPROVE_BENEFICIARY');
    };

    window.rejectBeneficiary = function(id) {
        if (!confirm('Are you sure you want to reject this beneficiary?')) return;
        updateBeneficiaryStatus(id, 'REJECT_BENEFICIARY');
    };

    function updateBeneficiaryStatus(id, action) {
        const formData = new FormData();
        formData.append('action', action);
        formData.append('id', id);

        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                alert('Beneficiary status updated successfully!');
                window.location.reload();
            } else {
                alert('Failed to update status: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(err => {
            alert('Server error occurred.');
        });
    }

    // Dedicated bulk and single notification dispatch page logic
    const targetSingle = document.getElementById('target_single');
    const targetAll = document.getElementById('target_all');
    const singleUserGroup = document.getElementById('single-user-select-group');
    const targetAppSelect = document.getElementById('target_app_id');
    
    if (targetSingle && targetAll && singleUserGroup) {
        targetSingle.addEventListener('change', () => {
            singleUserGroup.style.display = 'block';
            if (targetAppSelect) targetAppSelect.required = true;
        });
        targetAll.addEventListener('change', () => {
            singleUserGroup.style.display = 'none';
            if (targetAppSelect) targetAppSelect.required = false;
        });
    }

    const photoInput = document.getElementById('notification_photo');
    const previewWrapper = document.getElementById('image-preview-wrapper');
    const previewImg = document.getElementById('image-preview');
    
    if (photoInput) {
        photoInput.addEventListener('change', function() {
            var fileName = this.value.split("\\").pop();
            this.nextElementSibling.classList.add("selected");
            this.nextElementSibling.innerHTML = fileName || "Choose image file...";
            
            if (this.files && this.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    previewImg.src = e.target.result;
                    previewWrapper.style.display = 'block';
                }
                reader.readAsDataURL(this.files[0]);
            } else {
                previewWrapper.style.display = 'none';
            }
        });
    }

    const bulkForm = document.getElementById('bulk-notifications-form');
    if (bulkForm) {
        bulkForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const btn = document.getElementById('btn-bulk-send');
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Dispatched alerts...';
            
            const formData = new FormData(this);
            fetch('dashboard.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Dispatch Notification';
                
                if (data.success) {
                    document.getElementById('bulk-receipt-card').style.display = 'block';
                    document.getElementById('receipt-recipients').innerText = data.sent_count + ' user(s)';
                    if (data.image_url) {
                        document.getElementById('receipt-photo-attachment').innerHTML = `<a href="${data.image_url}" target="_blank">View Uploaded Image</a>`;
                    } else {
                        document.getElementById('receipt-photo-attachment').innerText = 'None';
                    }
                    alert(data.message);
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(err => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Dispatch Notification';
                alert('An error occurred during submission.');
                console.error(err);
            });
        });
    }

    // Auto-Sync Countdown Timer logic for failed_payouts page
    const timerEl = document.getElementById('sync-timer');
    const syncBtn = document.getElementById('btn-manual-sync');
    const logBody = document.getElementById('sync-log-body');
    const logContainer = document.getElementById('sync-log-container');
    const emptyLog = document.getElementById('sync-empty-log');
    
    if (timerEl && syncBtn) {
        let countdown = <?= isset($remaining) ? (int)$remaining : 120 ?>; // Calculated from server's last sync time
        let timerInterval = null;
        
        function escapeHtml(str) {
            if (!str) return '';
            return String(str)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#039;');
        }
        
        function updateTimerDisplay() {
            const minutes = Math.floor(countdown / 60);
            const seconds = countdown % 60;
            timerEl.innerText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
        
        function startTimer() {
            if (timerInterval) clearInterval(timerInterval);
            timerInterval = setInterval(() => {
                countdown--;
                if (countdown < 0) {
                    clearInterval(timerInterval);
                    triggerStatusSync();
                } else {
                    updateTimerDisplay();
                }
            }, 1000);
        }
        
        function triggerStatusSync() {
            clearInterval(timerInterval);
            syncBtn.disabled = true;
            syncBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Syncing...';
            timerEl.className = 'badge badge-secondary font-weight-bold px-3 py-2';
            timerEl.innerText = 'Syncing...';
            
            // Call the status checker endpoint
            fetch('../api/cron_check_payouts.php')
            .then(res => res.json())
            .then(data => {
                syncBtn.disabled = false;
                syncBtn.innerHTML = '<i class="fas fa-sync-alt mr-1"></i> Sync Now';
                timerEl.className = 'badge badge-warning font-weight-bold px-3 py-2';
                
                if (data.success) {
                    // Populate results table
                    logBody.innerHTML = '';
                    if (data.details && data.details.length > 0) {
                        data.details.forEach(item => {
                            let newStatusBadge = '';
                            let oldStatusBadge = `<span class="badge badge-secondary">${escapeHtml(item.old_status)}</span>`;
                            
                            if (item.new_status === 'SUCCESS') {
                                newStatusBadge = `<span class="badge badge-success">SUCCESS</span>`;
                            } else if (item.new_status === 'FAILED_HELD') {
                                newStatusBadge = `<span class="badge badge-danger">FAILED_HELD</span>`;
                            } else {
                                newStatusBadge = `<span class="badge badge-warning">${escapeHtml(item.new_status || 'PENDING')}</span>`;
                            }
                            
                            let remarks = item.error ? `<span class="text-danger">${escapeHtml(item.error)}</span>` : 
                                          (item.utr ? `UTR: ${escapeHtml(item.utr)}` : (item.message ? escapeHtml(item.message) : 'No updates'));
                            
                            logBody.innerHTML += `
                                <tr>
                                    <td><strong>${escapeHtml(item.order_id)}</strong></td>
                                    <td>${escapeHtml(item.sender_name)} (${escapeHtml(item.sender_app_id)})</td>
                                    <td><strong>${parseFloat(item.amount).toFixed(2)} INR</strong></td>
                                    <td>${oldStatusBadge}</td>
                                    <td>${newStatusBadge}</td>
                                    <td><span class="small font-weight-bold">${remarks}</span></td>
                                </tr>
                            `;
                        });
                        logContainer.style.display = 'block';
                        emptyLog.style.display = 'none';
                        
                        // If any transactions were updated, let's refresh the page after a short delay
                        if (data.updated > 0) {
                            setTimeout(() => {
                                alert(`${data.updated} transaction(s) status updated! Refreshing page...`);
                                window.location.reload();
                            }, 3000);
                        }
                    } else {
                        logBody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-2">No pending, processing or quarantined bank transfer transactions found to check.</td></tr>';
                        logContainer.style.display = 'block';
                        emptyLog.style.display = 'none';
                    }
                } else {
                    alert('Sync failed: ' + data.message);
                }
                
                // Restart timer
                countdown = 120;
                updateTimerDisplay();
                startTimer();
            })
            .catch(err => {
                console.error(err);
                syncBtn.disabled = false;
                syncBtn.innerHTML = '<i class="fas fa-sync-alt mr-1"></i> Sync Now';
                timerEl.className = 'badge badge-warning font-weight-bold px-3 py-2';
                timerEl.innerText = 'Error';
                
                // Restart timer anyway
                countdown = 120;
                updateTimerDisplay();
                startTimer();
            });
        }
        
        syncBtn.addEventListener('click', () => {
            triggerStatusSync();
        });
        
        // Start countdown on page load
        updateTimerDisplay();
        startTimer();
    }
</script>
</body>
</html>
