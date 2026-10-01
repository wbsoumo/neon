<?php
/**
 * Deccan Finance - Admin Toggle User Transactions API
 */
header('Content-Type: application/json');
require_once 'db_helper.php';

session_start();

// Guard admin access
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized. Admin session required.']);
    exit;
}

// Check POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Only POST requests are allowed.']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$appId = trim($data['app_id'] ?? '');
$status = trim($data['status'] ?? 'on'); // 'on' or 'off'
$message = trim($data['message'] ?? '');
$remarks = trim($data['remarks'] ?? '');

$emailTemplate = isset($data['email_template']) ? trim($data['email_template']) : null;

if (empty($appId)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Application ID is required.']);
    exit;
}

$txEnabled = ($status === 'on') ? 1 : 0;
if ($txEnabled === 0 && empty($message)) {
    $message = 'Transactions on your account have been suspended.';
}

try {
    $pdo = get_db_connection();
    
    // Check if user exists
    $user = get_application_by_id($appId);
    if (!$user) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found.']);
        exit;
    }
    
    $account = get_account_by_app_id($appId);
    $accountNumber = $account ? $account['account_number'] : '';

    // Update applications table
    $stmt = $pdo->prepare("UPDATE applications SET tx_enabled = :tx_enabled, tx_disabled_message = :message, tx_failed_email_template = :email_template WHERE app_id = :app_id");
    $stmt->execute([
        ':tx_enabled' => $txEnabled,
        ':message' => $txEnabled ? null : $message,
        ':email_template' => $emailTemplate,
        ':app_id' => $appId
    ]);

    // Log admin activity
    $adminUsername = $_SESSION['admin_user'] ?? 'Administrator';
    log_admin_activity($adminUsername, 'TOGGLE_USER_TRANSACTIONS', "Set transaction status to " . strtoupper($status) . " for user $appId. Message: $message");

    echo json_encode([
        'success' => true,
        'message' => 'Transaction status updated successfully.'
    ]);
} catch (\Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
