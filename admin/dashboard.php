<?php
/**
 * Deccan Finance Limited Onboarding - AdminLTE 3 Onboarding Console
 * Handles application approvals, rejection, and stats.
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

// Session authorization guard
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        header('Content-Type: application/json');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized administrator access.']);
        exit;
    }
    header('Location: login.php');
    exit;
}

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Administrator';
$initials = strtoupper(substr($username, 0, 2));

// Handle Action Requests (Approve/Reject/Edit Profile/Balance) via AJAX/POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'], $_POST['app_id'])) {
    header('Content-Type: application/json');
    $appId = $_POST['app_id'];
    $action = $_POST['action'];

    if ($action === 'APPROVE') {
        $success = update_application_status($appId, 'APPROVED');
        if ($success) {
            log_admin_activity($username, 'APPROVE_APPLICATION', "Approved application: $appId");
        }
        echo json_encode(['success' => $success, 'status' => 'APPROVED']);
    } elseif ($action === 'REJECT') {
        $success = update_application_status($appId, 'REJECTED');
        if ($success) {
            log_admin_activity($username, 'REJECT_APPLICATION', "Rejected application: $appId");
        }
        echo json_encode(['success' => $success, 'status' => 'REJECTED']);
    } elseif ($action === 'UPDATE_PROFILE') {
        $data = [
            'full_name' => trim($_POST['full_name']),
            'email' => trim($_POST['email']),
            'phone' => trim($_POST['phone']),
            'address' => trim($_POST['address']),
            'national_id' => trim($_POST['national_id']),
        ];
        if (isset($_POST['dob'])) $data['dob'] = trim($_POST['dob']);
        if (isset($_POST['gender'])) $data['gender'] = trim($_POST['gender']);
        if (isset($_POST['business_name'])) $data['business_name'] = trim($_POST['business_name']);
        if (isset($_POST['business_reg_no'])) $data['business_reg_no'] = trim($_POST['business_reg_no']);
        if (isset($_POST['expected_turnover'])) $data['expected_turnover'] = trim($_POST['expected_turnover']);

        $success = update_application_profile($appId, $data);
        if ($success) {
            log_admin_activity($username, 'UPDATE_PROFILE', "Updated profile details for application: $appId");
        }
        echo json_encode(['success' => $success]);
    } elseif ($action === 'ADJUST_BALANCE') {
        $amount = (float)$_POST['amount'];
        $type = $_POST['type']; // 'DEPOSIT' or 'WITHDRAW'
        
        // Fetch current application
        $apps = get_applications();
        $app = null;
        foreach ($apps as $a) {
            if ($a['app_id'] === $appId) {
                $app = $a;
                break;
            }
        }
        
        if (!$app) {
            echo json_encode(['success' => false, 'message' => 'Application not found.']);
            exit;
        }
        
        $currentBalance = (float)$app['balance'];
        if ($type === 'DEPOSIT') {
            $newBalance = $currentBalance + $amount;
        } elseif ($type === 'WITHDRAW') {
            if ($amount > $currentBalance) {
                echo json_encode(['success' => false, 'message' => 'Insufficient funds.']);
                exit;
            }
            $newBalance = $currentBalance - $amount;
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid transaction type.']);
            exit;
        }
        
        $success = update_application_balance($appId, $newBalance);
        if ($success) {
            $logDesc = ($type === 'DEPOSIT') ? "Deposited $amount INR (New balance: $newBalance INR) for application: $appId" : "Withdrew $amount INR (New balance: $newBalance INR) for application: $appId";
            log_admin_activity($username, 'ADJUST_BALANCE', $logDesc);
        }
        echo json_encode(['success' => $success, 'new_balance' => $newBalance]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid Action']);
    }
    exit;
}

// Fetch all applications
$applications = get_applications();

// Calculate stats (based on all applications)
$total = count($applications);
$pending = 0;
$approved = 0;
$rejected = 0;

foreach ($applications as $app) {
    if ($app['status'] === 'PENDING') $pending++;
    elseif ($app['status'] === 'APPROVED') $approved++;
    elseif ($app['status'] === 'REJECTED') $rejected++;
}

// Determine filter from query string
$filter = isset($_GET['filter']) ? strtoupper($_GET['filter']) : 'ALL';
if ($filter === 'SAVINGS') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'SAVINGS';
    });
} elseif ($filter === 'CURRENT') {
    $filteredApps = array_filter($applications, function($a) {
        return $a['account_type'] === 'CURRENT';
    });
} else {
    $filteredApps = $applications;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Deccan Finance Limited - Onboarding Console</title>

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
        
        /* Navy Blue Top Navbar */
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

        /* Navy Blue Sidebar Container */
        .main-sidebar {
            background-color: #02144a !important;
        }
        .sidebar-dark-primary .nav-sidebar > .nav-item > .nav-link.active,
        .sidebar-light-primary .nav-sidebar > .nav-item > .nav-link.active {
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
        
        /* Custom KPI Boxes in Brand Colors */
        .small-box.brand-navy {
            background-color: #031f73 !important;
            color: #ffffff !important;
        }
        .small-box.brand-gold {
            background-color: #fecb00 !important;
            color: #031f73 !important;
        }
        .small-box.brand-gold h3, .small-box.brand-gold p {
            color: #031f73 !important;
        }
        
        /* Card Headers matching Navy Theme */
        .card-navy-brand:not(.card-outline) > .card-header {
            background-color: #031f73 !important;
            color: #ffffff !important;
            border-bottom: 2px solid #fecb00;
        }
        
        /* Modal Style Overrides */
        .modal-header-brand {
            background-color: #031f73 !important;
            color: #ffffff !important;
            border-bottom: 4px solid #fecb00 !important;
        }
        .modal-header-brand .modal-title {
            color: #ffffff !important;
        }
        .modal-header-brand .close {
            color: #ffffff !important;
            opacity: 0.8;
        }
        .modal-header-brand .close:hover {
            color: #fecb00 !important;
            opacity: 1;
        }
        
        /* Table styles */
        .table-middle td, .table-middle th {
            vertical-align: middle !important;
        }

        /* Biometrics Viewers */
        .detail-img-frame {
            border: 2px solid #ccd6dd;
            border-radius: 4px;
            padding: 4px;
            background-color: #f8fafc;
            max-width: 100%;
        }
    </style>
</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

    <!-- Top Navbar -->
    <nav class="main-header navbar navbar-expand navbar-dark">
        <!-- Left navbar links -->
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
            </li>
            <li class="nav-item d-none d-sm-inline-block">
                <a href="../index.html" class="nav-link">Main Website</a>
            </li>
        </ul>

        <!-- Right navbar links -->
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
    <!-- /.navbar -->

    <!-- Main Sidebar Container -->
    <aside class="main-sidebar sidebar-dark-primary elevation-4">
        <!-- Brand Logo -->
        <a href="#" class="brand-link">
            <img src="favicon.png" alt="Deccan Finance" class="brand-image img-circle elevation-3" style="opacity: .8">
            <span class="brand-text font-weight-light">Deccan Finance Console</span>
        </a>

        <!-- Sidebar -->
        <div class="sidebar">
            <!-- Sidebar user panel -->
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
                        <a href="dashboard.php" class="nav-link active">
                            <i class="nav-icon fas fa-tachometer-alt"></i>
                            <p>Dashboard</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="settings.php" class="nav-link">
                            <i class="nav-icon fas fa-shield-alt"></i>
                            <p>Security Settings</p>
                        </a>
                    </li>
                    <li class="nav-header">APPLICATIONS</li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=all" class="nav-link <?= $filter === 'ALL' ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-list-ul"></i>
                            <p>All Applications</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=savings" class="nav-link <?= $filter === 'SAVINGS' ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-user-shield"></i>
                            <p>Savings Account</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="dashboard.php?filter=current" class="nav-link <?= $filter === 'CURRENT' ? 'text-warning font-weight-bold' : '' ?>">
                            <i class="nav-icon fas fa-briefcase"></i>
                            <p>Current Account</p>
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
        <!-- /.sidebar -->
    </aside>

    <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <div class="content-header">
            <div class="container-fluid">
                <div class="row mb-2">
                    <div class="col-sm-6">
                        <h1 class="m-0 text-navy font-weight-bold">Onboarding Management</h1>
                    </div>
                    <div class="col-sm-6">
                        <ol class="breadcrumb float-sm-right">
                            <li class="breadcrumb-item"><a href="#">Admin</a></li>
                            <li class="breadcrumb-item active">Applications</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>
        <!-- /.content-header -->

        <!-- Main content -->
        <div class="content">
            <div class="container-fluid">
                
                <!-- Info boxes / KPI Cards -->
                <div class="row">
                    <div class="col-lg-3 col-6">
                        <div class="small-box brand-navy">
                            <div class="inner">
                                <h3><?= $total ?></h3>
                                <p>Total Applications</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-document-text"></i>
                            </div>
                            <a href="dashboard.php?filter=all" class="small-box-footer">View All <i class="fas fa-arrow-circle-right"></i></a>
                        </div>
                    </div>
                    
                    <div class="col-lg-3 col-6">
                        <div class="small-box brand-gold">
                            <div class="inner">
                                <h3><?= $pending ?></h3>
                                <p>In Review (Pending)</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-clock"></i>
                            </div>
                            <a href="#" class="small-box-footer" style="color:#031f73 !important;">Onboarding Checks <i class="fas fa-circle"></i></a>
                        </div>
                    </div>

                    <div class="col-lg-3 col-6">
                        <div class="small-box bg-success">
                            <div class="inner">
                                <h3><?= $approved ?></h3>
                                <p>Approved Accounts</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-checkmark-circled"></i>
                            </div>
                            <a href="#" class="small-box-footer">Onboarded <i class="fas fa-check"></i></a>
                        </div>
                    </div>

                    <div class="col-lg-3 col-6">
                        <div class="small-box bg-danger">
                            <div class="inner">
                                <h3><?= $rejected ?></h3>
                                <p>Rejected / Declined</p>
                            </div>
                            <div class="icon">
                                <i class="ion ion-close-circled"></i>
                            </div>
                            <a href="#" class="small-box-footer">Declined <i class="fas fa-times"></i></a>
                        </div>
                    </div>
                </div>
                <!-- /.row -->

                <!-- Applications Data Table Card -->
                <div class="row">
                    <div class="col-12">
                        <div class="card card-navy-brand card-primary">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">
                                    <i class="fas fa-folder-open mr-2"></i> 
                                    Incoming Requests (Filter: <?= htmlspecialchars($filter) ?>)
                                </h3>
                            </div>
                            <!-- /.card-header -->
                            <div class="card-body p-0">
                                <?php if (empty($filteredApps)): ?>
                                    <div class="text-center py-5 text-muted">
                                        <i class="far fa-folder-open fa-3x mb-3"></i>
                                        <p class="mb-0">No application submissions matching this filter.</p>
                                    </div>
                                <?php else: ?>
                                    <table class="table table-hover table-bordered table-striped table-middle mb-0">
                                        <thead>
                                            <tr>
                                                <th>App ID</th>
                                                <th>Applicant Name</th>
                                                <th>Account Type</th>
                                                <th>Contact Phone</th>
                                                <th>Verification Status</th>
                                                <th>Submission Date</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ($filteredApps as $app): ?>
                                                <tr id="row-<?= $app['app_id'] ?>">
                                                    <td><strong><?= htmlspecialchars($app['app_id']) ?></strong></td>
                                                    <td><?= htmlspecialchars($app['full_name']) ?></td>
                                                    <td>
                                                        <span class="badge badge-info py-1 px-2">
                                                            <i class="fas <?= $app['account_type'] === 'SAVINGS' ? 'fa-user' : 'fa-building' ?> mr-1"></i>
                                                            <?= htmlspecialchars($app['account_type']) ?>
                                                        </span>
                                                    </td>
                                                    <td><?= htmlspecialchars($app['phone']) ?></td>
                                                    <td>
                                                        <?php if ($app['status'] === 'PENDING'): ?>
                                                            <span class="badge badge-warning py-1 px-2 text-dark"><i class="fas fa-sync-alt fa-spin mr-1"></i> PENDING</span>
                                                        <?php elseif ($app['status'] === 'APPROVED'): ?>
                                                            <span class="badge badge-success py-1 px-2"><i class="fas fa-check mr-1"></i> APPROVED</span>
                                                        <?php else: ?>
                                                            <span class="badge badge-danger py-1 px-2"><i class="fas fa-times mr-1"></i> REJECTED</span>
                                                        <?php endif; ?>
                                                    </td>
                                                    <td><?= date('M d, Y H:i', strtotime($app['created_at'])) ?></td>
                                                    <td>
                                                        <button class="btn btn-sm btn-primary" onclick="viewApplication(<?= htmlspecialchars(json_encode($app)) ?>)">
                                                            <i class="fas fa-search-plus mr-1"></i> View & Process
                                                        </button>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                <?php endif; ?>
                            </div>
                            <!-- /.card-body -->
                        </div>
                        <!-- /.card -->
                    </div>
                </div>

            </div><!-- /.container-fluid -->
        </div>
        <!-- /.content -->
    </div>
    <!-- /.content-wrapper -->

    <!-- Main Footer -->
    <footer class="main-footer">
        <div class="float-right d-none d-sm-inline">
            Deccan Finance Limited
        </div>
        <strong>Copyright &copy; 2026 Deccan Finance Limited.</strong> All rights reserved.
    </footer>
</div>
<!-- ./wrapper -->

<!-- Application Review Bootstrap 4 Modal -->
<div class="modal fade" id="reviewModal" tabindex="-1" role="dialog" aria-labelledby="reviewModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header modal-header-brand">
                <h5 class="modal-title font-weight-bold" id="reviewModalLabel"><i class="fas fa-user-check mr-2"></i> Review Application</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body p-4" id="modal-details-body">
                <!-- Injected via JS -->
            </div>
            <div class="modal-footer bg-light" id="modal-footer-actions">
                <button type="button" class="btn btn-warning font-weight-bold mr-auto" id="btn-action-edit"><i class="fas fa-edit mr-1"></i> Edit Profile</button>
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-danger font-weight-bold" id="btn-action-reject"><i class="fas fa-user-slash mr-1"></i> Reject Applicant</button>
                <button type="button" class="btn btn-success font-weight-bold" id="btn-action-approve"><i class="fas fa-user-plus mr-1"></i> Approve Account</button>
            </div>
        </div>
    </div>
</div>

<!-- Edit Profile Bootstrap 4 Modal -->
<div class="modal fade" id="editProfileModal" tabindex="-1" role="dialog" aria-labelledby="editProfileModalLabel" aria-hidden="true" style="z-index: 1060;">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header modal-header-brand" style="background-color: #031f73 !important; color: white !important; border-bottom: 4px solid #fecb00 !important;">
                <h5 class="modal-title font-weight-bold" id="editProfileModalLabel"><i class="fas fa-edit mr-2"></i> Edit Profile Details</h5>
                <button type="button" class="close text-white" onclick="$('#editProfileModal').modal('hide')" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="edit-profile-form">
                <div class="modal-body p-4">
                    <div class="form-group">
                        <label for="edit-full-name" class="small font-weight-bold text-navy">Full Name</label>
                        <input type="text" class="form-control form-control-sm" id="edit-full-name" name="full_name" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-email" class="small font-weight-bold text-navy">Email Address</label>
                        <input type="email" class="form-control form-control-sm" id="edit-email" name="email" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-phone" class="small font-weight-bold text-navy">Phone Number</label>
                        <input type="text" class="form-control form-control-sm" id="edit-phone" name="phone" required>
                    </div>
                    <div class="form-group">
                        <label for="edit-address" class="small font-weight-bold text-navy">Mailing Address</label>
                        <textarea class="form-control form-control-sm" id="edit-address" name="address" rows="2" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="edit-national-id" class="small font-weight-bold text-navy">PAN / ID Number</label>
                        <input type="text" class="form-control form-control-sm" id="edit-national-id" name="national_id" required>
                    </div>
                    
                    <!-- Dynamic fields based on account type -->
                    <div id="edit-savings-fields" style="display:none;">
                        <div class="form-group">
                            <label for="edit-dob" class="small font-weight-bold text-navy">Date of Birth</label>
                            <input type="date" class="form-control form-control-sm" id="edit-dob" name="dob">
                        </div>
                        <div class="form-group">
                            <label for="edit-gender" class="small font-weight-bold text-navy">Gender</label>
                            <select class="form-control form-control-sm" id="edit-gender" name="gender">
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>
                    
                    <div id="edit-current-fields" style="display:none;">
                        <div class="form-group">
                            <label for="edit-business-name" class="small font-weight-bold text-navy">Business Name</label>
                            <input type="text" class="form-control form-control-sm" id="edit-business-name" name="business_name">
                        </div>
                        <div class="form-group">
                            <label for="edit-business-reg-no" class="small font-weight-bold text-navy">GST / Registration No.</label>
                            <input type="text" class="form-control form-control-sm" id="edit-business-reg-no" name="business_reg_no">
                        </div>
                        <div class="form-group">
                            <label for="edit-expected-turnover" class="small font-weight-bold text-navy">Expected Turnover (INR)</label>
                            <input type="number" step="0.01" class="form-control form-control-sm" id="edit-expected-turnover" name="expected_turnover">
                        </div>
                    </div>
                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary btn-sm" onclick="$('#editProfileModal').modal('hide')">Cancel</button>
                    <button type="submit" class="btn btn-warning btn-sm font-weight-bold" style="color: #031f73;"><i class="fas fa-save mr-1"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- REQUIRED SCRIPTS -->
<!-- jQuery -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<!-- Bootstrap 4 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<!-- AdminLTE App -->
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
    let currentAppId = null;
    let activeApp = null;

    function viewApplication(app) {
        currentAppId = app.app_id;
        activeApp = app;
        
        let statusBadge = '';
        if (app.status === 'PENDING') {
            statusBadge = '<span class="badge badge-warning text-dark"><i class="fas fa-sync-alt fa-spin mr-1"></i> PENDING</span>';
        } else if (app.status === 'APPROVED') {
            statusBadge = '<span class="badge badge-success"><i class="fas fa-check mr-1"></i> APPROVED</span>';
        } else {
            statusBadge = '<span class="badge badge-danger"><i class="fas fa-times mr-1"></i> REJECTED</span>';
        }

        // Build HTML details structure
        let html = `
            <div class="row mb-4">
                <div class="col-sm-6">
                    <h5 class="text-navy font-weight-bold">Application ID: ${app.app_id}</h5>
                </div>
                <div class="col-sm-6 text-sm-right">
                    ${statusBadge}
                </div>
            </div>
            
            <div class="row">
                <!-- Data Fields Column -->
                <div class="col-md-7">
                    <div class="card card-outline card-primary">
                        <div class="card-body p-0">
                            <table class="table table-striped table-sm mb-0">
                                <tbody>
                                    <tr>
                                        <td class="font-weight-bold pl-3" width="40%">Account Type</td>
                                        <td>${app.account_type}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Full Name</td>
                                        <td>${escapeHtml(app.full_name)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Email Address</td>
                                        <td>${escapeHtml(app.email)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Phone Number</td>
                                        <td>${escapeHtml(app.phone)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Mailing Address</td>
                                        <td>${escapeHtml(app.address)}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">PAN / ID No.</td>
                                        <td>${escapeHtml(app.national_id)}</td>
                                    </tr>
        `;

        if (app.account_type === 'SAVINGS') {
            html += `
                                    <tr>
                                        <td class="font-weight-bold pl-3">Date of Birth</td>
                                        <td>${escapeHtml(app.dob || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Gender</td>
                                        <td>${escapeHtml(app.gender || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Initial Deposit</td>
                                        <td>${app.initial_deposit ? parseFloat(app.initial_deposit).toLocaleString() + ' INR' : '0.00 INR'}</td>
                                    </tr>
            `;
        } else {
            html += `
                                    <tr>
                                        <td class="font-weight-bold pl-3">Business Name</td>
                                        <td>${escapeHtml(app.business_name || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">GST / Reg No.</td>
                                        <td>${escapeHtml(app.business_reg_no || 'N/A')}</td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold pl-3">Turnover Volume</td>
                                        <td>${app.expected_turnover ? parseFloat(app.expected_turnover).toLocaleString() + ' INR' : 'N/A'}</td>
                                    </tr>
            `;
        }

        html += `
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Photo & Signature Column -->
                <div class="col-md-5">
                    <div class="card card-outline card-warning">
                        <div class="card-body text-center p-3">
                            <h6 class="font-weight-bold text-navy mb-2"><i class="fas fa-camera mr-1"></i> Portrait Photo Capture</h6>
                            <img src="../${app.photo_path}" class="detail-img-frame rounded-circle mb-3" style="width: 130px; height: 130px; object-fit: cover;">
                            
                            <h6 class="font-weight-bold text-navy mb-2"><i class="fas fa-signature mr-1"></i> Drawn Signature</h6>
                            <img src="../${app.signature_path}" class="detail-img-frame" style="width: 100%; height: 90px; object-fit: contain;">
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- KYC Documents Capture Row -->
            <div class="row mt-3">
                <div class="col-12">
                    <div class="card card-outline card-info">
                        <div class="card-body p-3">
                            <h6 class="font-weight-bold text-navy mb-3"><i class="fas fa-file-contract mr-1"></i> Live KYC Documents (Front)</h6>
                            <div class="row text-center">
                                <div class="col-sm-6 mb-2">
                                    <div class="font-weight-bold text-muted small mb-1">PAN Card / Business ID</div>
                                    <img src="../${app.doc_pan_path}" class="detail-img-frame" style="width: 100%; height: 180px; object-fit: cover;">
                                </div>
                                <div class="col-sm-6">
                                    <div class="font-weight-bold text-muted small mb-1">Aadhaar Card / Address Proof</div>
                                    <img src="../${app.doc_aadhaar_path}" class="detail-img-frame" style="width: 100%; height: 180px; object-fit: cover;">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        if (app.status === 'APPROVED') {
            html += `
            <!-- Financial Balance Management Block -->
            <div class="row mt-3">
                <div class="col-12">
                    <div class="card card-outline card-success">
                        <div class="card-header py-2">
                            <h6 class="card-title font-weight-bold text-success m-0"><i class="fas fa-wallet mr-1"></i> Balance Management</h6>
                        </div>
                        <div class="card-body p-3">
                            <div class="row align-items-center">
                                <div class="col-sm-5 mb-2 mb-sm-0">
                                    <span class="text-muted d-block small">CURRENT BALANCE</span>
                                    <span class="h4 font-weight-bold text-navy mb-0" id="current-balance-display">${parseFloat(app.balance || 0).toLocaleString()} INR</span>
                                </div>
                                <div class="col-sm-7">
                                    <div class="form-inline justify-content-sm-end">
                                        <div class="input-group input-group-sm mr-2 mb-2 mb-sm-0">
                                            <input type="number" step="0.01" min="0.01" class="form-control" id="adjust-amount" placeholder="Amount (INR)" required style="height: 31px; border-radius: 4px;">
                                        </div>
                                        <button type="button" class="btn btn-sm btn-success font-weight-bold mr-1" id="btn-balance-add"><i class="fas fa-plus mr-1"></i> Add</button>
                                        <button type="button" class="btn btn-sm btn-danger font-weight-bold" id="btn-balance-deduct"><i class="fas fa-minus mr-1"></i> Deduct</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            `;
        }

        document.getElementById('modal-details-body').innerHTML = html;

        // Set up balance adjustment buttons
        const btnBalanceAdd = document.getElementById('btn-balance-add');
        const btnBalanceDeduct = document.getElementById('btn-balance-deduct');
        if (btnBalanceAdd && btnBalanceDeduct) {
            const handleAdjustment = (type) => {
                const amountInput = document.getElementById('adjust-amount');
                const amount = parseFloat(amountInput.value);
                if (isNaN(amount) || amount <= 0) {
                    alert('Please enter a valid amount greater than 0.');
                    return;
                }
                
                const formData = new FormData();
                formData.append('app_id', currentAppId);
                formData.append('action', 'ADJUST_BALANCE');
                formData.append('amount', amount);
                formData.append('type', type);
                
                fetch('dashboard.php', {
                    method: 'POST',
                    body: formData
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        alert(`Successfully processed: ${type === 'DEPOSIT' ? 'Added' : 'Deducted'} ${amount} INR`);
                        // Update display in modal
                        document.getElementById('current-balance-display').textContent = parseFloat(data.new_balance).toLocaleString() + ' INR';
                        // Update balance in local object representation
                        activeApp.balance = data.new_balance;
                        // Clear input field
                        amountInput.value = '';
                    } else {
                        alert('Transaction failed: ' + (data.message || 'Unknown error'));
                    }
                })
                .catch(err => {
                    alert('Network error: Transaction could not be completed.');
                });
            };
            
            btnBalanceAdd.addEventListener('click', () => handleAdjustment('DEPOSIT'));
            btnBalanceDeduct.addEventListener('click', () => handleAdjustment('WITHDRAW'));
        }

        // Toggle action buttons in footer based on PENDING status
        const footer = document.getElementById('modal-footer-actions');
        const btnReject = document.getElementById('btn-action-reject');
        const btnApprove = document.getElementById('btn-action-approve');
        
        if (app.status === 'PENDING') {
            btnReject.style.display = 'inline-block';
            btnApprove.style.display = 'inline-block';
        } else {
            btnReject.style.display = 'none';
            btnApprove.style.display = 'none';
        }

        // Show Modal
        $('#reviewModal').modal('show');
    }

    // Modal Actions handlers
    document.getElementById('btn-action-approve').addEventListener('click', () => {
        updateApplicationStatus(currentAppId, 'APPROVE');
    });

    document.getElementById('btn-action-reject').addEventListener('click', () => {
        updateApplicationStatus(currentAppId, 'REJECT');
    });

    document.getElementById('btn-action-edit').addEventListener('click', () => {
        if (!activeApp) return;
        
        // Populate form fields
        document.getElementById('edit-full-name').value = activeApp.full_name;
        document.getElementById('edit-email').value = activeApp.email;
        document.getElementById('edit-phone').value = activeApp.phone;
        document.getElementById('edit-address').value = activeApp.address;
        document.getElementById('edit-national-id').value = activeApp.national_id;
        
        if (activeApp.account_type === 'SAVINGS') {
            document.getElementById('edit-savings-fields').style.display = 'block';
            document.getElementById('edit-current-fields').style.display = 'none';
            document.getElementById('edit-dob').value = activeApp.dob || '';
            document.getElementById('edit-gender').value = activeApp.gender || 'Male';
        } else {
            document.getElementById('edit-savings-fields').style.display = 'none';
            document.getElementById('edit-current-fields').style.display = 'block';
            document.getElementById('edit-business-name').value = activeApp.business_name || '';
            document.getElementById('edit-business-reg-no').value = activeApp.business_reg_no || '';
            document.getElementById('edit-expected-turnover').value = activeApp.expected_turnover || '';
        }
        
        // Show Edit Modal
        $('#editProfileModal').modal('show');
    });

    document.getElementById('edit-profile-form').addEventListener('submit', (e) => {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        formData.append('app_id', activeApp.app_id);
        formData.append('action', 'UPDATE_PROFILE');
        
        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                $('#editProfileModal').modal('hide');
                $('#reviewModal').modal('hide');
                alert('Profile details updated successfully!');
                window.location.reload();
            } else {
                alert('Error updating profile: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(err => {
            alert('Server error: Failed to save changes.');
        });
    });

    function updateApplicationStatus(appId, action) {
        if (!confirm(`Are you sure you want to ${action.toLowerCase()} application ${appId}?`)) {
            return;
        }

        const formData = new FormData();
        formData.append('app_id', appId);
        formData.append('action', action);

        fetch('dashboard.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                $('#reviewModal').modal('hide');
                // Refresh to reload stats and tables
                window.location.reload();
            } else {
                alert('Error updating application: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(err => {
            alert('Server error: Failed to complete request.');
        });
    }

    function escapeHtml(str) {
        if (!str) return '';
        return str
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }
</script>
</body>
</html>
