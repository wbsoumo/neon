<?php
/**
 * Neon Bank - Reusable Email Service
 * Premium Swiss Banking HTML Email Templates & Dynamic SMTP Engine
 */

require_once __DIR__ . '/db_helper.php';

$autoload_file = dirname(__DIR__) . '/vendor/autoload.php';
if (file_exists($autoload_file)) {
    require_once $autoload_file;
}

class EmailService {
    // Encryption settings
    private static $cipher = 'AES-256-CBC';
    private static $key = 'DeccanSecureKey2026!';

    /**
     * Encrypts the SMTP password for database storage.
     */
    public static function encrypt_password($password) {
        $iv = substr(hash('sha256', self::$key), 0, 16);
        return base64_encode(openssl_encrypt($password, self::$cipher, self::$key, 0, $iv));
    }

    /**
     * Decrypts the SMTP password.
     */
    public static function decrypt_password($encrypted) {
        $iv = substr(hash('sha256', self::$key), 0, 16);
        return openssl_decrypt(base64_decode($encrypted), self::$cipher, self::$key, 0, $iv);
    }

    /**
     * Gets SMTP Settings from the database and decrypts the password.
     */
    public static function get_settings() {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->query("SELECT * FROM smtp_settings ORDER BY id DESC LIMIT 1");
            $settings = $stmt->fetch();
            if ($settings && !empty($settings['smtp_pass_encrypted'])) {
                $settings['smtp_pass'] = self::decrypt_password($settings['smtp_pass_encrypted']);
            } else {
                $settings = [
                    'smtp_host' => 'neonfinswiss.world',
                    'smtp_port' => 465,
                    'smtp_encryption' => 'SSL',
                    'smtp_user' => 'no-reply@neonfinswiss.world',
                    'smtp_pass' => 'Soumojit1234@',
                    'from_email' => 'no-reply@neonfinswiss.world',
                    'from_name' => 'Neon Bank',
                    'reply_to' => 'no-reply@neonfinswiss.world',
                    'smtp_auth' => 1
                ];
            }
            return $settings;
        } catch (\Throwable $e) {
            return [
                'smtp_host' => 'neonfinswiss.world',
                'smtp_port' => 465,
                'smtp_encryption' => 'SSL',
                'smtp_user' => 'no-reply@neonfinswiss.world',
                'smtp_pass' => 'Soumojit1234@',
                'from_email' => 'no-reply@neonfinswiss.world',
                'from_name' => 'Neon Bank',
                'reply_to' => 'no-reply@neonfinswiss.world',
                'smtp_auth' => 1
            ];
        }
    }

    /**
     * Sends an email using SMTP (via PHPMailer or PHP mail fallback).
     */
    public static function sendMail($to, $subject, $htmlBody, $attachments = [], $cc = [], $bcc = []) {
        $settings = self::get_settings();
        $fromEmail = !empty($settings['from_email']) ? $settings['from_email'] : 'no-reply@neonfinswiss.world';
        $fromName = !empty($settings['from_name']) ? $settings['from_name'] : 'Neon Bank';
        $replyTo = !empty($settings['reply_to']) ? $settings['reply_to'] : 'no-reply@neonfinswiss.world';

        // 1. Direct Socket SSL SMTP Dispatcher (cPanel Port 465 / 587 SSL Authenticated)
        $socketRes = self::sendSocketSmtp($to, $subject, $htmlBody, $settings);
        if ($socketRes['success']) {
            self::log_email($to, $cc, $bcc, $subject, $htmlBody, $fromEmail, 'SUCCESS');
            return $socketRes;
        }

        // 2. Native PHP mail() fallback with proper envelope headers for cPanel exim
        try {
            $toStr = is_array($to) ? implode(', ', $to) : $to;
            $headers  = "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
            $headers .= "From: " . $fromName . " <" . $fromEmail . ">\r\n";
            $headers .= "Reply-To: " . $replyTo . "\r\n";
            $headers .= "X-Mailer: NeonBank-Mailer/2.0\r\n";

            // Pass -f parameter to set proper envelope sender
            $sent = @mail($toStr, $subject, $htmlBody, $headers, "-f" . $fromEmail);
            if ($sent) {
                self::log_email($to, $cc, $bcc, $subject, $htmlBody, $fromEmail, 'SUCCESS');
                return [
                    'success' => true,
                    'engine' => 'mail() (-f ' . $fromEmail . ')',
                    'socket_error' => $socketRes['message'] ?? 'Socket SMTP blocked by firewall',
                    'message' => 'Email accepted by cPanel local mail agent (-f envelope sender).'
                ];
            } else {
                $err = "Native mail() function returned false.";
                self::log_email($to, $cc, $bcc, $subject, $htmlBody, $fromEmail, 'FAILED', $err);
                return [
                    'success' => false,
                    'message' => 'Email sending failed: ' . $err
                ];
            }
        } catch (\Throwable $fallbackEx) {
            $err = $fallbackEx->getMessage();
            self::log_email($to, $cc, $bcc, $subject, $htmlBody, $fromEmail, 'FAILED', $err);
            return [
                'success' => false,
                'message' => 'Email sending failed: ' . $err
            ];
        }
    }

    /**
     * Direct Socket SMTP Dispatcher for SSL/TLS
     */
    private static function sendSocketSmtp($to, $subject, $htmlBody, $settings) {
        $hosts = [$settings['smtp_host'] ?? 'neonfinswiss.world', '127.0.0.1', 'localhost'];
        $user = $settings['smtp_user'] ?? 'no-reply@neonfinswiss.world';
        $pass = $settings['smtp_pass'] ?? 'Soumojit1234@';
        $from = $settings['from_email'] ?? 'no-reply@neonfinswiss.world';
        $fromName = $settings['from_name'] ?? 'Neon Bank';
        $replyTo = $settings['reply_to'] ?? $from;
        $targetTo = is_array($to) ? $to[0] : $to;

        $attempts = [
            ['host' => $hosts[0], 'port' => 465, 'scheme' => 'ssl://'],
            ['host' => $hosts[0], 'port' => 587, 'scheme' => ''],
            ['host' => '127.0.0.1', 'port' => 465, 'scheme' => 'ssl://'],
            ['host' => '127.0.0.1', 'port' => 587, 'scheme' => ''],
            ['host' => '127.0.0.1', 'port' => 25, 'scheme' => '']
        ];

        $lastErr = '';

        foreach ($attempts as $attempt) {
            $remote = $attempt['scheme'] . $attempt['host'] . ':' . $attempt['port'];
            $context = stream_context_create([
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                ]
            ]);

            $socket = @stream_socket_client($remote, $errno, $errstr, 2, STREAM_CLIENT_CONNECT, $context);
            if (!$socket) {
                $lastErr = "Connection to $remote failed: $errstr ($errno)";
                continue;
            }

            stream_set_timeout($socket, 2);

            $read = function($sock) {
                $response = '';
                while ($line = fgets($sock, 512)) {
                    $response .= $line;
                    if (substr($line, 3, 1) === ' ') break;
                }
                return $response;
            };

            $write = function($sock, $cmd) {
                fputs($sock, $cmd . "\r\n");
            };

            $welcome = $read($socket);
            if (substr($welcome, 0, 3) !== '220') {
                fclose($socket);
                $lastErr = "Welcome rejected on $remote: $welcome";
                continue;
            }

            $write($socket, "EHLO neonfinswiss.world");
            $ehlo = $read($socket);

            if ($attempt['port'] === 587) {
                $write($socket, "STARTTLS");
                $starttls = $read($socket);
                if (substr($starttls, 0, 3) === '220') {
                    stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
                    $write($socket, "EHLO neonfinswiss.world");
                    $read($socket);
                }
            }

            $write($socket, "AUTH LOGIN");
            $authResp = $read($socket);
            if (substr($authResp, 0, 3) !== '334') {
                fclose($socket);
                $lastErr = "AUTH LOGIN rejected on $remote: $authResp";
                continue;
            }

            $write($socket, base64_encode($user));
            $userResp = $read($socket);
            if (substr($userResp, 0, 3) !== '334') {
                fclose($socket);
                $lastErr = "Username rejected on $remote: $userResp";
                continue;
            }

            $write($socket, base64_encode($pass));
            $passResp = $read($socket);
            if (substr($passResp, 0, 3) !== '235') {
                fclose($socket);
                $lastErr = "Password rejected on $remote: $passResp";
                continue;
            }

            $write($socket, "MAIL FROM: <$from>");
            $mailResp = $read($socket);
            if (substr($mailResp, 0, 3) !== '250') {
                fclose($socket);
                $lastErr = "MAIL FROM rejected on $remote: $mailResp";
                continue;
            }

            $write($socket, "RCPT TO: <$targetTo>");
            $rcptResp = $read($socket);
            if (substr($rcptResp, 0, 3) !== '250') {
                fclose($socket);
                $lastErr = "RCPT TO rejected on $remote: $rcptResp";
                continue;
            }

            $write($socket, "DATA");
            $dataResp = $read($socket);
            if (substr($dataResp, 0, 3) !== '354') {
                fclose($socket);
                $lastErr = "DATA rejected on $remote: $dataResp";
                continue;
            }

            $headers  = "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
            $headers .= "From: =?UTF-8?B?" . base64_encode($fromName) . "?= <$from>\r\n";
            $headers .= "To: <$targetTo>\r\n";
            $headers .= "Reply-To: <$replyTo>\r\n";
            $headers .= "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n";
            $headers .= "Date: " . date(DATE_RFC2822) . "\r\n";
            $headers .= "Message-ID: <" . time() . '.' . uniqid() . "@neonfinswiss.world>\r\n";

            // Prepare body lines with dot-stuffing per RFC 5321
            $formattedBody = str_replace("\r\n", "\n", $htmlBody);
            $formattedBody = str_replace("\r", "\n", $formattedBody);
            $lines = explode("\n", $formattedBody);
            $stuffedLines = [];
            foreach ($lines as $line) {
                if (isset($line[0]) && $line[0] === '.') {
                    $stuffedLines[] = '.' . $line;
                } else {
                    $stuffedLines[] = $line;
                }
            }
            $cleanBodyStr = implode("\r\n", $stuffedLines);

            $messageData = $headers . "\r\n" . $cleanBodyStr . "\r\n.\r\n";
            fputs($socket, $messageData);

            $sendResp = $read($socket);
            $write($socket, "QUIT");
            fclose($socket);

            if (substr($sendResp, 0, 3) === '250') {
                return [
                    'success' => true,
                    'engine' => 'Socket SMTP (' . $remote . ')',
                    'message' => 'Email accepted by cPanel SMTP server.'
                ];
            } else {
                $lastErr = "Delivery error on $remote: $sendResp";
            }
        }

        return ['success' => false, 'message' => "SMTP Delivery Failed: " . $lastErr];
    }

    /**
     * Logs email transaction into email_logs table.
     */
    private static function log_email($to, $cc, $bcc, $subject, $body, $sender, $status, $error = null) {
        try {
            $pdo = get_db_connection();
            $toStr = is_array($to) ? implode(', ', $to) : $to;
            $ccStr = is_array($cc) ? implode(', ', $cc) : (empty($cc) ? null : $cc);
            $bccStr = is_array($bcc) ? implode(', ', $bcc) : (empty($bcc) ? null : $bcc);

            $stmt = $pdo->prepare("INSERT INTO email_logs 
                (recipient, cc, bcc, subject, body, sender, status, error_message) 
                VALUES (:recipient, :cc, :bcc, :subject, :body, :sender, :status, :error)");
            
            $stmt->execute([
                ':recipient' => $toStr,
                ':cc' => $ccStr,
                ':bcc' => $bccStr,
                ':subject' => $subject,
                ':body' => $body,
                ':sender' => $sender,
                ':status' => $status,
                ':error' => $error
            ]);
        } catch (\Throwable $e) {
            error_log("Failed to log email transaction: " . $e->getMessage());
        }
    }

    /**
     * Builds standard Neon Bank HTML Wrapper template matching neon web theme
     */
    public static function renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $tableRowsHtml, $statusBoxHtml = '') {
        $logoUrl = 'https://neonfinswiss.world/logo.webp';

        return '<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>' . htmlspecialchars($title) . '</title>
</head>
<body style="margin:0;padding:0;background-color:#0B0E17;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased;">
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0B0E17;padding:40px 15px;">
<tr>
<td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background-color:#121929;border:1px solid #1E2D4A;border-radius:20px;overflow:hidden;box-shadow:0 20px 50px rgba(0,0,0,0.5);width:100%;max-width:600px;">
<!-- Header Banner -->
<tr>
<td align="center" style="padding:40px 30px 30px;background:linear-gradient(180deg,#17233B 0%,#121929 100%);border-bottom:1px solid #1E2D4A;">
    <img src="' . $logoUrl . '" alt="Neon Bank" width="70" height="70" style="display:block;margin-bottom:12px;border-radius:14px;box-shadow:0 8px 20px rgba(0,242,254,0.15);">
    <h1 style="margin:0;color:#FFFFFF;font-size:26px;font-weight:900;letter-spacing:1px;text-transform:uppercase;">NEON BANK</h1>
    <p style="margin:5px 0 0;color:#00F2FE;font-size:12px;letter-spacing:2px;text-transform:uppercase;font-weight:700;">Swiss Private Digital Banking</p>
</td>
</tr>
<!-- Content Area -->
<tr>
<td style="padding:36px 32px;color:#CBD5E1;">
    <!-- Status Badge -->
    <div style="display:inline-block;padding:8px 16px;background-color:' . $badgeColor . '1E;border:1px solid ' . $badgeColor . '40;border-radius:30px;color:' . $badgeColor . ';font-size:12px;font-weight:800;letter-spacing:1px;text-transform:uppercase;margin-bottom:20px;">
        ' . htmlspecialchars($badgeText) . '
    </div>

    <h2 style="margin:0 0 12px;color:#FFFFFF;font-size:24px;font-weight:800;">' . htmlspecialchars($title) . '</h2>
    <p style="margin:0 0 16px;color:#CBD5E1;font-size:15px;line-height:26px;">Dear <strong>' . htmlspecialchars($customerName) . '</strong>,</p>
    <p style="margin:0 0 28px;color:#94A3B8;font-size:15px;line-height:26px;">' . $description . '</p>

    <!-- Details Table Card -->
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0A0F1D;border:1px solid #1E2D4A;border-radius:14px;margin-bottom:28px;overflow:hidden;">
        ' . $tableRowsHtml . '
    </table>

    ' . $statusBoxHtml . '
</td>
</tr>
<!-- Footer -->
<tr>
<td style="padding:28px 32px;background-color:#0A0F1D;border-top:1px solid #1E2D4A;text-align:center;">
    <p style="margin:0 0 10px;font-size:12px;color:#64748B;line-height:20px;">This is an automated operational notice from <strong>Neon Bank AG</strong>.<br>Please do not reply directly to this email.</p>
    <p style="margin:0 0 14px;font-size:12px;color:#64748B;">Need assistance? <a href="mailto:support@neonfinswiss.world" style="color:#00F2FE;text-decoration:none;font-weight:600;">support@neonfinswiss.world</a></p>
    <div style="height:1px;background-color:#1E2D4A;margin:16px 0;"></div>
    <p style="margin:0;font-size:11px;color:#475569;letter-spacing:0.5px;">&copy; 2026 Neon Bank AG. Zurich, Switzerland. All Rights Reserved.</p>
</td>
</tr>
</table>
</td>
</tr>
</table>
</body>
</html>';
    }

    /**
     * Helper to render a table row inside email cards
     */
    public static function renderTableRow($label, $value, $valueColor = '#FFFFFF', $isBold = false, $isLast = false) {
        $borderStyle = $isLast ? '' : 'border-bottom:1px solid #162035;';
        $fontWeight = $isBold ? 'font-weight:700;' : 'font-weight:400;';
        return '<tr>
            <td style="padding:14px 18px;color:#94A3B8;font-size:14px;' . $borderStyle . '">' . htmlspecialchars($label) . '</td>
            <td align="right" style="padding:14px 18px;color:' . $valueColor . ';font-size:15px;' . $fontWeight . $borderStyle . '">' . $value . '</td>
        </tr>';
    }

    /**
     * Sends an email stating the application is under review (Onboarding Submit).
     */
    public static function sendApplicationReviewEmail($email, $fullName, $appId) {
        try {
            $title = "Application Submitted & Under Review";
            $badgeText = "⏳ APPLICATION IN REVIEW";
            $badgeColor = "#00F2FE";
            $customerName = $fullName;
            $dateTime = date('d M Y, h:i A');

            $description = "Thank you for opening an account with <strong>Neon Bank</strong>. Your onboarding application has been successfully received and is currently undergoing secure KYC verification.";

            $rows = '';
            $rows .= self::renderTableRow('Application Reference', '<strong>' . htmlspecialchars($appId) . '</strong>', '#00F2FE', true);
            $rows .= self::renderTableRow('Applicant Name', htmlspecialchars($fullName));
            $rows .= self::renderTableRow('Submission Date', $dateTime);
            $rows .= self::renderTableRow('Review Status', '<span style="color:#00F2FE;font-weight:700;">IN PROGRESS (24-48h)</span>', '#00F2FE', true, true);

            $statusBox = '
            <div style="background-color:#0A1B2E;border-left:4px solid #00F2FE;border-radius:8px;padding:16px;margin-top:10px;">
                <strong style="color:#00F2FE;font-size:14px;">🔒 What Happens Next?</strong>
                <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">Our compliance team will review your uploaded verification documents. Once approved, you will receive your account number and instant access to your Neon Bank mobile portal.</p>
            </div>';

            $htmlBody = self::renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $rows, $statusBox);
            return self::sendMail($email, "Neon Bank - " . $title, $htmlBody);
        } catch (\Throwable $e) {
            return ['success' => false, 'message' => "Failed to send review notification email: " . $e->getMessage()];
        }
    }

    /**
     * Sends a transaction or approval notification email.
     */
    public static function sendNotificationEmail($accountNumber, $type, $amount = null, $reference = null, $remarks = null, $amountInr = null) {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT a.account_number, app.full_name, app.email, app.balance, app.account_type, app.initial_deposit 
                FROM accounts a 
                JOIN applications app ON a.app_id = app.app_id 
                WHERE a.account_number = :account_number LIMIT 1");
            $stmt->execute([':account_number' => $accountNumber]);
            $customer = $stmt->fetch();
            
            if (!$customer) {
                return ['success' => false, 'message' => "Customer with account number $accountNumber not found."];
            }

            $customerName = $customer['full_name'];
            $email = $customer['email'];
            $currentBalanceChf = number_format((float)$customer['balance'], 2);
            $dateTime = date('d M Y, h:i A');
            $ref = htmlspecialchars($reference ?: 'NEON-' . mt_rand(10000000, 99999999));
            $desc = htmlspecialchars($remarks ?: 'Neon Bank Operation');

            if ($type === 'approved') {
                $title = "Account Application Approved 🎉";
                $badgeText = "✓ ACCOUNT ACTIVATED";
                $badgeColor = "#10B981";
                $description = "Congratulations! Your <strong>Neon Bank</strong> private account application has been verified and fully activated.";

                $rows = '';
                $rows .= self::renderTableRow('Account Number', '<strong>' . htmlspecialchars($customer['account_number']) . '</strong>', '#10B981', true);
                $rows .= self::renderTableRow('Account Type', htmlspecialchars($customer['account_type']) . ' Account');
                $rows .= self::renderTableRow('Initial Deposit', 'CHF ' . number_format((float)$customer['initial_deposit'], 2), '#10B981', true);
                $rows .= self::renderTableRow('Available Balance', '<strong>CHF ' . $currentBalanceChf . '</strong>', '#FFFFFF', true);
                $rows .= self::renderTableRow('Activation Date', $dateTime, '#94A3B8', false, true);

                $statusBox = '
                <div style="background-color:#09201A;border-left:4px solid #10B981;border-radius:8px;padding:16px;">
                    <strong style="color:#10B981;font-size:14px;">✓ Account Ready For Use</strong>
                    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">You can now log into the Neon Bank mobile app to set your 6-digit Security MPIN and start instant transfers and international banking.</p>
                </div>';
            } elseif ($type === 'credit') {
                $title = "Account Credited Alert";
                $badgeText = "↑ BALANCE CREDITED";
                $badgeColor = "#10B981";
                $description = "A credit transaction has been processed and successfully deposited into your Neon Bank account.";

                $rows = '';
                $rows .= self::renderTableRow('Amount Credited', '<strong style="color:#10B981;font-size:18px;">+CHF ' . number_format((float)$amount, 2) . '</strong>', '#10B981', true);
                $rows .= self::renderTableRow('Account Number', htmlspecialchars($customer['account_number']));
                $rows .= self::renderTableRow('Updated Balance', '<strong>CHF ' . $currentBalanceChf . '</strong>', '#FFFFFF', true);
                $rows .= self::renderTableRow('Reference UTR', $ref);
                $rows .= self::renderTableRow('Date & Time', $dateTime);
                $rows .= self::renderTableRow('Description', $desc, '#CBD5E1', false, true);

                $statusBox = '
                <div style="background-color:#09201A;border-left:4px solid #10B981;border-radius:8px;padding:16px;">
                    <strong style="color:#10B981;font-size:14px;">✓ Funds Deposited</strong>
                    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">The credited amount is immediately available in your balance for transfers and card operations.</p>
                </div>';
            } elseif ($type === 'debit' || $type === 'payout') {
                $title = ($type === 'payout' || str_contains(strtolower($desc), 'payout')) ? "Payout Transfer Executed" : "Account Debited Alert";
                $badgeText = "↓ BALANCE DEBITED";
                $badgeColor = "#EF4444";
                $description = "A debit transaction has been executed on your Neon Bank account.";

                $rows = '';
                $rows .= self::renderTableRow('Amount Debited (Base)', '<strong style="color:#EF4444;font-size:18px;">-CHF ' . number_format((float)$amount, 2) . '</strong>', '#EF4444', true);
                
                if ($amountInr !== null && (float)$amountInr > 0) {
                    $rows .= self::renderTableRow('Converted Payout Amount', '<strong style="color:#00F2FE;font-size:16px;">₹ ' . number_format((float)$amountInr, 2) . ' INR</strong>', '#00F2FE', true);
                }
                
                $rows .= self::renderTableRow('Account Number', htmlspecialchars($customer['account_number']));
                $rows .= self::renderTableRow('Remaining Balance', '<strong>CHF ' . $currentBalanceChf . '</strong>', '#FFFFFF', true);
                $rows .= self::renderTableRow('Reference UTR / ID', $ref);
                $rows .= self::renderTableRow('Date & Time', $dateTime);
                $rows .= self::renderTableRow('Description', $desc, '#CBD5E1', false, true);

                $statusBox = '
                <div style="background-color:#2A1215;border-left:4px solid #EF4444;border-radius:8px;padding:16px;">
                    <strong style="color:#EF4444;font-size:14px;">✓ Transaction Executed</strong>
                    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">If you did not authorize this debit operation, please contact our 24/7 security desk immediately at support@neonfinswiss.world.</p>
                </div>';
            } elseif ($type === 'failed') {
                $title = "Transaction Attempt Failed";
                $badgeText = "✕ TRANSACTION FAILED";
                $badgeColor = "#EF4444";
                $description = "A transaction attempt on your account could not be completed.";

                $rows = '';
                $rows .= self::renderTableRow('Attempted Amount', 'CHF ' . number_format((float)$amount, 2), '#EF4444', true);
                if ($amountInr !== null && (float)$amountInr > 0) {
                    $rows .= self::renderTableRow('Converted Payout Amount', '₹ ' . number_format((float)$amountInr, 2) . ' INR', '#CBD5E1');
                }
                $rows .= self::renderTableRow('Account Number', htmlspecialchars($customer['account_number']));
                $rows .= self::renderTableRow('Reference Code', $ref);
                $rows .= self::renderTableRow('Failure Reason', htmlspecialchars($reference ?: 'Processing decline'), '#EF4444', true);
                $rows .= self::renderTableRow('Date & Time', $dateTime, '#CBD5E1', false, true);

                $statusBox = '
                <div style="background-color:#2A1215;border-left:4px solid #EF4444;border-radius:8px;padding:16px;">
                    <strong style="color:#EF4444;font-size:14px;">✕ Balance Preserved</strong>
                    <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">No funds were deducted from your account. Please check recipient details and try again.</p>
                </div>';
            } else {
                return ['success' => false, 'message' => "Invalid notification type: $type"];
            }

            $htmlBody = self::renderNeonTemplate($title, $customerName, $badgeText, $badgeColor, $description, $rows, $statusBox);
            return self::sendMail($email, "Neon Bank - " . $title, $htmlBody);
        } catch (\Throwable $e) {
            return ['success' => false, 'message' => "Failed to send notification email: " . $e->getMessage()];
        }
    }

    /**
     * Sends Password Reset Security Code OTP email.
     */
    public static function sendPasswordResetOtpEmail($email, $name, $otp) {
        try {
            $title = "Password Reset Security Code";
            $badgeText = "🔒 SECURITY VERIFICATION";
            $badgeColor = "#00F2FE";
            $dateTime = date('d M Y, h:i A');

            $description = "We received a request to reset the password for your <strong>Neon Bank</strong> account. Use the 6-digit security code below to authorize your request:";

            $rows = '';
            $rows .= self::renderTableRow('One-Time Security OTP', '<span style="font-size:24px;font-weight:900;letter-spacing:4px;color:#00F2FE;">' . htmlspecialchars($otp) . '</span>', '#00F2FE', true);
            $rows .= self::renderTableRow('Validity Period', '15 Minutes', '#F59E0B', true);
            $rows .= self::renderTableRow('Request Date', $dateTime, '#94A3B8', false, true);

            $statusBox = '
            <div style="background-color:#0A1B2E;border-left:4px solid #00F2FE;border-radius:8px;padding:16px;">
                <strong style="color:#00F2FE;font-size:14px;">⚠️ Security Advisory</strong>
                <p style="margin:8px 0 0;color:#94A3B8;font-size:13px;line-height:22px;">Never share this OTP code with anyone, including Neon Bank staff. If you did not initiate this request, please ignore this email.</p>
            </div>';

            $htmlBody = self::renderNeonTemplate($title, $name, $badgeText, $badgeColor, $description, $rows, $statusBox);
            return self::sendMail($email, "Neon Bank - " . $title, $htmlBody);
        } catch (\Throwable $e) {
            return ['success' => false, 'message' => "Failed to send OTP email: " . $e->getMessage()];
        }
    }
}
