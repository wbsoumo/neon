<?php
/**
 * Deccan Finance - Test AWS SES SMTP Email Delivery
 * Scope: Public/Authenticated/Admin
 */

header('Content-Type: application/json');
require_once __DIR__ . '/email_service.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

// Get parameters
$to = isset($_GET['to']) ? trim($_GET['to']) : (isset($_POST['to']) ? trim($_POST['to']) : '');
$subject = isset($_GET['subject']) ? trim($_GET['subject']) : (isset($_POST['subject']) ? trim($_POST['subject']) : '');
$body = isset($_GET['body']) ? trim($_GET['body']) : (isset($_POST['body']) ? trim($_POST['body']) : '');
$debugMode = (isset($_GET['debug']) && $_GET['debug'] == '1') || (isset($_POST['debug']) && $_POST['debug'] == '1');

if (empty($to)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Recipient email address (to) is required. Usage: /api/test_email.php?to=test@example.com&debug=1'
    ]);
    exit;
}

if (!filter_var($to, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid recipient email address format.'
    ]);
    exit;
}

$mail = new PHPMailer(true);
$mail->CharSet = 'UTF-8';
$debugBuffer = [];

try {
    // Enable SMTP Debugging if requested
    if ($debugMode) {
        $mail->SMTPDebug = SMTP::DEBUG_SERVER;
        $mail->Debugoutput = function($str, $level) use (&$debugBuffer) {
            $debugBuffer[] = trim($str);
        };
    } else {
        $mail->SMTPDebug = SMTP::DEBUG_OFF;
    }

    // SMTP Server Settings from Database Settings
    $settings = EmailService::get_settings();
    if (!$settings) {
        throw new Exception('SMTP settings not found in database.');
    }

    $mail->isSMTP();
    $mail->Host       = $settings['smtp_host'];
    $mail->SMTPAuth   = (bool)$settings['smtp_auth'];
    $mail->Username   = $settings['smtp_user'];
    $mail->Password   = $settings['smtp_pass'];
    
    $encryption = strtoupper($settings['smtp_encryption']);
    if ($encryption === 'TLS') {
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    } elseif ($encryption === 'SSL') {
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
    } else {
        $mail->SMTPSecure = '';
    }
    $mail->Port       = (int)$settings['smtp_port'];

    // Sender / Recipients
    $mail->setFrom($settings['from_email'], $settings['from_name']);
    $mail->addAddress($to);

    // Content
    $mail->isHTML(true);
    $mail->Subject = $subject ?: 'Deccan Finance Test Email';
    $mail->Body    = $body ?: '<h3>Deccan Finance - Security Test</h3><p>This is a secure test email sent via AWS SES SMTP on TLS Port 587.</p>';
    $mail->AltBody = strip_tags($mail->Body);

    // Send
    $mail->send();

    http_response_code(200);
    $response = [
        'success' => true,
        'message' => 'Email sent successfully via SMTP settings.',
        'from' => $settings['from_email'],
        'to' => $to,
        'config' => [
            'host' => $settings['smtp_host'],
            'port' => $settings['smtp_port'],
            'secure' => $settings['smtp_encryption'],
            'username_configured' => !empty($settings['smtp_user'])
        ]
    ];
    if ($debugMode) {
        $response['smtp_debug'] = $debugBuffer;
    }
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => 'Email delivery failed: ' . $mail->ErrorInfo,
        'error_detail' => $e->getMessage(),
        'config' => [
            'host' => isset($settings) ? $settings['smtp_host'] : 'Unknown',
            'port' => isset($settings) ? $settings['smtp_port'] : 'Unknown',
            'secure' => isset($settings) ? $settings['smtp_encryption'] : 'Unknown'
        ]
    ];
    if ($debugMode) {
        $response['smtp_debug'] = $debugBuffer;
    }
    echo json_encode($response);
}
