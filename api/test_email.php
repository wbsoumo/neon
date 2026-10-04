<?php
/**
 * Neon Bank - Test Email Delivery Endpoint
 * Sends a test email to the specified address or default target.
 */

header('Content-Type: application/json');

// Force version marker
header('X-Neon-Email-Version: 2.0');

require_once __DIR__ . '/db_helper.php';
require_once __DIR__ . '/email_service.php';

$to = !empty($_REQUEST['to']) ? trim($_REQUEST['to']) : 'globaltrade1072@gmail.com';

if (empty($to) || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Valid recipient email address (to) is required.'
    ]);
    exit;
}

$title = "Neon Bank Email Service System Test";
$customerName = "Alexander Weber";
$badgeText = "✓ SYSTEM VERIFICATION SUCCESSFUL";
$badgeColor = "#00F2FE";
$description = "This is an automated test notification confirming that <strong>Neon Bank</strong> email service is active and correctly configured with <strong>no-reply@neonfinswiss.world</strong> credentials.";

$rows = '';
$rows .= EmailService::renderTableRow('Test Recipient', htmlspecialchars($to), '#00F2FE', true);
$rows .= EmailService::renderTableRow('Sender Address', 'no-reply@neonfinswiss.world');
$rows .= EmailService::renderTableRow('SMTP Gateway Host', 'neonfinswiss.world:465 (SSL)');
$rows .= EmailService::renderTableRow('Dispatch Timestamp', date('d M Y, h:i:s A'));
$rows .= EmailService::renderTableRow('Security Status', '<span style="color:#10B981;font-weight:700;">TLS/SSL AUTHENTICATED</span>', '#10B981', true, true);

$statusBox = '
<div style="background-color:#0A1B2E;border-left:4px solid #00F2FE;border-radius:8px;padding:16px;">
    <strong style="color:#00F2FE;font-size:14px;">⚡ System Status Normal</strong>
    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">Automated transactional emails for onboarding submissions, application approvals, payouts, P2P transfers, and password resets are active.</p>
</div>';

$htmlBody = EmailService::renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $rows, $statusBox);

$result = EmailService::sendMail($to, "Neon Bank - System Verification Test", $htmlBody);

if ($result['success']) {
    echo json_encode([
        'success' => true,
        'message' => 'Test email dispatched successfully to ' . $to,
        'details' => $result
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Email dispatch result: ' . $result['message'],
        'details' => $result
    ]);
}
