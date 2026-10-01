<?php
/**
 * Deccan Finance - SMTP Email Settings Page
 */

require_once '../api/db_helper.php';
require_once '../api/email_service.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

// Guard admin access
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: login.php');
    exit;
}

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Administrator';
$initials = strtoupper(substr($username, 0, 2));

// CSRF Security Token initialization
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

$message = '';
$messageType = '';

// Process POST requests
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Validate CSRF
    $csrf = isset($_POST['csrf_token']) ? $_POST['csrf_token'] : '';
    if (!hash_equals($_SESSION['csrf_token'], $csrf)) {
        $message = "Invalid CSRF security token.";
        $messageType = "danger";
    } else {
        $action = isset($_POST['action']) ? $_POST['action'] : '';
        
        $smtp_host = isset($_POST['smtp_host']) ? trim($_POST['smtp_host']) : '';
        $smtp_port = isset($_POST['smtp_port']) ? (int)$_POST['smtp_port'] : 587;
        $smtp_encryption = isset($_POST['smtp_encryption']) ? trim($_POST['smtp_encryption']) : 'TLS';
        $smtp_user = isset($_POST['smtp_user']) ? trim($_POST['smtp_user']) : '';
        $smtp_pass = isset($_POST['smtp_pass']) ? trim($_POST['smtp_pass']) : '';
        $from_email = isset($_POST['from_email']) ? trim($_POST['from_email']) : '';
        $from_name = isset($_POST['from_name']) ? trim($_POST['from_name']) : '';
        $reply_to = isset($_POST['reply_to']) ? trim($_POST['reply_to']) : '';
        $smtp_auth = isset($_POST['smtp_auth']) ? 1 : 0;

        // Fetch current saved settings to preserve password if not updated
        $currentSettings = EmailService::get_settings();
        $encryptedPass = $currentSettings ? $currentSettings['smtp_pass_encrypted'] : '';

        if (!empty($smtp_pass)) {
            $encryptedPass = EmailService::encrypt_password($smtp_pass);
        }

        if ($action === 'SAVE_SETTINGS') {
            try {
                $pdo = get_db_connection();
                // We keep only one settings row
                $pdo->exec("DELETE FROM smtp_settings");
                $stmt = $pdo->prepare("INSERT INTO smtp_settings 
                    (smtp_host, smtp_port, smtp_encryption, smtp_user, smtp_pass_encrypted, from_email, from_name, reply_to, smtp_auth) 
                    VALUES (:host, :port, :encryption, :user, :pass, :from_email, :from_name, :reply_to, :auth)");
                
                $stmt->execute([
                    ':host' => $smtp_host,
                    ':port' => $smtp_port,
                    ':encryption' => $smtp_encryption,
                    ':user' => $smtp_user,
                    ':pass' => $encryptedPass,
                    ':from_email' => $from_email,
                    ':from_name' => $from_name,
                    ':reply_to' => $reply_to,
                    ':auth' => $smtp_auth
                ]);
                $message = "SMTP Settings saved successfully.";
                $messageType = "success";
            } catch (\Exception $e) {
                $message = "Error saving settings: " . $e->getMessage();
                $messageType = "danger";
            }
        } 
        elseif ($action === 'TEST_CONNECTION') {
            // Dry run SMTP connection handshake
            $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
            try {
                $mail->isSMTP();
                $mail->Host       = $smtp_host;
                $mail->SMTPAuth   = (bool)$smtp_auth;
                $mail->Username   = $smtp_user;
                // If a new password was provided in post, use it; otherwise decrypt current
                $mail->Password   = !empty($smtp_pass) ? $smtp_pass : ($currentSettings ? $currentSettings['smtp_pass'] : '');
                
                $encryption = strtoupper($smtp_encryption);
                if ($encryption === 'TLS') {
                    $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
                } elseif ($encryption === 'SSL') {
                    $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
                } else {
                    $mail->SMTPSecure = '';
                }
                $mail->Port       = $smtp_port;
                $mail->Timeout    = 10;
                
                // Allow self-signed certs for local validation
                $mail->SMTPOptions = [
                    'ssl' => [
                        'verify_peer' => false,
                        'verify_peer_name' => false,
                        'allow_self_signed' => true
                    ]
                ];

                $mail->smtpConnect();
                $mail->smtpClose();

                $message = "SMTP Handshake Successful! Connection established successfully.";
                $messageType = "success";
            } catch (\Exception $e) {
                $message = "SMTP Connection Failed: " . ($mail->ErrorInfo ?: $e->getMessage());
                $messageType = "danger";
            }
        }
        elseif ($action === 'SEND_TEST_EMAIL') {
            $test_to = isset($_POST['test_to']) ? trim($_POST['test_to']) : '';
            if (empty($test_to)) {
                $message = "Please enter a recipient email address for the test.";
                $messageType = "warning";
            } else {
                // If a new password is typed in the form, use the transient settings
                // Otherwise use the stored ones
                $transientPass = !empty($smtp_pass) ? $smtp_pass : ($currentSettings ? $currentSettings['smtp_pass'] : '');
                
                // Temporarily override config to test the input credentials
                $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
                try {
                    $mail->isSMTP();
                    $mail->Host       = $smtp_host;
                    $mail->SMTPAuth   = (bool)$smtp_auth;
                    $mail->Username   = $smtp_user;
                    $mail->Password   = $transientPass;
                    
                    $encryption = strtoupper($smtp_encryption);
                    if ($encryption === 'TLS') {
                        $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
                    } elseif ($encryption === 'SSL') {
                        $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
                    } else {
                        $mail->SMTPSecure = '';
                    }
                    $mail->Port       = $smtp_port;

                    $mail->setFrom($from_email, $from_name);
                    $mail->addAddress($test_to);
                    $mail->isHTML(true);
                    $mail->Subject = "Deccan Finance - SMTP Test Email";
                    $mail->Body    = "<h3>Deccan Finance SMTP Verification</h3><p>This email confirms that your admin SMTP configuration is working correctly.</p><p>Timestamp: " . date('Y-m-d H:i:s') . "</p>";
                    
                    $mail->send();
                    $message = "Test email sent successfully to " . htmlspecialchars($test_to);
                    $messageType = "success";
                } catch (\Exception $e) {
                    $message = "Email sending failed: " . ($mail->ErrorInfo ?: $e->getMessage());
                    $messageType = "danger";
                }
            }
        }
    }
}

// Fetch current SMTP Settings
$settings = EmailService::get_settings();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Deccan Finance - SMTP Settings</title>
    <!-- Google Font: Source Sans Pro -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <!-- Brand Favicon -->
    <link rel="icon" type="image/png" href="../assets/img/favicon.png">

    <style>
        /* BRAND COLOR OVERRIDES */
        .main-header.navbar {
            background-color: #031f73 !important;
            border-bottom: 4px solid #fecb00 !important;
        }
        .main-header.navbar .nav-link,
        .main-header.navbar .navbar-brand {
            color: #ffffff !important;
        }
        .main-header.navbar .nav-link:hover {
            color: #fecb00 !important;
        }
        .main-sidebar {
            background-color: #02144a !important;
        }
        .sidebar-dark-primary .nav-sidebar > .nav-item > .nav-link.active {
            background-color: #fecb00 !important;
            color: #031f73 !important;
            font-weight: 700;
        }
        .brand-link {
            border-bottom: 1px solid #fecb00 !important;
            background-color: #02144a !important;
        }
        .brand-link .brand-text {
            color: #ffffff !important;
            font-weight: 700;
        }
        .sidebar a {
            color: rgba(255, 255, 255, 0.8) !important;
        }
        .sidebar a:hover, .sidebar .nav-link.active a {
            color: #ffffff !important;
        }
        .sidebar-dark-primary .nav-sidebar>.nav-item>.nav-link.active .nav-icon {
            color: #031f73 !important;
        }
        .card-navy-brand:not(.card-outline) > .card-header {
            background-color: #031f73 !important;
            color: #ffffff !important;
            border-bottom: 2px solid #fecb00;
        }
    </style>
</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

    <!-- Top Navbar -->
    <nav class="main-header navbar navbar-expand navbar-dark">
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
            </li>
            <li class="nav-item d-none d-sm-inline-block">
                <a href="../index.html" class="nav-link">Main Website</a>
            </li>
        </ul>

        <ul class="navbar-nav ml-auto">
            <li class="nav-item d-none d-sm-inline-block">
                <a href="logout.php" class="nav-link text-warning font-weight-bold"><i class="fas fa-sign-out-alt mr-1"></i> Logout</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" data-widget="fullscreen" href="#" role="button">
                    <i class="fas fa-expand-arrows-alt"></i>
                </a>
            </li>
        </ul>
    </nav>

    <!-- Main Sidebar Container -->
    <aside class="main-sidebar sidebar-dark-primary elevation-4">
        <a href="dashboard.php" class="brand-link">
            <img src="../assets/img/favicon.png" alt="Deccan Finance" class="brand-image img-circle elevation-3" style="opacity: .8">
            <span class="brand-text font-weight-light">Deccan Finance</span>
        </a>

        <div class="sidebar">
            <div class="user-panel mt-3 pb-3 mb-3 d-flex">
                <div class="image">
                    <span class="img-circle elevation-2 text-white bg-warning d-flex align-items-center justify-content-center" style="width: 32px; height: 32px; font-weight: 700;"><?= $initials ?></span>
                </div>
                <div class="info">
                    <a href="#" class="d-block"><?= htmlspecialchars($username) ?></a>
                </div>
            </div>

            <!-- Sidebar Menu -->
            <nav class="mt-2">
                <ul class="nav nav-pills nav-sidebar flex-column" role="menu">
                    <li class="nav-header">MANAGEMENT</li>
                    <li class="nav-item">
                        <a href="dashboard.php" class="nav-link">
                            <i class="nav-icon fas fa-tachometer-alt"></i>
                            <p>Dashboard</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="user_profiles.php" class="nav-link">
                            <i class="nav-icon fas fa-users-cog"></i>
                            <p>User Profiles</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="transactions.php" class="nav-link">
                            <i class="nav-icon fas fa-exchange-alt"></i>
                            <p>All Transactions</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="settings.php" class="nav-link">
                            <i class="nav-icon fas fa-shield-alt"></i>
                            <p>Security Settings</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="compliance.php" class="nav-link">
                            <i class="nav-icon fas fa-file-contract"></i>
                            <p>Compliance Manager</p>
                        </a>
                    </li>
                    <li class="nav-header">EMAIL SYSTEM</li>
                    <li class="nav-item">
                        <a href="email_settings.php" class="nav-link active">
                            <i class="nav-icon fas fa-envelope-open-text"></i>
                            <p>Email Settings</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="send_email.php" class="nav-link">
                            <i class="nav-icon fas fa-paper-plane"></i>
                            <p>Send Email</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="email_logs.php" class="nav-link">
                            <i class="nav-icon fas fa-history"></i>
                            <p>Email Logs</p>
                        </a>
                    </li>
                    <li class="nav-header">SESSION</li>
                    <li class="nav-item">
                        <a href="logout.php" class="nav-link">
                            <i class="nav-icon fas fa-sign-out-alt text-warning"></i>
                            <p>Logout</p>
                        </a>
                    </li>
                </ul>
            </nav>
        </div>
    </aside>

    <!-- Content Wrapper -->
    <div class="content-wrapper">
        <div class="content-header">
            <div class="container-fluid">
                <div class="row mb-2">
                    <div class="col-sm-6">
                        <h1 class="m-0 text-navy font-weight-bold">SMTP Email Settings</h1>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <section class="content">
            <div class="container-fluid">
                
                <?php if (!empty($message)): ?>
                    <div class="alert alert-<?= $messageType ?> alert-dismissible fade show" role="alert">
                        <strong>Status:</strong> <?= htmlspecialchars($message) ?>
                        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                <?php endif; ?>

                <div class="row">
                    <div class="col-md-8">
                        <div class="card card-navy-brand">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">SMTP Configuration</h3>
                            </div>
                            <form action="email_settings.php" method="POST">
                                <input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">
                                
                                <div class="card-body">
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Host</label>
                                        <div class="col-sm-9">
                                            <input type="text" class="form-control" name="smtp_host" required
                                                   value="<?= htmlspecialchars($settings['smtp_host'] ?? 'mail.deccanfinltd.world') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Port</label>
                                        <div class="col-sm-9">
                                            <input type="number" class="form-control" name="smtp_port" required
                                                   value="<?= htmlspecialchars($settings['smtp_port'] ?? '587') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Encryption</label>
                                        <div class="col-sm-9">
                                            <select class="form-control" name="smtp_encryption">
                                                <option value="TLS" <?= ($settings['smtp_encryption'] ?? 'TLS') === 'TLS' ? 'selected' : '' ?>>TLS</option>
                                                <option value="SSL" <?= ($settings['smtp_encryption'] ?? 'TLS') === 'SSL' ? 'selected' : '' ?>>SSL</option>
                                                <option value="NONE" <?= ($settings['smtp_encryption'] ?? 'TLS') === 'NONE' ? 'selected' : '' ?>>None</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Username</label>
                                        <div class="col-sm-9">
                                            <input type="text" class="form-control" name="smtp_user" required
                                                   value="<?= htmlspecialchars($settings['smtp_user'] ?? 'support@deccanfinltd.world') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Password</label>
                                        <div class="col-sm-9">
                                            <input type="password" class="form-control" name="smtp_pass" 
                                                   placeholder="<?= !empty($settings['smtp_pass_encrypted']) ? '•••••••• (Leave blank to keep current)' : 'Enter password' ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">From Email</label>
                                        <div class="col-sm-9">
                                            <input type="email" class="form-control" name="from_email" required
                                                   value="<?= htmlspecialchars($settings['from_email'] ?? 'support@deccanfinltd.world') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">From Name</label>
                                        <div class="col-sm-9">
                                            <input type="text" class="form-control" name="from_name" required
                                                   value="<?= htmlspecialchars($settings['from_name'] ?? 'Deccan Finance') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">Reply-To Email</label>
                                        <div class="col-sm-9">
                                            <input type="email" class="form-control" name="reply_to" required
                                                   value="<?= htmlspecialchars($settings['reply_to'] ?? 'support@deccanfinltd.world') ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-3 col-form-label">SMTP Authentication</label>
                                        <div class="col-sm-9">
                                            <div class="custom-control custom-switch mt-2">
                                                <input type="checkbox" class="custom-control-input" id="smtp_auth" name="smtp_auth" 
                                                       <?= ($settings['smtp_auth'] ?? 1) ? 'checked' : '' ?>>
                                                <label class="custom-control-label" for="smtp_auth">Require SMTP Authentication</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-footer bg-light d-flex justify-content-between">
                                    <button type="submit" name="action" value="SAVE_SETTINGS" class="btn btn-primary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Save Settings
                                    </button>
                                    <div>
                                        <a href="../test_review_email.php" target="_blank" class="btn btn-success font-weight-bold mr-1">
                                            <i class="fas fa-eye mr-1"></i> Open Template Tester
                                        </a>
                                        <button type="submit" name="action" value="TEST_CONNECTION" class="btn btn-secondary font-weight-bold mr-1">
                                            <i class="fas fa-plug mr-1"></i> Test SMTP Connection
                                        </button>
                                        <button type="button" class="btn btn-info font-weight-bold" data-toggle="modal" data-target="#testEmailModal">
                                            <i class="fas fa-envelope mr-1"></i> Send Test Email
                                        </button>
                                    </div>
                                </div>

                                <!-- Test Email Modal -->
                                <div class="modal fade" id="testEmailModal" tabindex="-1" role="dialog" aria-hidden="true">
                                    <div class="modal-dialog" role="document">
                                        <div class="modal-content">
                                            <div class="modal-header bg-info text-white">
                                                <h5 class="modal-title font-weight-bold">Send Test Email</h5>
                                                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                                                    <span aria-hidden="true">&times;</span>
                                                </button>
                                            </div>
                                            <div class="modal-body">
                                                <div class="form-group">
                                                    <label>Recipient Email Address</label>
                                                    <input type="email" class="form-control" name="test_to" placeholder="Enter recipient email">
                                                </div>
                                                <p class="text-muted small">This sends a standard verification email using the settings entered in the form.</p>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">Close</button>
                                                <button type="submit" name="action" value="SEND_TEST_EMAIL" class="btn btn-info font-weight-bold">Send Test Mail</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="card card-navy-brand">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">Configuration Tips</h3>
                            </div>
                            <div class="card-body">
                                <h5><strong>AWS SES Connection</strong></h5>
                                <p class="small text-muted">For AWS SES integration, make sure your domain identity is verified in the SES Console. Common settings:</p>
                                <ul class="small text-muted pl-3">
                                    <li>Host: <code>email-smtp.ap-south-1.amazonaws.com</code></li>
                                    <li>Port: <code>587</code></li>
                                    <li>Encryption: <code>TLS</code></li>
                                </ul>
                                <hr>
                                <h5><strong>Port & SSL Guide</strong></h5>
                                <ul class="small text-muted pl-3">
                                    <li><strong>Port 587 (TLS):</strong> Recommended configuration for secure outgoing mail.</li>
                                    <li><strong>Port 465 (SSL):</strong> Use for explicit SSL connection configurations.</li>
                                    <li><strong>Port 25 / 2525:</strong> Use only if encryption is disabled.</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>
</div>

<!-- REQUIRED SCRIPTS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
</body>
</html>
