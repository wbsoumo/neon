<?php
/**
 * Deccan Finance - Reusable Email Service
 * Uses database SMTP settings and PHPMailer to send HTML emails dynamically.
 */

require_once __DIR__ . '/db_helper.php';
require_once dirname(__DIR__) . '/vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

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
            if ($settings) {
                $settings['smtp_pass'] = self::decrypt_password($settings['smtp_pass_encrypted']);
            }
            return $settings;
        } catch (\Exception $e) {
            error_log("Failed to load SMTP settings: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Sends an email using SMTP configuration from database.
     *
     * @param string|array $to Recipient email(s)
     * @param string $subject Subject
     * @param string $htmlBody HTML Body
     * @param array $attachments Array of attachment paths or [path, name] arrays
     * @param string|array $cc CC address(es)
     * @param string|array $bcc BCC address(es)
     * @return array ['success' => bool, 'message' => string]
     */
    public static function sendMail($to, $subject, $htmlBody, $attachments = [], $cc = [], $bcc = []) {
        $settings = self::get_settings();
        if (!$settings) {
            return [
                'success' => false,
                'message' => 'SMTP settings not found in database.'
            ];
        }

        $mail = new PHPMailer(true);
        $mail->CharSet = 'UTF-8';

        try {
            // Enable SMTP debugging if requested or log manually
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
            $mail->Timeout    = 10; // Set a 10 second timeout to prevent page hanging

            // Disable automatic verification of self-signed SSL/TLS certs if needed (for local tests)
            $mail->SMTPOptions = [
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                ]
            ];

            // Set Sender and Reply-To
            $mail->setFrom($settings['from_email'], $settings['from_name']);
            if (!empty($settings['reply_to'])) {
                $mail->addReplyTo($settings['reply_to']);
            }

            // Add Recipient(s)
            if (is_array($to)) {
                foreach ($to as $t) {
                    $t = trim($t);
                    if (!empty($t)) $mail->addAddress($t);
                }
            } else {
                $mail->addAddress(trim($to));
            }

            // Add CC
            if (!empty($cc)) {
                $ccList = is_array($cc) ? $cc : explode(',', $cc);
                foreach ($ccList as $c) {
                    $c = trim($c);
                    if (!empty($c)) $mail->addCC($c);
                }
            }

            // Add BCC
            if (!empty($bcc)) {
                $bccList = is_array($bcc) ? $bcc : explode(',', $bcc);
                foreach ($bccList as $b) {
                    $b = trim($b);
                    if (!empty($b)) $mail->addBCC($b);
                }
            }

            // Add Attachments
            if (!empty($attachments)) {
                foreach ($attachments as $a) {
                    if (is_array($a)) {
                        $path = $a['path'] ?? '';
                        $name = $a['name'] ?? '';
                        if (!empty($path) && file_exists($path)) {
                            $mail->addAttachment($path, $name);
                        }
                    } else {
                        if (!empty($a) && file_exists($a)) {
                            $mail->addAttachment($a);
                        }
                    }
                }
            }

            // Content
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body    = $htmlBody;
            $mail->AltBody = strip_tags($htmlBody);

            $mail->send();

            // Log successful email
            self::log_email($to, $cc, $bcc, $subject, $htmlBody, $settings['from_email'], 'SUCCESS');

            return [
                'success' => true,
                'message' => 'Email sent successfully.'
            ];
        } catch (\Exception $e) {
            $errorInfo = $mail->ErrorInfo ?: $e->getMessage();
            error_log("Email sending error: " . $errorInfo);

            // Log failed email
            self::log_email($to, $cc, $bcc, $subject, $htmlBody, $settings['from_email'] ?? 'System', 'FAILED', $errorInfo);

            return [
                'success' => false,
                'message' => 'Email sending failed: ' . $errorInfo
            ];
        }
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
        } catch (\Exception $e) {
            error_log("Failed to log email transaction: " . $e->getMessage());
        }
    }

    /**
     * Sends a transaction or approval notification email using the branded HTML template.
     *
     * @param string $accountNumber Customer's 11-digit account number
     * @param string $type 'credit' | 'debit' | 'approved'
     * @param float|null $amount Transaction amount (optional)
     * @param string|null $reference Reference/UTR number (optional)
     * @param string|null $remarks Transaction remarks/description (optional)
     * @return array
     */
    public static function sendNotificationEmail($accountNumber, $type, $amount = null, $reference = null, $remarks = null) {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT a.account_number, app.full_name, app.email, app.balance, app.account_type, app.initial_deposit, app.tx_failed_email_template 
                FROM accounts a 
                JOIN applications app ON a.app_id = app.app_id 
                WHERE a.account_number = :account_number LIMIT 1");
            $stmt->execute([':account_number' => $accountNumber]);
            $customer = $stmt->fetch();
            
            if (!$customer) {
                return ['success' => false, 'message' => "Customer with account number $accountNumber not found."];
            }

            $customer_name = htmlspecialchars($customer['full_name']);
            $email = $customer['email'];
            $current_balance = number_format($customer['balance'], 2);
            $date_time = date('d M Y h:i A');
            $ref = htmlspecialchars($reference ?: 'DF-' . mt_rand(10000000, 99999999));
            $desc = htmlspecialchars($remarks ?: 'N/A');

            // Template theme mapping
            if ($type === 'credit') {
                $title = "Balance Credited";
                $gradient_start = "#5B5CF6";
                $gradient_end = "#7C63FF";
                $amount_label = "Amount Credited";
                $amount_val = "₹" . number_format($amount, 2);
                $amount_color = "#16a34a";
                $body_description = "A credit transaction has been successfully completed in your Deccan Finance account.";
                $txn_type_label = "CREDIT";
                $status_block = '
                <div style="background:#edfdf3;padding:18px;border-radius:10px;border-left:5px solid #16a34a;">
                    <strong style="color:#16a34a;">✓ Money Successfully Credited</strong>
                    <p style="margin:10px 0 0;color:#555;line-height:24px;">The credited amount is now available in your account and can be used immediately for transfers, payments, or withdrawals.</p>
                </div>';
            } elseif ($type === 'debit') {
                $title = "Balance Debited";
                $gradient_start = "#ef4444";
                $gradient_end = "#b91c1c";
                $amount_label = "Amount Debited";
                $amount_val = "₹" . number_format($amount, 2);
                $amount_color = "#dc2626";
                $body_description = "A debit transaction has been successfully completed in your Deccan Finance account.";
                $txn_type_label = "DEBIT";
                $status_block = '
                <div style="background:#fef2f2;padding:18px;border-radius:10px;border-left:5px solid #dc2626;">
                    <strong style="color:#dc2626;">✓ Money Successfully Debited</strong>
                    <p style="margin:10px 0 0;color:#555;line-height:24px;">The debited amount has been successfully deducted from your account balance.</p>
                </div>';
            } elseif ($type === 'failed') {
                $title = "Transaction Failed";
                $gradient_start = "#ef4444";
                $gradient_end = "#b91c1c";
                $amount_label = "Transaction Amount";
                $amount_val = "₹" . number_format($amount, 2);
                $amount_color = "#dc2626";
                $body_description = "A transaction attempt could not be processed on your account.";
                $txn_type_label = "FAILED_TRANSACTION";

                $defaultTemplate = '
                <div style="background:#fef2f2;padding:18px;border-radius:10px;border-left:5px solid #dc2626;margin-top:20px;">
                    <strong style="color:#dc2626;">✗ Money Transaction Failed</strong>
                    <p style="margin:10px 0 0;color:#555;line-height:24px;">The transaction could not be processed. Reason: {reason}</p>
                </div>';

                $templateContent = !empty($customer['tx_failed_email_template']) ? $customer['tx_failed_email_template'] : $defaultTemplate;

                // Replace placeholders
                $templateContent = str_replace('{name}', $customer_name, $templateContent);
                $templateContent = str_replace('{account_number}', htmlspecialchars($customer['account_number']), $templateContent);
                $templateContent = str_replace('{amount}', "₹" . number_format($amount, 2), $templateContent);
                $templateContent = str_replace('{recipient_account}', htmlspecialchars($remarks ?: 'N/A'), $templateContent);
                $templateContent = str_replace('{reason}', htmlspecialchars($reference ?: 'N/A'), $templateContent);
                $templateContent = str_replace('{date_time}', $date_time, $templateContent);
                $templateContent = str_replace('{reference_number}', $ref, $templateContent);

                $status_block = $templateContent;
            } elseif ($type === 'approved') {
                $title = "Account Approved 🎉";
                $gradient_start = "#10b981";
                $gradient_end = "#047857";
                $amount_label = "Initial Deposit";
                $amount_val = "₹" . number_format($customer['initial_deposit'], 2);
                $amount_color = "#10b981";
                $body_description = "Congratulations! Your Deccan Finance account application has been approved and activated.";
                $txn_type_label = "ACCOUNT_ACTIVATION";
                $status_block = '
                <div style="background:#edfdf3;padding:18px;border-radius:10px;border-left:5px solid #10b981;">
                    <strong style="color:#10b981;">✓ Account Successfully Activated</strong>
                    <p style="margin:10px 0 0;color:#555;line-height:24px;">Your account is now fully active. You can set up your login PIN and MPIN using your registered Aadhaar details to begin transactions.</p>
                </div>';
                $desc = "Account: " . htmlspecialchars($customer['account_type']) . " Account";
            } else {
                return ['success' => false, 'message' => "Invalid notification type: $type"];
            }

            // Conditionally add Account Number row for approved accounts
            $account_number_row = '';
            if ($type === 'approved') {
                $account_number_row = '
                <tr>
                    <td style="color:#666;">Account Number</td>
                    <td align="right" style="color:#222;"><strong>' . htmlspecialchars($customer['account_number']) . '</strong></td>
                </tr>';
            }

            // Action button removed per request
            $action_button = '';

            // HTML Body Template Compilation
            $htmlBody = '<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>' . $title . '</title>
</head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb;padding:40px 0;">
<tr>
<td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 25px rgba(0,0,0,.08);">
<tr>
<td align="center" style="padding:35px 20px;background:linear-gradient(135deg,' . $gradient_start . ',' . $gradient_end . ');">
<img src="https://deccanfinltd.world/assets/img/logo.png" width="80" style="display:block;margin-bottom:10px;">
<h1 style="margin:10px 0 5px;color:#fff;font-size:30px;">Deccan Finance</h1>
<p style="margin:0;color:#e7e7ff;font-size:15px;">Secure. Simple. Trusted.</p>
</td>
</tr>
<tr>
<td style="padding:40px;">
<h2 style="margin-top:0;color:#222;font-size:28px;">' . $title . '</h2>
<p style="color:#555;font-size:16px;line-height:28px;">Hello <strong>' . $customer_name . '</strong>,</p>
<p style="color:#555;font-size:16px;line-height:28px;">' . $body_description . '</p>
<table width="100%" cellpadding="12" cellspacing="0" style="margin:30px 0;background:#f8f9ff;border-radius:12px;">
<tr>
<td style="color:#666;">' . $amount_label . '</td>
<td align="right" style="font-size:28px;font-weight:bold;color:' . $amount_color . ';">' . $amount_val . '</td>
</tr>' . $account_number_row . '
<tr>
<td style="color:#666;">Available Balance</td>
<td align="right" style="font-size:18px;color:#222;"><strong>₹' . $current_balance . '</strong></td>
</tr>
<tr>
<td style="color:#666;">Date & Time</td>
<td align="right" style="color:#222;">' . $date_time . '</td>
</tr>
<tr>
<td style="color:#666;">Reference Number</td>
<td align="right" style="color:#222;">' . $ref . '</td>
</tr>
<tr>
<td style="color:#666;">Transaction Type</td>
<td align="right" style="color:#222;">' . $txn_type_label . '</td>
</tr>
<tr>
<td style="color:#666;">Description</td>
<td align="right" style="color:#222;">' . $desc . '</td>
</tr>
</table>
' . $status_block . '
' . $action_button . '
</td>
</tr>
<tr>
<td style="padding:30px;background:#fafafa;border-top:1px solid #eee;">
<table width="100%">
<tr>
<td align="center">
<p style="margin:0;font-size:13px;color:#888;">This is an automated notification. Please do not reply to this email.</p>
<p style="margin-top:15px;font-size:13px;color:#999;">Need help? <a href="mailto:support@deccanfinltd.world" style="color:' . $gradient_start . ';text-decoration:none;">support@deccanfinltd.world</a></p>
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

            return self::sendMail($email, "Deccan Finance - " . $title, $htmlBody);
        } catch (\Exception $e) {
            return ['success' => false, 'message' => "Failed to send notification email: " . $e->getMessage()];
        }
    }

    /**
     * Sends an email stating the application is under review.
     */
    public static function sendApplicationReviewEmail($email, $fullName, $appId) {
        try {
            $title = "Application Under Review ⏳";
            $gradient_start = "#031f73";
            $gradient_end = "#02144a";
            $date_time = date('d M Y h:i A');
            $customer_name = htmlspecialchars($fullName);

            $htmlBody = '<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>' . $title . '</title>
</head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb;padding:40px 0;">
<tr>
<td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 25px rgba(0,0,0,.08);">
<tr>
<td align="center" style="padding:35px 20px;background:linear-gradient(135deg,' . $gradient_start . ',' . $gradient_end . ');">
<img src="https://deccanfinltd.world/assets/img/logo.png" width="80" style="display:block;margin-bottom:10px;">
<h1 style="margin:10px 0 5px;color:#fff;font-size:30px;">Deccan Finance</h1>
<p style="margin:0;color:#e7e7ff;font-size:15px;">Secure. Simple. Trusted.</p>
</td>
</tr>
<tr>
<td style="padding:40px;">
<h2 style="margin-top:0;color:#222;font-size:28px;">' . $title . '</h2>
<p style="color:#555;font-size:16px;line-height:28px;">Hello <strong>' . $customer_name . '</strong>,</p>
<p style="color:#555;font-size:16px;line-height:28px;">Thank you for submitting your application to Deccan Finance.</p>
<p style="color:#555;font-size:16px;line-height:28px;">Your application has been received and is currently <strong>under review</strong>. Our compliance team will verify your details within the next <strong>24-48 hours</strong>.</p>
<table width="100%" cellpadding="12" cellspacing="0" style="margin:30px 0;background:#f8f9ff;border-radius:12px;">
<tr>
<td style="color:#666;">Application ID</td>
<td align="right" style="font-size:18px;color:#222;"><strong>' . htmlspecialchars($appId) . '</strong></td>
</tr>
<tr>
<td style="color:#666;">Submission Date</td>
<td align="right" style="color:#222;">' . $date_time . '</td>
</tr>
</table>
<div style="background:#f8f9ff;padding:18px;border-radius:10px;border-left:5px solid #031f73;">
    <strong style="color:#031f73;">⏳ Verification in Progress</strong>
    <p style="margin:10px 0 0;color:#555;line-height:24px;">Please keep your Application ID safe. You can use it to track your application status or log in once approved.</p>
</div>
</td>
</tr>
<tr>
<td style="padding:30px;background:#fafafa;border-top:1px solid #eee;">
<table width="100%">
<tr>
<td align="center">
<p style="margin:0;font-size:13px;color:#888;">This is an automated notification. Please do not reply to this email.</p>
<p style="margin-top:15px;font-size:13px;color:#999;">Need help? <a href="mailto:support@deccanfinltd.world" style="color:' . $gradient_start . ';text-decoration:none;">support@deccanfinltd.world</a></p>
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

            return self::sendMail($email, "Deccan Finance - " . $title, $htmlBody);
        } catch (\Exception $e) {
            return ['success' => false, 'message' => "Failed to send review notification email: " . $e->getMessage()];
        }
    }
}
