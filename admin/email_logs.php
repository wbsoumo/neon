<?php
/**
 * Deccan Finance - Outgoing Email Logs
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

// Handle AJAX Resend Action
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'resend') {
    header('Content-Type: application/json');
    $log_id = isset($_POST['log_id']) ? (int)$_POST['log_id'] : 0;
    if ($log_id > 0) {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT * FROM email_logs WHERE id = :id LIMIT 1");
            $stmt->execute([':id' => $log_id]);
            $log = $stmt->fetch();
            if ($log) {
                $cc = !empty($log['cc']) ? explode(', ', $log['cc']) : [];
                $bcc = !empty($log['bcc']) ? explode(', ', $log['bcc']) : [];
                
                $res = EmailService::sendMail($log['recipient'], $log['subject'], $log['body'], [], $cc, $bcc);
                
                if ($res['success']) {
                    echo json_encode(['success' => true, 'message' => 'Email resent successfully.']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Failed to resend: ' . $res['message']]);
                }
            } else {
                echo json_encode(['success' => false, 'message' => 'Email log entry not found.']);
            }
        } catch (\Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid email log ID.']);
    }
    exit;
}

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Administrator';
$initials = strtoupper(substr($username, 0, 2));

// Initialize filters
$search_recipient = isset($_GET['recipient']) ? trim($_GET['recipient']) : '';
$search_subject = isset($_GET['subject']) ? trim($_GET['subject']) : '';
$date_from = isset($_GET['date_from']) ? trim($_GET['date_from']) : '';
$date_to = isset($_GET['date_to']) ? trim($_GET['date_to']) : '';

// Build PDO query with dynamic filters
try {
    $pdo = get_db_connection();
    
    $query = "SELECT * FROM email_logs WHERE 1=1";
    $params = [];

    if (!empty($search_recipient)) {
        $query .= " AND (recipient LIKE :recipient OR cc LIKE :cc OR bcc LIKE :bcc)";
        $params[':recipient'] = '%' . $search_recipient . '%';
        $params[':cc'] = '%' . $search_recipient . '%';
        $params[':bcc'] = '%' . $search_recipient . '%';
    }

    if (!empty($search_subject)) {
        $query .= " AND subject LIKE :subject";
        $params[':subject'] = '%' . $search_subject . '%';
    }

    if (!empty($date_from)) {
        $query .= " AND DATE(created_at) >= :date_from";
        $params[':date_from'] = $date_from;
    }

    if (!empty($date_to)) {
        $query .= " AND DATE(created_at) <= :date_to";
        $params[':date_to'] = $date_to;
    }

    $query .= " ORDER BY id DESC";
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $logs = $stmt->fetchAll();
} catch (\Exception $e) {
    $logs = [];
    $errorMsg = "Failed to load logs: " . $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Email Logs</title>
    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">

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
                        <a href="send_email.php" class="nav-link">
                            <i class="nav-icon fas fa-paper-plane"></i>
                            <p>Send Email</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="email_logs.php" class="nav-link active">
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
                        <h1 class="m-0 text-navy font-weight-bold">Outgoing Email Logs</h1>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <section class="content">
            <div class="container-fluid">
                
                <!-- Filter Card -->
                <div class="card card-outline card-primary mb-4">
                    <div class="card-header">
                        <h3 class="card-title font-weight-bold text-navy"><i class="fas fa-search mr-1"></i> Filter Logs</h3>
                    </div>
                    <form action="email_logs.php" method="GET">
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>Recipient / CC / BCC</label>
                                        <input type="text" class="form-control" name="recipient" 
                                               value="<?= htmlspecialchars($search_recipient) ?>" placeholder="Search recipient...">
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>Subject</label>
                                        <input type="text" class="form-control" name="subject" 
                                               value="<?= htmlspecialchars($search_subject) ?>" placeholder="Search subject...">
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>Date From</label>
                                        <input type="date" class="form-control" name="date_from" 
                                               value="<?= htmlspecialchars($date_from) ?>">
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>Date To</label>
                                        <input type="date" class="form-control" name="date_to" 
                                               value="<?= htmlspecialchars($date_to) ?>">
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="card-footer bg-light text-right">
                            <a href="email_logs.php" class="btn btn-secondary font-weight-bold mr-2">Reset Filters</a>
                            <button type="submit" class="btn btn-primary font-weight-bold px-4">Apply Filters</button>
                        </div>
                    </form>
                </div>

                <!-- Logs Table Card -->
                <div class="card card-navy-brand">
                    <div class="card-header">
                        <h3 class="card-title font-weight-bold">Email Transmissions</h3>
                    </div>
                    <div class="card-body p-0 table-responsive" style="max-height: 600px; overflow-y: auto;">
                        <table class="table table-hover table-striped text-nowrap">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Recipient</th>
                                    <th>Subject</th>
                                    <th>Sender</th>
                                    <th>Date & Time</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (empty($logs)): ?>
                                    <tr>
                                        <td colspan="7" class="text-center text-muted py-4">No email logs found matching criteria.</td>
                                    </tr>
                                <?php else: ?>
                                    <?php foreach ($logs as $log): ?>
                                        <tr>
                                            <td><?= htmlspecialchars($log['id']) ?></td>
                                            <td style="max-width: 250px; overflow: hidden; text-overflow: ellipsis;">
                                                <strong>To:</strong> <?= htmlspecialchars($log['recipient']) ?>
                                                <?php if (!empty($log['cc'])): ?>
                                                    <br><small class="text-muted"><strong>CC:</strong> <?= htmlspecialchars($log['cc']) ?></small>
                                                <?php endif; ?>
                                                <?php if (!empty($log['bcc'])): ?>
                                                    <br><small class="text-muted"><strong>BCC:</strong> <?= htmlspecialchars($log['bcc']) ?></small>
                                                <?php endif; ?>
                                            </td>
                                            <td style="max-width: 300px; overflow: hidden; text-overflow: ellipsis; font-weight: 500;">
                                                <?= htmlspecialchars($log['subject']) ?>
                                            </td>
                                            <td><?= htmlspecialchars($log['sender']) ?></td>
                                            <td><?= htmlspecialchars(date('d M Y h:i A', strtotime($log['created_at']))) ?></td>
                                            <td>
                                                <?php if ($log['status'] === 'SUCCESS'): ?>
                                                    <span class="badge badge-success px-2 py-1"><i class="fas fa-check-circle mr-1"></i> Success</span>
                                                <?php else: ?>
                                                    <span class="badge badge-danger px-2 py-1"><i class="fas fa-times-circle mr-1"></i> Failed</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <button type="button" class="btn btn-sm btn-info font-weight-bold view-email-btn mr-1" 
                                                        data-id="<?= htmlspecialchars($log['id']) ?>"
                                                        data-recipient="<?= htmlspecialchars($log['recipient']) ?>"
                                                        data-subject="<?= htmlspecialchars($log['subject']) ?>"
                                                        data-sender="<?= htmlspecialchars($log['sender']) ?>"
                                                        data-time="<?= htmlspecialchars(date('d M Y h:i A', strtotime($log['created_at']))) ?>"
                                                        data-status="<?= htmlspecialchars($log['status']) ?>"
                                                        data-error="<?= htmlspecialchars($log['error_message'] ?? '') ?>"
                                                        data-body="<?= htmlspecialchars($log['body']) ?>">
                                                    <i class="fas fa-eye mr-1"></i> View Details
                                                </button>
                                                <button type="button" class="btn btn-sm btn-primary font-weight-bold resend-btn" 
                                                        data-id="<?= htmlspecialchars($log['id']) ?>">
                                                    <i class="fas fa-paper-plane mr-1"></i> Resend
                                                </button>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    </div>
</div>

<!-- Email Detail Modal -->
<div class="modal fade" id="emailDetailModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header bg-navy text-white" style="background-color: #031f73 !important;">
                <h5 class="modal-title font-weight-bold" id="modalSubject">Email Details</h5>
                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div id="modalAlert" class="alert d-none mb-3"></div>
                <div class="row mb-3">
                    <div class="col-md-6">
                        <strong>Sender:</strong> <span id="modalSender"></span><br>
                        <strong>Recipient:</strong> <span id="modalRecipient"></span>
                    </div>
                    <div class="col-md-6 text-md-right">
                        <strong>Date:</strong> <span id="modalTime"></span><br>
                        <strong>Status:</strong> <span id="modalStatusBadge"></span>
                    </div>
                </div>
                
                <div class="card card-outline card-danger d-none" id="modalErrorCard">
                    <div class="card-header bg-danger-light">
                        <strong class="text-danger"><i class="fas fa-exclamation-circle mr-1"></i> SMTP Error Details</strong>
                    </div>
                    <div class="card-body py-2">
                        <code id="modalErrorMessage"></code>
                    </div>
                </div>
                
                <div class="form-group mt-3">
                    <label class="border-bottom pb-1 d-block font-weight-bold">Message Content</label>
                    <div class="border rounded p-3 bg-light" style="max-height: 400px; overflow-y: auto;" id="modalBody">
                        <!-- Loaded Dynamically -->
                    </div>
                </div>
            </div>
            <div class="modal-footer justify-content-between">
                <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary font-weight-bold resend-email-btn" id="modalResendBtn">
                    <i class="fas fa-paper-plane mr-1"></i> Resend Email
                </button>
            </div>
        </div>
    </div>
</div>

<!-- REQUIRED SCRIPTS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
    $(document).ready(function() {
        // Open details modal
        $('.view-email-btn').on('click', function() {
            var btn = $(this);
            $('#modalSubject').text(btn.data('subject'));
            $('#modalSender').text(btn.data('sender'));
            $('#modalRecipient').text(btn.data('recipient'));
            $('#modalTime').text(btn.data('time'));
            
            // Set resend button log id
            $('#modalResendBtn').data('id', btn.data('id'));
            
            // Reset alert container
            $('#modalAlert').addClass('d-none').removeClass('alert-success alert-danger').text('');
            
            var status = btn.data('status');
            var badgeHtml = '';
            if (status === 'SUCCESS') {
                badgeHtml = '<span class="badge badge-success px-2 py-1">Success</span>';
                $('#modalErrorCard').addClass('d-none');
            } else {
                badgeHtml = '<span class="badge badge-danger px-2 py-1">Failed</span>';
                $('#modalErrorMessage').text(btn.data('error'));
                $('#modalErrorCard').removeClass('d-none');
            }
            $('#modalStatusBadge').html(badgeHtml);
            
            // Render HTML email body safely
            var rawHtml = btn.data('body');
            $('#modalBody').html(rawHtml);
            
            $('#emailDetailModal').modal('show');
        });

        // Resend email from modal
        $('#modalResendBtn').on('click', function() {
            var btn = $(this);
            var logId = btn.data('id');
            if (!logId) return;

            if (!confirm('Are you sure you want to resend this email?')) {
                return;
            }

            btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin mr-1"></i> Resending...');
            
            var alertDiv = $('#modalAlert');
            alertDiv.addClass('d-none').removeClass('alert-success alert-danger').text('');

            $.ajax({
                url: 'email_logs.php',
                method: 'POST',
                data: { action: 'resend', log_id: logId },
                dataType: 'json',
                success: function(response) {
                    btn.prop('disabled', false).html('<i class="fas fa-paper-plane mr-1"></i> Resend Email');
                    if (response.success) {
                        alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                        setTimeout(function() {
                            location.reload();
                        }, 1200);
                    } else {
                        alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                    }
                },
                error: function() {
                    btn.prop('disabled', false).html('<i class="fas fa-paper-plane mr-1"></i> Resend Email');
                    alertDiv.text('An error occurred while resending the email.').addClass('alert-danger').removeClass('d-none');
                }
            });
        });

        // Resend email from table row directly
        $('.resend-btn').on('click', function(e) {
            e.stopPropagation();
            var btn = $(this);
            var logId = btn.data('id');
            
            if (!confirm('Are you sure you want to resend this email?')) {
                return;
            }
            
            btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i>');
            
            $.ajax({
                url: 'email_logs.php',
                method: 'POST',
                data: { action: 'resend', log_id: logId },
                dataType: 'json',
                success: function(response) {
                    if (response.success) {
                        alert(response.message);
                        location.reload();
                    } else {
                        alert(response.message);
                        btn.prop('disabled', false).html('<i class="fas fa-paper-plane mr-1"></i> Resend');
                    }
                },
                error: function() {
                    alert('An error occurred while resending the email.');
                    btn.prop('disabled', false).html('<i class="fas fa-paper-plane mr-1"></i> Resend');
                }
            });
        });
    });
</script>
</body>
</html>
