<?php
/**
 * Deccan Finance - Admin Settings & Security Console
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
    } elseif ($action === 'UPDATE_FIREBASE_CREDENTIALS') {
        $jsonStr = isset($_POST['firebase_json']) ? trim($_POST['firebase_json']) : '';
        if (empty($jsonStr)) {
            $error = 'Credentials JSON cannot be empty.';
        } else {
            $data = json_decode($jsonStr, true);
            if (!$data || empty($data['project_id']) || empty($data['private_key']) || empty($data['client_email'])) {
                $error = 'Invalid Service Account JSON. Must contain project_id, private_key, and client_email.';
            } else {
                $configDir = '../api/config/';
                if (!is_dir($configDir)) {
                    mkdir($configDir, 0777, true);
                }
                $res = file_put_contents($configDir . 'firebase_service_account.json', $jsonStr);
                if ($res !== false) {
                    log_admin_activity($username, 'UPDATE_FIREBASE_CREDENTIALS', 'Updated Firebase Service Account Credentials');
                    $success_msg = 'Firebase Service Account Credentials updated successfully.';
                } else {
                    $error = 'Failed to write credentials file. Check permissions of api/config/ directory.';
                }
            }
        }
    } elseif ($action === 'UPDATE_PAYOUT_CREDENTIALS') {
        $mid = isset($_POST['bharat_mid']) ? trim($_POST['bharat_mid']) : '';
        $key = isset($_POST['bharat_key']) ? trim($_POST['bharat_key']) : '';
        if (empty($mid) || empty($key)) {
            $error = 'Both Merchant ID and Merchant Key are required.';
        } else {
            $res = save_payout_credentials($mid, $key);
            if ($res) {
                log_admin_activity($username, 'UPDATE_PAYOUT_CREDENTIALS', 'Updated Bharat4u Payout API credentials');
                $success_msg = 'Bharat4u Payout credentials updated successfully.';
            } else {
                $error = 'Failed to write credentials file. Check permissions of api/config/ directory.';
            }
        }
    } elseif ($action === 'UPDATE_ACTIVE_PAYOUT_PROVIDER') {
        $provider = isset($_POST['active_provider']) ? trim($_POST['active_provider']) : 'bharat4u';
        if ($provider !== 'bharat4u' && $provider !== 'jiopay') {
            $error = 'Invalid payout provider selected.';
        } else {
            $res = save_active_payout_provider($provider);
            if ($res) {
                log_admin_activity($username, 'UPDATE_ACTIVE_PAYOUT_PROVIDER', 'Updated active payout provider to: ' . $provider);
                $success_msg = 'Active payout provider updated to ' . ($provider === 'jiopay' ? 'JioPay' : 'Bharat4u') . ' successfully.';
            } else {
                $error = 'Failed to save active provider setting.';
            }
        }
    } elseif ($action === 'UPDATE_MAINTENANCE_MODE') {
        $enabled = isset($_POST['maintenance_mode']) ? (int)$_POST['maintenance_mode'] : 0;
        $res = save_maintenance_mode($enabled);
        if ($res !== false) {
            log_admin_activity($username, 'UPDATE_MAINTENANCE_MODE', 'Updated front page display status. Maintenance Mode: ' . ($enabled ? 'ON (Show 404)' : 'OFF (Show Front Page)'));
            $success_msg = 'Homepage display status updated successfully.';
        } else {
            $error = 'Failed to update homepage display status.';
        }
    } elseif ($action === 'UPDATE_JIOPAY_CREDENTIALS') {
        $mid = isset($_POST['jiopay_mid']) ? trim($_POST['jiopay_mid']) : '';
        $key = isset($_POST['jiopay_key']) ? trim($_POST['jiopay_key']) : '';
        $entityId = isset($_POST['jiopay_entity_id']) ? trim($_POST['jiopay_entity_id']) : '';
        $customerId = isset($_POST['jiopay_customer_id']) ? trim($_POST['jiopay_customer_id']) : '';
        if (empty($mid) || empty($key) || empty($entityId) || empty($customerId)) {
            $error = 'All fields (Merchant ID, Merchant Key, Entity ID, and Customer ID) are required for JioPay.';
        } else {
            $res = save_jiopay_credentials($mid, $key, $entityId, $customerId);
            if ($res) {
                log_admin_activity($username, 'UPDATE_JIOPAY_CREDENTIALS', 'Updated JioPay Payout API credentials');
                $success_msg = 'JioPay Payout credentials updated successfully.';
            } else {
                $error = 'Failed to write credentials file. Check permissions of api/config/ directory.';
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
    <title>Neon Finance - Security Settings</title>

    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- Ionicons -->
    <link rel="stylesheet" href="https://code.ionicframework.com/ionicons/2.0.1/css/ionicons.min.css">
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
                        <a href="settings.php" class="nav-link active">
                            <i class="nav-icon fas fa-shield-alt"></i>
                            <p>Security Settings</p>
                        </a>
                    </li>
                    <li class="nav-header">APPLICATIONS</li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=all" class="nav-link">
                            <i class="nav-icon fas fa-list-ul"></i>
                            <p>All Applications</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=savings" class="nav-link">
                            <i class="nav-icon fas fa-user-shield"></i>
                            <p>Savings Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=current" class="nav-link">
                            <i class="nav-icon fas fa-briefcase"></i>
                            <p>Current Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=nri" class="nav-link">
                            <i class="nav-icon fas fa-globe"></i>
                            <p>NRI Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=corporate" class="nav-link">
                            <i class="nav-icon fas fa-building"></i>
                            <p>Corporate Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=beneficiary_approvals" class="nav-link">
                            <i class="nav-icon fas fa-user-check"></i>
                            <p>Beneficiary Approvals</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=failed_payouts" class="nav-link">
                            <i class="nav-icon fas fa-exclamation-triangle"></i>
                            <p>Failed Payouts Queue</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="notifications.php" class="nav-link">
                            <i class="nav-icon fas fa-bell"></i>
                            <p>Send Notifications</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="compliance.php" class="nav-link">
                            <i class="nav-icon fas fa-file-contract"></i>
                            <p>Compliance Manager</p>
                        </a>
                    </li>
                    <li class="nav-header">TESTING</li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=p2p_test" class="nav-link">
                            <i class="nav-icon fas fa-exchange-alt"></i>
                            <p>P2P Transfer Test</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?page=payout_test" class="nav-link">
                            <i class="nav-icon fas fa-wallet"></i>
                            <p>Payout Transfer Test</p>
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

                        <!-- Firebase Configuration Card -->
                        <div class="card card-default mt-4">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-key mr-2"></i> Firebase Credentials Configuration</h3>
                                <div class="card-tools">
                                    <button type="button" class="btn btn-tool" data-card-widget="collapse">
                                        <i class="fas fa-minus"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-body">
                                <?php
                                $creds = get_firebase_credentials();
                                if ($creds):
                                ?>
                                    <div class="alert alert-success p-2 small">
                                        <i class="fas fa-check-circle mr-1"></i> Configured: <strong><?= htmlspecialchars($creds['project_id']) ?></strong>
                                        <br><span class="text-muted">Client Email: <?= htmlspecialchars($creds['client_email']) ?></span>
                                    </div>
                                <?php else: ?>
                                    <div class="alert alert-warning p-2 small text-dark">
                                        <i class="fas fa-exclamation-triangle mr-1"></i> Not Configured. Dispatches will default to simulation mode.
                                    </div>
                                <?php endif; ?>

                                <form action="settings.php" method="post">
                                    <input type="hidden" name="action" value="UPDATE_FIREBASE_CREDENTIALS">
                                    <div class="form-group">
                                        <label class="font-weight-bold">Firebase Service Account Private Key JSON</label>
                                        <textarea name="firebase_json" class="form-control text-monospace" rows="8" placeholder='{ "type": "service_account", ... }' required style="font-size: 90%;"><?= $creds ? htmlspecialchars(json_encode($creds, JSON_PRETTY_PRINT)) : '' ?></textarea>
                                    </div>
                                    <button type="submit" class="btn btn-secondary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Save Service Account Credentials
                                    </button>
                                </form>
                                <p class="small text-muted mt-2 mb-0" style="font-size: 85%;">
                                    Generate a new key JSON from: <strong>Firebase Console > Project Settings > Service Accounts > Generate New Private Key</strong>. Paste the entire JSON file contents here.
                                </p>
                            </div>
                        </div>

                        <!-- Bharat4u Payout Configuration Card -->
                        <div class="card card-default mt-4">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-wallet mr-2"></i> Bharat4u Payout Credentials</h3>
                                <div class="card-tools">
                                    <button type="button" class="btn btn-tool" data-card-widget="collapse">
                                        <i class="fas fa-minus"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-body">
                                <?php
                                $payoutCreds = get_payout_credentials();
                                if (!empty($payoutCreds['bharat_mid']) && !empty($payoutCreds['bharat_key'])):
                                ?>
                                    <div class="alert alert-success p-2 small mb-3">
                                        <i class="fas fa-check-circle mr-1"></i> Configured Mid: <strong><?= htmlspecialchars($payoutCreds['bharat_mid']) ?></strong>
                                    </div>
                                <?php else: ?>
                                    <div class="alert alert-warning p-2 small text-dark mb-3">
                                        <i class="fas fa-exclamation-triangle mr-1"></i> Not Configured. Payouts will default to simulation mode.
                                    </div>
                                <?php endif; ?>

                                <form action="settings.php" method="post">
                                    <input type="hidden" name="action" value="UPDATE_PAYOUT_CREDENTIALS">
                                    <div class="form-group">
                                        <label class="font-weight-bold">Merchant ID (Mid)</label>
                                        <input type="text" name="bharat_mid" class="form-control" value="<?= htmlspecialchars($payoutCreds['bharat_mid']) ?>" placeholder="e.g. BHARAT507571014" required>
                                    </div>
                                    <div class="form-group">
                                        <label class="font-weight-bold">Merchant Key</label>
                                        <input type="text" name="bharat_key" class="form-control" value="<?= htmlspecialchars($payoutCreds['bharat_key']) ?>" placeholder="e.g. 8749ed748061" required>
                                    </div>
                                    <button type="submit" class="btn btn-secondary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Save Payout Credentials
                                    </button>
                                </form>
                            </div>
                        </div>

                        <!-- Active Payout Method Selection Card -->
                        <div class="card card-default mt-4">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-toggle-on mr-2"></i> Active Payout Method</h3>
                                <div class="card-tools">
                                    <button type="button" class="btn btn-tool" data-card-widget="collapse">
                                        <i class="fas fa-minus"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-body">
                                <?php
                                $activeProvider = get_active_payout_provider();
                                ?>
                                <div class="alert alert-info p-2 small mb-3">
                                    Currently Routing Payouts via: <strong><?= $activeProvider === 'jiopay' ? 'JioPay Payout' : 'Bharat4u Payout' ?></strong>
                                </div>

                                <form action="settings.php" method="post">
                                    <input type="hidden" name="action" value="UPDATE_ACTIVE_PAYOUT_PROVIDER">
                                    <div class="form-group">
                                        <label class="font-weight-bold">Select Active Payout Method</label>
                                        <select name="active_provider" class="form-control" required>
                                            <option value="bharat4u" <?= $activeProvider === 'bharat4u' ? 'selected' : '' ?>>Bharat4u Payout</option>
                                            <option value="jiopay" <?= $activeProvider === 'jiopay' ? 'selected' : '' ?>>JioPay Payout</option>
                                        </select>
                                    </div>
                                    <button type="submit" class="btn btn-primary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Switch Payout Method
                                    </button>
                                </form>
                            </div>
                        </div>

                        <!-- Front Page Display Mode Card -->
                        <div class="card card-default mt-4">
                            <div class="card-header bg-navy text-white" style="background-color: #031f73 !important; border-bottom: 2px solid #fecb00;">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-power-off mr-2"></i> Front Page Display Mode</h3>
                                <div class="card-tools">
                                    <button type="button" class="btn btn-tool text-white" data-card-widget="collapse">
                                        <i class="fas fa-minus"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-body">
                                <?php
                                $maintenanceMode = get_maintenance_mode();
                                ?>
                                <div class="alert alert-<?= $maintenanceMode ? 'warning' : 'success' ?> p-2 small mb-3">
                                    Current Status: <strong><?= $maintenanceMode ? '404 Maintenance Mode (Homepage returns 404 error)' : 'Live / Normal (Homepage shows normal index.html)' ?></strong>
                                </div>

                                <form action="settings.php" method="post">
                                    <input type="hidden" name="action" value="UPDATE_MAINTENANCE_MODE">
                                    <div class="form-group">
                                        <label class="font-weight-bold">Select Homepage Mode</label>
                                        <select name="maintenance_mode" class="form-control" required>
                                            <option value="0" <?= !$maintenanceMode ? 'selected' : '' ?>>Normal (Show Front Page)</option>
                                            <option value="1" <?= $maintenanceMode ? 'selected' : '' ?>>Maintenance (Show 404 Error)</option>
                                        </select>
                                    </div>
                                    <button type="submit" class="btn btn-primary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Save Homepage Status
                                    </button>
                                </form>
                            </div>
                        </div>

                        <!-- JioPay Payout Configuration Card -->
                        <div class="card card-default mt-4">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold"><i class="fas fa-wallet mr-2"></i> JioPay Payout Credentials</h3>
                                <div class="card-tools">
                                    <button type="button" class="btn btn-tool" data-card-widget="collapse">
                                        <i class="fas fa-minus"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-body">
                                <?php
                                $jioCreds = get_jiopay_credentials();
                                if (!empty($jioCreds['jiopay_mid']) && !empty($jioCreds['jiopay_key']) && !empty($jioCreds['entity_id']) && !empty($jioCreds['customer_id'])):
                                ?>
                                    <div class="alert alert-success p-2 small mb-3">
                                        <i class="fas fa-check-circle mr-1"></i> Configured Mid: <strong><?= htmlspecialchars($jioCreds['jiopay_mid']) ?></strong>
                                        <br><span class="text-muted">Entity ID: <?= htmlspecialchars($jioCreds['entity_id']) ?></span>
                                        <br><span class="text-muted">Customer ID: <?= htmlspecialchars($jioCreds['customer_id']) ?></span>
                                    </div>
                                <?php else: ?>
                                    <div class="alert alert-warning p-2 small text-dark mb-3">
                                        <i class="fas fa-exclamation-triangle mr-1"></i> Not Fully Configured. Payouts will default to simulation mode.
                                    </div>
                                <?php endif; ?>

                                <form action="settings.php" method="post">
                                    <input type="hidden" name="action" value="UPDATE_JIOPAY_CREDENTIALS">
                                    <div class="form-group">
                                        <label class="font-weight-bold">Merchant ID (Mid)</label>
                                        <input type="text" name="jiopay_mid" class="form-control" value="<?= htmlspecialchars($jioCreds['jiopay_mid']) ?>" placeholder="e.g. JIOPAY507571014" required>
                                    </div>
                                    <div class="form-group">
                                        <label class="font-weight-bold">Merchant Key</label>
                                        <input type="text" name="jiopay_key" class="form-control" value="<?= htmlspecialchars($jioCreds['jiopay_key']) ?>" placeholder="e.g. 9849ed748062" required>
                                    </div>
                                    <div class="form-group">
                                        <label class="font-weight-bold">Entity ID</label>
                                        <input type="text" name="jiopay_entity_id" class="form-control" value="<?= htmlspecialchars($jioCreds['entity_id'] ?? '') ?>" placeholder="e.g. 3173ad0e-xxxx-xxxxxx-9c57830b2d07" required>
                                    </div>
                                    <div class="form-group">
                                        <label class="font-weight-bold">Customer ID</label>
                                        <input type="text" name="jiopay_customer_id" class="form-control" value="<?= htmlspecialchars($jioCreds['customer_id'] ?? '') ?>" placeholder="e.g. CUST10001" required>
                                    </div>
                                    <button type="submit" class="btn btn-secondary font-weight-bold">
                                        <i class="fas fa-save mr-1"></i> Save Payout Credentials
                                    </button>
                                </form>
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
        <strong>Copyright &copy; 2026 Deccan Finance.</strong> All rights reserved.
    </footer>
</div>

<!-- REQUIRED SCRIPTS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
</body>
</html>
