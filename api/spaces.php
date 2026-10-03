<?php
/**
 * Neon Finance - Spaces API
 * Handle GET, CREATE, UPDATE, DELETE, TRANSFER, and TRANSACTIONS for Spaces
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$action = $data['action'] ?? $_GET['action'] ?? 'list';

// Resolve Session / App ID
$passedSessionId = $data['session_id'] ?? $_GET['session_id'] ?? '';
$headers = function_exists('getallheaders') ? getallheaders() : [];
if (empty($passedSessionId)) {
    if (!empty($headers['X-Session-ID'])) $passedSessionId = trim($headers['X-Session-ID']);
    elseif (!empty($headers['x-session-id'])) $passedSessionId = trim($headers['x-session-id']);
    elseif (!empty($_SERVER['HTTP_X_SESSION_ID'])) $passedSessionId = trim($_SERVER['HTTP_X_SESSION_ID']);
}

if (!empty($passedSessionId)) {
    session_id($passedSessionId);
}
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$appId = $data['app_id'] ?? $_GET['app_id'] ?? ($_SESSION['customer_app_id'] ?? '');

if (empty($appId)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized user session.']);
    exit;
}

$pdo = get_db_connection();

switch ($action) {
    case 'list':
        // Fetch spaces for user
        $stmt = $pdo->prepare("SELECT * FROM user_spaces WHERE app_id = :app_id ORDER BY created_at DESC");
        $stmt->execute([':app_id' => $appId]);
        $spaces = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Also fetch main balance in CHF and INR
        $userStmt = $pdo->prepare("SELECT balance FROM applications WHERE app_id = :app_id");
        $userStmt->execute([':app_id' => $appId]);
        $user = $userStmt->fetch(PDO::FETCH_ASSOC);
        $balanceInr = (float)($user['balance'] ?? 0);
        $balanceChf = $balanceInr * 0.0104; // 1 INR = ~0.0104 CHF

        echo json_encode([
            'success' => true,
            'spaces' => $spaces,
            'main_balance_chf' => round($balanceChf, 2),
            'main_balance_inr' => round($balanceInr, 2)
        ]);
        break;

    case 'create':
        $name = trim($data['name'] ?? '');
        $category = trim($data['category'] ?? 'Custom Space');
        $iconKey = trim($data['icon_key'] ?? 'custom');
        $currency = trim($data['currency'] ?? 'CHF');
        $targetAmount = !empty($data['target_amount']) ? (float)$data['target_amount'] : null;
        $targetDate = !empty($data['target_date']) ? trim($data['target_date']) : null;
        $initialAmount = !empty($data['initial_amount']) ? (float)$data['initial_amount'] : 0.0;
        $colorHex = !empty($data['color_hex']) ? trim($data['color_hex']) : '#E91E63';
        $allocationType = !empty($data['allocation_type']) ? trim($data['allocation_type']) : 'NONE';
        $allocationValue = !empty($data['allocation_value']) ? (float)$data['allocation_value'] : 0.0;

        if (empty($name)) {
            echo json_encode(['success' => false, 'message' => 'Space name is required.']);
            exit;
        }

        $spaceId = 'SPC_' . strtoupper(bin2hex(random_bytes(6)));

        // If initial amount > 0, deduct from main account (assuming main account is INR, convert if CHF)
        if ($initialAmount > 0) {
            $userStmt = $pdo->prepare("SELECT balance FROM applications WHERE app_id = :app_id FOR UPDATE");
            $userStmt->execute([':app_id' => $appId]);
            $user = $userStmt->fetch();
            $currentMainInr = (float)($user['balance'] ?? 0);

            // Amount in INR to deduct
            $deductInr = ($currency === 'CHF') ? ($initialAmount * 96.15) : $initialAmount;

            if ($currentMainInr < $deductInr) {
                echo json_encode(['success' => false, 'message' => 'Insufficient Main Account balance for initial deposit.']);
                exit;
            }

            // Deduct
            $pdo->prepare("UPDATE applications SET balance = balance - :deduct WHERE app_id = :app_id")
                ->execute([':deduct' => $deductInr, ':app_id' => $appId]);
        }

        $stmt = $pdo->prepare("INSERT INTO user_spaces (space_id, app_id, name, category, icon_key, currency, balance, target_amount, target_date, color_hex, allocation_type, allocation_value) 
            VALUES (:space_id, :app_id, :name, :category, :icon_key, :currency, :balance, :target_amount, :target_date, :color_hex, :allocation_type, :allocation_value)");
        $stmt->execute([
            ':space_id' => $spaceId,
            ':app_id' => $appId,
            ':name' => $name,
            ':category' => $category,
            ':icon_key' => $iconKey,
            ':currency' => $currency,
            ':balance' => $initialAmount,
            ':target_amount' => $targetAmount,
            ':target_date' => $targetDate,
            ':color_hex' => $colorHex,
            ':allocation_type' => $allocationType,
            ':allocation_value' => $allocationValue,
        ]);

        if ($initialAmount > 0) {
            $txId = 'SPCTX_' . strtoupper(bin2hex(random_bytes(6)));
            $pdo->prepare("INSERT INTO space_transactions (transaction_id, space_id, app_id, type, amount, currency, source_dest, status) 
                VALUES (:tx_id, :space_id, :app_id, 'ADD', :amount, :currency, 'Main Account Deposit', 'SUCCESS')")
                ->execute([
                    ':tx_id' => $txId,
                    ':space_id' => $spaceId,
                    ':app_id' => $appId,
                    ':amount' => $initialAmount,
                    ':currency' => $currency
                ]);
        }

        echo json_encode(['success' => true, 'message' => 'Space created successfully!', 'space_id' => $spaceId]);
        break;

    case 'update':
        $spaceId = trim($data['space_id'] ?? '');
        $name = trim($data['name'] ?? '');
        $targetAmount = !empty($data['target_amount']) ? (float)$data['target_amount'] : null;
        $targetDate = !empty($data['target_date']) ? trim($data['target_date']) : null;
        $allocationType = !empty($data['allocation_type']) ? trim($data['allocation_type']) : 'NONE';
        $allocationValue = !empty($data['allocation_value']) ? (float)$data['allocation_value'] : 0.0;

        if (empty($spaceId) || empty($name)) {
            echo json_encode(['success' => false, 'message' => 'Space ID and Name are required.']);
            exit;
        }

        $stmt = $pdo->prepare("UPDATE user_spaces SET name = :name, target_amount = :target_amount, target_date = :target_date, allocation_type = :allocation_type, allocation_value = :allocation_value WHERE space_id = :space_id AND app_id = :app_id");
        $stmt->execute([
            ':name' => $name,
            ':target_amount' => $targetAmount,
            ':target_date' => $targetDate,
            ':allocation_type' => $allocationType,
            ':allocation_value' => $allocationValue,
            ':space_id' => $spaceId,
            ':app_id' => $appId
        ]);

        echo json_encode(['success' => true, 'message' => 'Space updated successfully.']);
        break;

    case 'delete':
        $spaceId = trim($data['space_id'] ?? '');
        if (empty($spaceId)) {
            echo json_encode(['success' => false, 'message' => 'Space ID required.']);
            exit;
        }

        // Return remaining balance to main account
        $spcStmt = $pdo->prepare("SELECT balance, currency FROM user_spaces WHERE space_id = :space_id AND app_id = :app_id");
        $spcStmt->execute([':space_id' => $spaceId, ':app_id' => $appId]);
        $spc = $spcStmt->fetch();

        if ($spc && (float)$spc['balance'] > 0) {
            $refundBal = (float)$spc['balance'];
            $refundInr = ($spc['currency'] === 'CHF') ? ($refundBal * 96.15) : $refundBal;

            $pdo->prepare("UPDATE applications SET balance = balance + :refund WHERE app_id = :app_id")
                ->execute([':refund' => $refundInr, ':app_id' => $appId]);
        }

        $pdo->prepare("DELETE FROM user_spaces WHERE space_id = :space_id AND app_id = :app_id")->execute([':space_id' => $spaceId, ':app_id' => $appId]);
        $pdo->prepare("DELETE FROM space_transactions WHERE space_id = :space_id AND app_id = :app_id")->execute([':space_id' => $spaceId, ':app_id' => $appId]);

        echo json_encode(['success' => true, 'message' => 'Space deleted and funds returned to Main Account.']);
        break;

    case 'transfer':
        $spaceId = trim($data['space_id'] ?? '');
        $type = strtoupper(trim($data['type'] ?? 'ADD')); // ADD or WITHDRAW
        $amount = (float)($data['amount'] ?? 0);

        if (empty($spaceId) || $amount <= 0) {
            echo json_encode(['success' => false, 'message' => 'Valid Space ID and positive amount required.']);
            exit;
        }

        // Fetch Space
        $spcStmt = $pdo->prepare("SELECT * FROM user_spaces WHERE space_id = :space_id AND app_id = :app_id FOR UPDATE");
        $spcStmt->execute([':space_id' => $spaceId, ':app_id' => $appId]);
        $spc = $spcStmt->fetch();

        if (!$spc) {
            echo json_encode(['success' => false, 'message' => 'Space not found.']);
            exit;
        }

        // Fetch Main User Account
        $userStmt = $pdo->prepare("SELECT balance FROM applications WHERE app_id = :app_id FOR UPDATE");
        $userStmt->execute([':app_id' => $appId]);
        $user = $userStmt->fetch();
        $mainBalInr = (float)($user['balance'] ?? 0);

        $currency = $spc['currency'];
        $amountInr = ($currency === 'CHF') ? ($amount * 96.15) : $amount;

        if ($type === 'ADD') {
            if ($mainBalInr < $amountInr) {
                echo json_encode(['success' => false, 'message' => 'Insufficient Main Account balance.']);
                exit;
            }

            // Deduct main account, credit space
            $pdo->prepare("UPDATE applications SET balance = balance - :amount_inr WHERE app_id = :app_id")
                ->execute([':amount_inr' => $amountInr, ':app_id' => $appId]);

            $pdo->prepare("UPDATE user_spaces SET balance = balance + :amount WHERE space_id = :space_id")
                ->execute([':amount' => $amount, ':space_id' => $spaceId]);

            $srcDest = 'Main Account Transfer';
        } else {
            // WITHDRAW
            $spaceBal = (float)$spc['balance'];
            if ($spaceBal < $amount) {
                echo json_encode(['success' => false, 'message' => 'Insufficient funds in this Space.']);
                exit;
            }

            // Deduct space, credit main account
            $pdo->prepare("UPDATE user_spaces SET balance = balance - :amount WHERE space_id = :space_id")
                ->execute([':amount' => $amount, ':space_id' => $spaceId]);

            $pdo->prepare("UPDATE applications SET balance = balance + :amount_inr WHERE app_id = :app_id")
                ->execute([':amount_inr' => $amountInr, ':app_id' => $appId]);

            $srcDest = 'Main Account Withdrawal';
        }

        // Record Space Transaction
        $txId = 'SPCTX_' . strtoupper(bin2hex(random_bytes(6)));
        $pdo->prepare("INSERT INTO space_transactions (transaction_id, space_id, app_id, type, amount, currency, source_dest, status) 
            VALUES (:tx_id, :space_id, :app_id, :type, :amount, :currency, :source_dest, 'SUCCESS')")
            ->execute([
                ':tx_id' => $txId,
                ':space_id' => $spaceId,
                ':app_id' => $appId,
                ':type' => $type,
                ':amount' => $amount,
                ':currency' => $currency,
                ':source_dest' => $srcDest,
            ]);

        // Get updated balances
        $updatedUser = $pdo->prepare("SELECT balance FROM applications WHERE app_id = :app_id");
        $updatedUser->execute([':app_id' => $appId]);
        $newMainInr = (float)($updatedUser->fetchColumn() ?? 0);

        $updatedSpc = $pdo->prepare("SELECT balance FROM user_spaces WHERE space_id = :space_id");
        $updatedSpc->execute([':space_id' => $spaceId]);
        $newSpcBal = (float)($updatedSpc->fetchColumn() ?? 0);

        echo json_encode([
            'success' => true,
            'message' => ($type === 'ADD' ? 'Funds added to Space!' : 'Funds withdrawn to Main Account!'),
            'new_space_balance' => $newSpcBal,
            'new_main_balance_chf' => round($newMainInr * 0.0104, 2),
            'new_main_balance_inr' => round($newMainInr, 2)
        ]);
        break;

    case 'transactions':
        $spaceId = trim($data['space_id'] ?? $_GET['space_id'] ?? '');
        if (empty($spaceId)) {
            echo json_encode(['success' => false, 'message' => 'Space ID required.']);
            exit;
        }

        $stmt = $pdo->prepare("SELECT * FROM space_transactions WHERE space_id = :space_id AND app_id = :app_id ORDER BY created_at DESC LIMIT 50");
        $stmt->execute([':space_id' => $spaceId, ':app_id' => $appId]);
        $txs = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(['success' => true, 'transactions' => $txs]);
        break;

    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action.']);
        break;
}
