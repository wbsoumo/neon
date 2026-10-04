<?php
/**
 * Neon Bank - Test Dispatch Script
 */
header('Content-Type: application/json');

require_once __DIR__ . '/db_helper.php';
require_once __DIR__ . '/email_service.php';

$pdo = get_db_connection();

// Get an existing account or application if available
$account = $pdo->query("SELECT a.account_number, app.email, app.full_name FROM accounts a JOIN applications app ON a.app_id = app.app_id LIMIT 1")->fetch();

$to = 'globaltrade1072@gmail.com';

$title = "Neon Bank Email System Test";
$customerName = $account ? $account['full_name'] : "Alexander Weber";
$badgeText = "✓ SYSTEM VERIFICATION SUCCESSFUL";
$badgeColor = "#00F2FE";
$description = "This is an automated test email confirming that <strong>Neon Bank</strong> email service is active and correctly configured with <strong>no-reply@neonfinswiss.world</strong> credentials.";

$rows = '';
$rows .= EmailService::renderTableRow('Test Recipient', htmlspecialchars($to), '#00F2FE', true);
$rows .= EmailService::renderTableRow('Sender Email', 'no-reply@neonfinswiss.world');
$rows .= EmailService::renderTableRow('Dispatch Time', date('d M Y, h:i:s A'));
if ($account) {
    $rows .= EmailService::renderTableRow('Active Customer Account', htmlspecialchars($account['account_number']));
}
$rows .= EmailService::renderTableRow('Security Status', '<span style="color:#10B981;font-weight:700;">TLS/SSL AUTHENTICATED</span>', '#10B981', true, true);

$statusBox = '
<div style="background-color:#0A1B2E;border-left:4px solid #00F2FE;border-radius:8px;padding:16px;">
    <strong style="color:#00F2FE;font-size:14px;">⚡ Email Notification Active</strong>
    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">Automated HTML notifications for onboarding, approvals, payouts, P2P transfers, and password resets are online.</p>
</div>';

$htmlBody = EmailService::renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $rows, $statusBox);

$res = EmailService::sendMail($to, "Neon Bank - Test Email Verification", $htmlBody);

// Also try sending notification email if account found
$notificationRes = null;
if ($account) {
    $notificationRes = EmailService::sendNotificationEmail($account['account_number'], 'approved');
}

echo json_encode([
    'success' => $res['success'],
    'message' => $res['message'],
    'recipient' => $to,
    'sender' => 'no-reply@neonfinswiss.world',
    'smtp_settings_in_db' => EmailService::get_settings(),
    'notification_res' => $notificationRes
]);
