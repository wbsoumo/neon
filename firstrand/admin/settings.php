<?php
/**
 * Deccan Finance Limited Onboarding - Admin Settings & Security Console
 * Handles IP Whitelisting additions/deletions and logs activity audits.
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

// Session authorization guard
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: login.php');
    exit;
}

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Administrator';
$initials = strtoupper(substr($username, 0, 2));

$error = '';
$success_msg = '';

// Handle Whitelist Actions
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'ADD_IP') {
        $ip = trim($_POST['ip']);
        if (empty($ip)) {
            $error = 'IP Address field cannot be empty.';
        } elseif (!filter_var($ip, FILTER_VALIDATE_IP)) {
            $error = 'Please enter a valid IPv4 or IPv6 address.';
        } else {
            $res = add_whitelisted_ip($ip);
            if ($res) {
                log_admin_activity($username, 'ADD_IP_WHITELIST', "Added IP to whitelist: $ip");
                $success_msg = "Successfully whitelisted IP address: $ip";
            } else {
                $error = 'Failed to whitelist IP address. It may already be whitelisted.';
            }
        }
    } elseif ($action === 'DELETE_IP') {
        $ip = trim($_POST['ip']);
        $clientIp = get_client_ip();

        if ($ip === $clientIp) {
            $error = 'You cannot remove your own active client IP (' . htmlspecialchars($ip) . ') to prevent lockout.';
        } else {
            $res = delete_whitelisted_ip($ip);
            if ($res) {
                log_admin_activity($username, 'REMOVE_IP_WHITELIST', "Removed IP from whitelist: $ip");
                $success_msg = "Successfully removed IP address: $ip";
            } else {
                $error = 'Failed to remove IP address.';
            }
        }
    }
}

// Fetch records
$whitelistedIps = get_whitelisted_ips();
$logs = get_admin_logs();
$myIp = get_client_ip();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Deccan Finance Limited - Security Settings</title>

    <!-- Google Font: Source Sans Pro -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- Ionicons -->
    <link rel="stylesheet" href="https://code.ionicframework.com/ionicons/2.0.1/css/ionicons.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <!-- Brand Favicon -->
    <link rel="icon" type="image/png" href="favicon.png">

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
        .table-middle td, .table-middle th {
            vertical-align: middle !important;
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
        <a href="#" class="brand-link">
            <img src="favicon.png" alt="Deccan Finance" class="brand-image img-circle elevation-3" style="opacity: .8">
            <span class="brand-text font-weight-light">Deccan Finance Console</span>
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
                        <a href="settings.php" class="nav-link active">
                            <i class="nav-icon fas fa-shield-alt"></i>
                            <p>Security Settings</p>
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
                        <h1 class="m-0 text-navy font-weight-bold">Security Settings & Logs</h1>
                    </div>
                    <div class="col-sm-6">
                        <ol class="breadcrumb float-sm-right">
                            <li class="breadcrumb-item"><a href="dashboard.php">Admin</a></li>
                            <li class="breadcrumb-item active">Security Settings</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main content -->
        <div class="content">
            <div class="container-fluid">
                
                <?php if (!empty($error)): ?>
                    <div class="alert alert-danger alert-dismissible">
                        <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                        <i class="icon fas fa-ban"></i> <?= htmlspecialchars($error) ?>
                    </div>
                <?php endif; ?>

                <?php if (!empty($success_msg)): ?>
                    <div class="alert alert-success alert-dismissible">
                        <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                        <i class="icon fas fa-check"></i> <?= htmlspecialchars($success_msg) ?>
                    </div>
                <?php endif; ?>

                <div class="row">
                    <!-- IP Whitelist Card -->
                    <div class="col-md-5">
                        <div class="card card-navy-brand card-primary">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-list-alt mr-2"></i> IP Whitelist Manager</h3>
                            </div>
                            <div class="card-body">
                                <p class="small text-muted">Your active client IP address is: <span class="badge badge-info"><?= htmlspecialchars($myIp) ?></span>. You cannot delete this IP to prevent lockout.</p>
                                
                                <form action="settings.php" method="post" class="mb-4">
                                    <input type="hidden" name="action" value="ADD_IP">
                                    <div class="input-group input-group-sm">
                                        <input type="text" name="ip" class="form-control" placeholder="Enter IP address (e.g. 192.168.1.1)" required>
                                        <span class="input-group-append">
                                            <button type="submit" class="btn btn-success font-weight-bold"><i class="fas fa-plus mr-1"></i> Whitelist</button>
                                        </span>
                                    </div>
                                </form>

                                <table class="table table-hover table-bordered table-striped table-sm table-middle mb-0">
                                    <thead>
                                        <tr>
                                            <th>Whitelisted IP</th>
                                            <th class="text-center" style="width: 100px;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach ($whitelistedIps as $ip): ?>
                                            <tr>
                                                <td>
                                                    <strong><?= htmlspecialchars($ip) ?></strong>
                                                    <?php if ($ip === $myIp): ?>
                                                        <span class="badge badge-pill badge-primary ml-1">My Active IP</span>
                                                    <?php endif; ?>
                                                </td>
                                                <td class="text-center">
                                                    <form action="settings.php" method="post" style="display:inline;" onsubmit="return confirm('Are you sure you want to remove this IP from the whitelist?');">
                                                        <input type="hidden" name="action" value="DELETE_IP">
                                                        <input type="hidden" name="ip" value="<?= htmlspecialchars($ip) ?>">
                                                        <button type="submit" class="btn btn-xs btn-danger font-weight-bold" <?= ($ip === $myIp) ? 'disabled' : '' ?>>
                                                            <i class="fas fa-trash-alt mr-1"></i> Delete
                                                        </button>
                                                    </form>
                                                </td>
                                            </tr>
                                        <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Logs Card -->
                    <div class="col-md-7">
                        <div class="card card-navy-brand card-secondary">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-history mr-2"></i> Audit & Activity Logs</h3>
                            </div>
                            <div class="card-body p-0" style="max-height: 520px; overflow-y: auto;">
                                <table class="table table-hover table-striped table-sm table-middle mb-0">
                                    <thead class="bg-light" style="position: sticky; top: 0; z-index: 10;">
                                        <tr>
                                            <th>User</th>
                                            <th>Action</th>
                                            <th>Details</th>
                                            <th>IP Address</th>
                                            <th>Time</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php if (empty($logs)): ?>
                                            <tr>
                                                <td colspan="5" class="text-center py-4 text-muted">No activity logs recorded.</td>
                                            </tr>
                                        <?php else: ?>
                                            <?php foreach ($logs as $log): ?>
                                                <tr>
                                                    <td><strong><?= htmlspecialchars($log['username'] ?: 'System') ?></strong></td>
                                                    <td>
                                                        <?php
                                                        $badgeColor = 'badge-secondary';
                                                        if (strpos($log['action'], 'LOGIN_SUCCESS') !== false) $badgeColor = 'badge-success';
                                                        elseif (strpos($log['action'], 'LOGIN_FAILED') !== false) $badgeColor = 'badge-danger';
                                                        elseif (strpos($log['action'], 'ADJUST_BALANCE') !== false) $badgeColor = 'badge-info';
                                                        elseif (strpos($log['action'], 'APPROVE') !== false) $badgeColor = 'badge-success';
                                                        elseif (strpos($log['action'], 'REJECT') !== false) $badgeColor = 'badge-danger';
                                                        elseif (strpos($log['action'], 'ADD_IP_WHITELIST') !== false) $badgeColor = 'badge-warning';
                                                        ?>
                                                        <span class="badge <?= $badgeColor ?>"><?= htmlspecialchars($log['action']) ?></span>
                                                    </td>
                                                    <td class="small"><?= htmlspecialchars($log['details']) ?></td>
                                                    <td><span class="small font-weight-bold"><?= htmlspecialchars($log['ip_address']) ?></span></td>
                                                    <td class="small text-nowrap"><?= date('M d, Y H:i', strtotime($log['created_at'])) ?></td>
                                                </tr>
                                            <?php endforeach; ?>
                                        <?php endif; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <!-- Main Footer -->
    <footer class="main-footer">
        <div class="float-right d-none d-sm-inline">
            Deccan Finance Limited
        </div>
        <strong>Copyright &copy; 2026 Deccan Finance Limited.</strong> All rights reserved.
    </footer>
</div>

<!-- REQUIRED SCRIPTS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
</body>
</html>
