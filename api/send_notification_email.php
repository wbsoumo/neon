<?php
/**
 * Neon Bank - Automated Email Notification API
 * Trigger email notifications externally or internally using account number and notification type.
 */

header('Content-Type: application/json');
require_once __DIR__ . '/db_helper.php';
require_once __DIR__ . '/email_service.php';

// Accept request body
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$toEmail = isset($data['to']) ? trim($data['to']) : (isset($_GET['to']) ? trim($_GET['to']) : '');
$accountNumber = isset($data['account_number']) ? trim($data['account_number']) : '';
$type = isset($data['type']) ? strtolower(trim($data['type'])) : 'approved';

if (!empty($toEmail)) {
    // Send direct test email
    $title = "Neon Bank Email Service System Test";
    $customerName = "Alexander Weber";
    $badgeText = "✓ SYSTEM VERIFICATION SUCCESSFUL";
    $badgeColor = "#00F2FE";
    $description = "This is an automated test notification confirming that <strong>Neon Bank</strong> email service is active and correctly configured with <strong>no-reply@neonfinswiss.world</strong> credentials.";

    $rows = '';
    $rows .= EmailService::renderTableRow('Test Recipient', htmlspecialchars($toEmail), '#00F2FE', true);
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
    $res = EmailService::sendMail($toEmail, "Neon Bank - System Verification Test", $htmlBody);

    echo json_encode([
        'success' => $res['success'],
        'message' => $res['message'],
        'recipient' => $toEmail
    ]);
    exit;
}

if (empty($accountNumber)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameter: account_number or to'
    ]);
    exit;
}

$amount = isset($data['amount']) ? (float)$data['amount'] : null;
$reference = isset($data['reference']) ? trim($data['reference']) : null;
$remarks = isset($data['remarks']) ? trim($data['remarks']) : null;

$res = EmailService::sendNotificationEmail($accountNumber, $type, $amount, $reference, $remarks);

if ($res['success']) {
    echo json_encode([
        'success' => true,
        'message' => 'Notification email sent successfully.'
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to send email. Details: ' . $res['message']
    ]);
}
