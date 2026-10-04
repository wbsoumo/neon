<?php
/**
 * Neon Bank - Direct Test Email Dispatcher
 */
header('Content-Type: application/json');

require_once __DIR__ . '/db_helper.php';
require_once __DIR__ . '/email_service.php';

$to = 'globaltrade1072@gmail.com';

$title = "Neon Bank Email System Test";
$customerName = "Alexander Weber";
$badgeText = "✓ SYSTEM VERIFICATION SUCCESSFUL";
$badgeColor = "#00F2FE";
$description = "This is an automated test email confirming that <strong>Neon Bank</strong> email service is active and correctly configured with <strong>no-reply@neonfinswiss.world</strong> credentials.";

$rows = '';
$rows .= EmailService::renderTableRow('Test Recipient', htmlspecialchars($to), '#00F2FE', true);
$rows .= EmailService::renderTableRow('Sender Email', 'no-reply@neonfinswiss.world');
$rows .= EmailService::renderTableRow('Dispatch Time', date('d M Y, h:i:s A'));
$rows .= EmailService::renderTableRow('Security Status', '<span style="color:#10B981;font-weight:700;">TLS/SSL AUTHENTICATED</span>', '#10B981', true, true);

$statusBox = '
<div style="background-color:#0A1B2E;border-left:4px solid #00F2FE;border-radius:8px;padding:16px;">
    <strong style="color:#00F2FE;font-size:14px;">⚡ Email Notification Active</strong>
    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">Automated HTML notifications for onboarding, approvals, payouts, P2P transfers, and password resets are online.</p>
</div>';

$htmlBody = EmailService::renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $rows, $statusBox);

$res = EmailService::sendMail($to, "Neon Bank - Test Email Verification", $htmlBody);

echo json_encode([
    'success' => $res['success'],
    'message' => $res['message'],
    'recipient' => $to,
    'sender' => 'no-reply@neonfinswiss.world'
]);
