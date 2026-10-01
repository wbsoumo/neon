<?php
/**
 * Deccan Finance - Forgot Password API
 * Flow: 
 * 1. Action: request_otp (Identity: Email/Mobile) -> Generates & sends OTP, returns session_id
 * 2. Action: verify_otp (session_id, OTP) -> Marks session as verified
 * 3. Action: reset_password (session_id, new_password) -> Updates password
 */

header('Content-Type: application/json');
require_once 'db_helper.php';
require_once 'email_service.php';

// Accept request parameters
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$action = isset($data['action']) ? trim($data['action']) : '';

if (empty($action)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameter: action'
    ]);
    exit;
}

try {
    $pdo = get_db_connection();

    if ($action === 'request_otp') {
        $identity = isset($data['identity']) ? trim($data['identity']) : '';
        if (empty($identity)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Email address or Mobile number is required.']);
            exit;
        }

        // Check if matching user application exists
        $stmt = $pdo->prepare("SELECT app_id, email, full_name FROM applications WHERE email = :identity OR phone = :identity LIMIT 1");
        $stmt->execute([':identity' => $identity]);
        $user = $stmt->fetch();

        if (!$user) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Account with the provided Email or Mobile number not found.']);
            exit;
        }

        $appId = $user['app_id'];
        $email = $user['email'];
        $name = $user['full_name'];

        // Generate 6-digit numeric OTP and Session ID
        $otp = str_pad(mt_rand(100000, 999999), 6, '0', STR_PAD_LEFT);
        $sessionId = bin2hex(random_bytes(16));
        $expiresAt = date('Y-m-d H:i:s', time() + 900); // Valid for 15 minutes

        // Insert password reset session
        $stmtInsert = $pdo->prepare("INSERT INTO password_resets (app_id, email, otp, session_id, expires_at) VALUES (:app_id, :email, :otp, :session_id, :expires_at)");
        $stmtInsert->execute([
            ':app_id' => $appId,
            ':email' => $email,
            ':otp' => $otp,
            ':session_id' => $sessionId,
            ':expires_at' => $expiresAt
        ]);

        // Send OTP via Email using branded HTML Template
        $title = "Reset Password Verification Code";
        $htmlBody = '<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Password Reset OTP</title>
</head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb;padding:40px 0;">
<tr>
<td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 25px rgba(0,0,0,.08);">
<tr>
<td align="center" style="padding:35px 20px;background:linear-gradient(135deg,#0e1c36,#1a365d);">
<img src="https://deccanfinltd.world/assets/img/logo.png" width="80" style="display:block;margin-bottom:10px;">
<h1 style="margin:10px 0 5px;color:#fff;font-size:30px;">Deccan Finance</h1>
<p style="margin:0;color:#e7e7ff;font-size:15px;">Secure. Simple. Trusted.</p>
</td>
</tr>
<tr>
<td style="padding:40px;text-align:center;">
<h2 style="margin-top:0;color:#222;font-size:24px;">Verification Code</h2>
<p style="color:#555;font-size:16px;line-height:28px;text-align:left;">Hello <strong>' . htmlspecialchars($name) . '</strong>,</p>
<p style="color:#555;font-size:16px;line-height:28px;text-align:left;">We received a request to reset the password for your Deccan Finance account. Please use the following One-Time Password (OTP) to verify your request:</p>
<div style="background:#f0f4f8;border:2px dashed #ccd6dd;border-radius:12px;padding:20px;margin:30px auto;width:200px;font-size:32px;font-weight:bold;letter-spacing:4px;color:#1a365d;">
' . $otp . '
</div>
<p style="color:#ef4444;font-size:14px;font-weight:bold;">This OTP is valid for 15 minutes. Please do not share this code with anyone.</p>
<p style="color:#666;font-size:14px;margin-top:25px;text-align:left;">If you did not request a password reset, you can safely ignore this email.</p>
</td>
</tr>
<tr>
<td style="padding:30px;background:#fafafa;border-top:1px solid #eee;">
<table width="100%">
<tr>
<td align="center">
<p style="margin:0;font-size:13px;color:#888;">This is an automated notification. Please do not reply to this email.</p>
<p style="margin-top:15px;font-size:13px;color:#999;">Need help? <a href="mailto:support@deccanfinltd.world" style="color:#1a365d;text-decoration:none;">support@deccanfinltd.world</a></p>
<p style="margin-top:20px;font-size:12px;color:#bbb;">© 2026 Deccan Finance. All Rights Reserved.</p>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</body>
</html>';

        $mailResult = EmailService::sendMail($email, "Deccan Finance - " . $title, $htmlBody);

        if ($mailResult['success']) {
            echo json_encode([
                'success' => true,
                'message' => 'Verification code sent successfully to your registered email.',
                'session_id' => $sessionId
            ]);
        } else {
            // Roll back the session entry if sending failed
            $stmtDel = $pdo->prepare("DELETE FROM password_resets WHERE session_id = :session_id");
            $stmtDel->execute([':session_id' => $sessionId]);
            
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Failed to dispatch verification code email. Details: ' . $mailResult['message']
            ]);
        }

    } elseif ($action === 'verify_otp') {
        $sessionId = isset($data['session_id']) ? trim($data['session_id']) : '';
        $otp = isset($data['otp']) ? trim($data['otp']) : '';

        if (empty($sessionId) || empty($otp)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Session ID and OTP are required.']);
            exit;
        }

        // Verify OTP matches and is not expired
        $stmt = $pdo->prepare("SELECT * FROM password_resets WHERE session_id = :session_id AND otp = :otp AND is_verified = 0 AND expires_at > NOW() LIMIT 1");
        $stmt->execute([
            ':session_id' => $sessionId,
            ':otp' => $otp
        ]);
        $reset = $stmt->fetch();

        if (!$reset) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP.']);
            exit;
        }

        // Mark reset session as verified
        $stmtUpdate = $pdo->prepare("UPDATE password_resets SET is_verified = 1 WHERE session_id = :session_id");
        $stmtUpdate->execute([':session_id' => $sessionId]);

        echo json_encode([
            'success' => true,
            'message' => 'OTP verified successfully. You may now set your new password.',
            'session_id' => $sessionId
        ]);

    } elseif ($action === 'reset_password') {
        $sessionId = isset($data['session_id']) ? trim($data['session_id']) : '';
        $newPassword = isset($data['new_password']) ? trim($data['new_password']) : '';

        if (empty($sessionId) || empty($newPassword)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Session ID and new password are required.']);
            exit;
        }

        if (strlen($newPassword) < 6) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters long.']);
            exit;
        }

        // Check if verified reset session is valid and not expired
        $stmt = $pdo->prepare("SELECT * FROM password_resets WHERE session_id = :session_id AND is_verified = 1 AND expires_at > NOW() LIMIT 1");
        $stmt->execute([':session_id' => $sessionId]);
        $reset = $stmt->fetch();

        if (!$reset) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Invalid or expired password reset session.']);
            exit;
        }

        $appId = $reset['app_id'];

        // Update the password in plaintext format as requested
        $stmtPass = $pdo->prepare("UPDATE applications SET password_hash = :new_password WHERE app_id = :app_id");
        $stmtPass->execute([
            ':new_password' => $newPassword,
            ':app_id' => $appId
        ]);

        // Delete reset session so it cannot be reused
        $stmtDelete = $pdo->prepare("DELETE FROM password_resets WHERE session_id = :session_id");
        $stmtDelete->execute([':session_id' => $sessionId]);

        echo json_encode([
            'success' => true,
            'message' => 'Password updated successfully. You can now sign in.'
        ]);

    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid action. Must be request_otp, verify_otp, or reset_password.']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An internal server error occurred: ' . $e->getMessage()
    ]);
}
