<?php
/**
 * Deccan Finance - Send Email (Admin Email Composer)
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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Validate CSRF
    $csrf = isset($_POST['csrf_token']) ? $_POST['csrf_token'] : '';
    if (!hash_equals($_SESSION['csrf_token'], $csrf)) {
        $message = "Invalid CSRF security token.";
        $messageType = "danger";
    } else {
        $to = isset($_POST['to']) ? trim($_POST['to']) : '';
        $cc = isset($_POST['cc']) ? trim($_POST['cc']) : '';
        $bcc = isset($_POST['bcc']) ? trim($_POST['bcc']) : '';
        $subject = isset($_POST['subject']) ? trim($_POST['subject']) : '';
        $body = isset($_POST['body']) ? trim($_POST['body']) : '';

        if (empty($to) || empty($subject) || empty($body)) {
            $message = "Recipient, Subject, and Email Body are required fields.";
            $messageType = "warning";
        } else {
            // Process Attachments
            $attachments = [];
            if (isset($_FILES['attachments']) && !empty($_FILES['attachments']['name'][0])) {
                $files = $_FILES['attachments'];
                for ($i = 0; $i < count($files['name']); $i++) {
                    if ($files['error'][$i] === UPLOAD_ERR_OK) {
                        $attachments[] = [
                            'path' => $files['tmp_name'][$i],
                            'name' => $files['name'][$i]
                        ];
                    }
                }
            }

            // Send Email
            $result = EmailService::sendMail($to, $subject, $body, $attachments, $cc, $bcc);
            
            if ($result['success']) {
                $message = "Email sent successfully! Transaction logged.";
                $messageType = "success";
            } else {
                $message = "Failed to send email. Error: " . $result['message'];
                $messageType = "danger";
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Email Composer</title>
    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">
    <!-- Summernote Rich Text Editor -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/summernote/0.8.20/summernote-bs4.min.css">
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
        .note-editor {
            border-radius: 4px;
            border: 1px solid #ced4da !important;
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
            <img src="../assets/7PzcYdFs3fE3HNk64pDrpdmsSOk.svg" alt="Neon Logo" onerror="this.src='../logo.png';" style="height: 32px; width: auto;">
            <span class="brand-text" style="font-weight: 800; color: #ffffff;"><span style="color: #00f2fe;">neon</span> finance</span>
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
                        <a href="email_settings.php" class="nav-link">
                            <i class="nav-icon fas fa-envelope-open-text"></i>
                            <p>Email Settings</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="send_email.php" class="nav-link active">
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
                        <h1 class="m-0 text-navy font-weight-bold">Compose & Send Email</h1>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <section class="content">
            <div class="container-fluid">

                <?php if (!empty($message)): ?>
                    <div class="alert alert-<?= $messageType ?> alert-dismissible fade show" role="alert">
                        <?= $message ?>
                        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                <?php endif; ?>

                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-navy-brand">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">Email Composer</h3>
                            </div>
                            <form action="send_email.php" method="POST" enctype="multipart/form-data">
                                <input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">
                                
                                <div class="card-body">
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">Recipient Email</label>
                                        <div class="col-sm-10">
                                            <input type="text" class="form-control" name="to" required 
                                                   placeholder="recipient@example.com (comma separated for multiple)">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">CC</label>
                                        <div class="col-sm-10">
                                            <input type="text" class="form-control" name="cc" 
                                                   placeholder="cc1@example.com, cc2@example.com">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">BCC</label>
                                        <div class="col-sm-10">
                                            <input type="text" class="form-control" name="bcc" 
                                                   placeholder="bcc@example.com">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">Subject</label>
                                        <div class="col-sm-10">
                                            <input type="text" class="form-control" name="subject" required 
                                                   placeholder="Enter email subject">
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">Attachments</label>
                                        <div class="col-sm-10">
                                            <div class="custom-file">
                                                <input type="file" class="custom-file-input" name="attachments[]" id="attachments" multiple>
                                                <label class="custom-file-label" for="attachments">Choose file(s)</label>
                                            </div>
                                            <small class="text-muted">Select multiple files if needed.</small>
                                        </div>
                                    </div>
                                    <div class="form-group row">
                                        <label class="col-sm-2 col-form-label">Message Body</label>
                                        <div class="col-sm-10">
                                            <textarea class="form-control" name="body" id="summernote" required></textarea>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-footer bg-light text-right">
                                    <button type="submit" class="btn btn-primary font-weight-bold px-4">
                                        <i class="fas fa-paper-plane mr-2"></i> Send Email
                                    </button>
                                </div>
                            </form>
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
<!-- Summernote JS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/summernote/0.8.20/summernote-bs4.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
    $(document).ready(function() {
        // Initialize Summernote Rich Text Editor
        $('#summernote').summernote({
            height: 350,
            placeholder: 'Type your rich text message here...',
            toolbar: [
                ['style', ['style']],
                ['font', ['bold', 'underline', 'clear']],
                ['color', ['color']],
                ['para', ['ul', 'ol', 'paragraph']],
                ['table', ['table']],
                ['insert', ['link', 'picture', 'video']],
                ['view', ['fullscreen', 'codeview', 'help']]
            ]
        });

        // Show selected file names
        $('.custom-file-input').on('change', function() {
            var files = $(this)[0].files;
            var fileNames = [];
            for (var i = 0; $file = files[i]; i++) {
                fileNames.push($file.name);
            }
            $(this).next('.custom-file-label').html(fileNames.join(', ') || 'Choose file(s)');
        });
    });
</script>
</body>
</html>
