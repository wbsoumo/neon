<?php
/**
 * Deccan Finance - Admin User Profiles & Controls
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

$pdo = get_db_connection();

// --- AJAX ENDPOINTS ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    $action = $_POST['action'];

    if ($action === 'update_profile') {
        $appId = trim($_POST['app_id'] ?? '');
        $name = trim($_POST['full_name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $phone = trim($_POST['phone'] ?? '');

        if (empty($appId) || empty($name) || empty($email) || empty($phone)) {
            echo json_encode(['success' => false, 'message' => 'All basic profile fields are required.']);
            exit;
        }

        try {
            $stmt = $pdo->prepare("UPDATE applications SET full_name = :full_name, email = :email, phone = :phone WHERE app_id = :app_id");
            $stmt->execute([
                ':full_name' => $name,
                ':email' => $email,
                ':phone' => $phone,
                ':app_id' => $appId
            ]);
            log_admin_activity($username, 'UPDATE_USER_PROFILE', "Updated details for $appId. Name=$name, Email=$email, Mobile=$phone");
            echo json_encode(['success' => true, 'message' => 'Profile updated successfully.']);
        } catch (\Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'add_balance') {
        $appId = trim($_POST['app_id'] ?? '');
        $amount = (float)($_POST['amount'] ?? 0);
        $utrId = trim($_POST['utr_id'] ?? '');
        $balanceAction = trim($_POST['balance_action'] ?? 'add');
        $remarks = trim($_POST['remarks'] ?? '');

        if (empty($appId) || $amount <= 0) {
            echo json_encode(['success' => false, 'message' => 'Invalid application ID or amount.']);
            exit;
        }

        try {
            // Find account number
            $account = get_account_by_app_id($appId);
            if (!$account) {
                echo json_encode(['success' => false, 'message' => 'No approved account found for this application. Cannot adjust balance.']);
                exit;
            }
            $accountNumber = $account['account_number'];

            if (empty($utrId)) {
                $attempts = 0;
                do {
                    $utrId = '';
                    for ($i = 0; $i < 12; $i++) {
                        $utrId .= mt_rand(0, 9);
                    }
                    $stmt = $pdo->prepare("SELECT COUNT(*) FROM transactions WHERE utr_id = :utr_id");
                    $stmt->execute([':utr_id' => $utrId]);
                    $exists = $stmt->fetchColumn() > 0;
                    $attempts++;
                } while ($exists && $attempts < 10);
            }

            if ($balanceAction === 'deduct') {
                // Fetch current balance to prevent overdraft unless intended
                $stmtBal = $pdo->prepare("SELECT balance FROM applications WHERE app_id = :app_id");
                $stmtBal->execute([':app_id' => $appId]);
                $currentBalance = (float)$stmtBal->fetchColumn();
                if ($currentBalance < $amount) {
                    echo json_encode(['success' => false, 'message' => "Insufficient balance. User only has ₹" . number_format($currentBalance, 2)]);
                    exit;
                }

                $pdo->beginTransaction();
                // Deduct balance
                $stmtUpdate = $pdo->prepare("UPDATE applications SET balance = balance - :amount WHERE app_id = :app_id");
                $stmtUpdate->execute([':amount' => $amount, ':app_id' => $appId]);

                // Log transaction (debit from user to SYSTEM)
                record_transaction($appId, 'SYSTEM', $amount, 'BANK_TRANSFER', $utrId, 'SUCCESS', null, null, null, null, $remarks);
                $pdo->commit();

                // Notify user via Email (debit alert)
                try {
                    EmailService::sendNotificationEmail($accountNumber, 'debit', $amount, $utrId, $remarks ?: 'Account Adjustment (Debit)');
                } catch (\Exception $mailEx) {
                    error_log("Failed to send balance deduction email: " . $mailEx->getMessage());
                }

                // Notify user via Push Notification
                try {
                    $notifyTitle = "Account Debited";
                    $notifyBody = "Your account has been debited by " . number_format($amount, 2) . " INR." . ($remarks ? " Remarks: " . $remarks . "." : "") . " UTR: " . $utrId;
                    send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (\Exception $notifEx) {
                    error_log("Failed to send balance deduction notification: " . $notifEx->getMessage());
                }

                log_admin_activity($username, 'DEDUCT_USER_BALANCE', "Deducted ₹$amount from user $appId (Acct: $accountNumber) with UTR $utrId. Remarks: $remarks");
                echo json_encode(['success' => true, 'message' => "Successfully deducted ₹" . number_format($amount, 2) . " with UTR $utrId."]);
            } else {
                $pdo->beginTransaction();
                // Update balance
                $stmtUpdate = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :app_id");
                $stmtUpdate->execute([':amount' => $amount, ':app_id' => $appId]);

                // Log transaction (credit to user from SYSTEM)
                record_transaction('SYSTEM', $accountNumber, $amount, 'BANK_TRANSFER', $utrId, 'SUCCESS', null, null, null, null, $remarks);
                $pdo->commit();

                // Notify user via Email (credit alert)
                try {
                    EmailService::sendNotificationEmail($accountNumber, 'credit', $amount, $utrId, $remarks ?: 'Account Adjustment (Credit)');
                } catch (\Exception $mailEx) {
                    error_log("Failed to send balance addition email: " . $mailEx->getMessage());
                }

                // Notify user via Push Notification
                try {
                    $notifyTitle = "Account Credited";
                    $notifyBody = "Your account has been credited by " . number_format($amount, 2) . " INR." . ($remarks ? " Remarks: " . $remarks . "." : "") . " UTR: " . $utrId;
                    send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (\Exception $notifEx) {
                    error_log("Failed to send balance addition notification: " . $notifEx->getMessage());
                }

                log_admin_activity($username, 'ADD_USER_BALANCE', "Deposited ₹$amount to user $appId (Acct: $accountNumber) with UTR $utrId. Remarks: $remarks");
                echo json_encode(['success' => true, 'message' => "Successfully deposited ₹" . number_format($amount, 2) . " with UTR $utrId."]);
            }
        } catch (\Exception $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            echo json_encode(['success' => false, 'message' => 'Transaction failed: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'change_password') {
        $appId = trim($_POST['app_id'] ?? '');
        $newPassword = trim($_POST['new_password'] ?? '');

        if (empty($appId) || empty($newPassword)) {
            echo json_encode(['success' => false, 'message' => 'Password cannot be empty.']);
            exit;
        }

        if (strlen($newPassword) < 6) {
            echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters long.']);
            exit;
        }

        try {
            $stmt = $pdo->prepare("UPDATE applications SET password_hash = :password WHERE app_id = :app_id");
            $stmt->execute([
                ':password' => $newPassword,
                ':app_id' => $appId
            ]);
            log_admin_activity($username, 'CHANGE_USER_PASSWORD', "Updated login password for $appId");
            echo json_encode(['success' => true, 'message' => 'Password changed successfully.']);
        } catch (\Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'change_mpin') {
        $appId = trim($_POST['app_id'] ?? '');
        $newMpin = trim($_POST['new_mpin'] ?? '');

        if (empty($appId) || empty($newMpin)) {
            echo json_encode(['success' => false, 'message' => 'MPIN cannot be empty.']);
            exit;
        }

        if (!preg_match('/^\d{6}$/', $newMpin)) {
            echo json_encode(['success' => false, 'message' => 'Invalid MPIN format. Must be exactly 6 digits.']);
            exit;
        }

        try {
            $account = get_account_by_app_id($appId);
            if (!$account) {
                echo json_encode(['success' => false, 'message' => 'No activated account found. Cannot set MPIN.']);
                exit;
            }

            $mpinHash = password_hash($newMpin, PASSWORD_DEFAULT);
            set_account_mpin($appId, $mpinHash);

            log_admin_activity($username, 'CHANGE_USER_MPIN', "Reset MPIN for $appId");
            echo json_encode(['success' => true, 'message' => 'MPIN changed successfully.']);
        } catch (\Exception $e) {
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        }
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action'])) {
    header('Content-Type: application/json');
    $action = $_GET['action'];

    if ($action === 'search') {
        $query = trim($_GET['query'] ?? '');
        if (strlen($query) < 2) {
            echo json_encode([]);
            exit;
        }

        try {
            $stmt = $pdo->prepare("SELECT app_id, full_name, email, phone, status FROM applications WHERE full_name LIKE :q OR email LIKE :q OR phone LIKE :q LIMIT 10");
            $stmt->execute([':q' => "%$query%"]);
            echo json_encode($stmt->fetchAll());
        } catch (\Exception $e) {
            echo json_encode([]);
        }
        exit;
    }

    if ($action === 'get_details') {
        $appId = trim($_GET['app_id'] ?? '');
        if (empty($appId)) {
            echo json_encode(['success' => false, 'message' => 'Missing application ID.']);
            exit;
        }

        try {
            $application = get_application_by_id($appId);
            if (!$application) {
                echo json_encode(['success' => false, 'message' => 'User profile not found.']);
                exit;
            }

            $account = get_account_by_app_id($appId);
            $accountNumber = $account ? $account['account_number'] : 'N/A';

            // Get transactions
            $transactions = get_transactions_by_app_id($appId);

            // Get activity logs
            $stmtLogs = $pdo->prepare("SELECT ip_address, status, details, created_at FROM user_login_logs WHERE app_id = :app_id ORDER BY created_at DESC LIMIT 30");
            $stmtLogs->execute([':app_id' => $appId]);
            $logs = $stmtLogs->fetchAll();

            echo json_encode([
                'success' => true,
                'application' => $application,
                'account_number' => $accountNumber,
                'transactions' => $transactions,
                'activities' => $logs
            ]);
        } catch (\Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - User Profile Manager</title>
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
        .search-results-box {
            position: absolute;
            width: 100%;
            z-index: 1000;
            background: white;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            max-height: 250px;
            overflow-y: auto;
        }
        .search-item {
            padding: 10px 15px;
            cursor: pointer;
            border-bottom: 1px solid #f0f0f0;
            transition: background 0.2s;
        }
        .search-item:hover {
            background: #f8f9ff;
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
                        <a href="user_profiles.php" class="nav-link active">
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
                        <h1 class="m-0 text-navy font-weight-bold">User Profile Manager</h1>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <section class="content col-12">
            <div class="container-fluid">
                
                <!-- Search Card -->
                <div class="card card-outline card-primary mb-4 position-relative">
                    <div class="card-header">
                        <h3 class="card-title font-weight-bold text-navy"><i class="fas fa-search mr-1"></i> Search Customer</h3>
                    </div>
                    <div class="card-body">
                        <div class="input-group">
                            <input type="text" id="searchInput" class="form-control form-control-lg" placeholder="Type user's name, email, or mobile number to search..." autocomplete="off">
                            <div class="input-group-append">
                                <span class="input-group-text"><i class="fas fa-user-search"></i></span>
                            </div>
                        </div>
                        <div id="searchResults" class="search-results-box d-none"></div>
                    </div>
                </div>

                <!-- Info Alert when no user is selected -->
                <div id="noUserAlert" class="alert alert-info py-4">
                    <h5><i class="icon fas fa-info"></i> Please Select a User</h5>
                    <p class="mb-0">Use the search box above to locate a customer profile. Once selected, all management tools, history logs, and balance credentials will load here.</p>
                </div>

                <!-- User Management Section (Hidden initially) -->
                <div id="userManagerContainer" class="d-none">
                    
                    <!-- Basic Information Row -->
                    <div class="row">
                        <!-- Edit details -->
                        <div class="col-md-6">
                            <div class="card card-navy-brand">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold"><i class="fas fa-user-edit mr-1"></i> Edit Basic Profile</h3>
                                </div>
                                <form id="basicProfileForm">
                                    <input type="hidden" name="action" value="update_profile">
                                    <input type="hidden" name="app_id" id="profileAppId">
                                    <div class="card-body">
                                        <div id="profileAlert" class="alert d-none"></div>
                                        
                                        <div class="form-group">
                                            <label>Full Name</label>
                                            <input type="text" class="form-control" name="full_name" id="profileName" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Email Address</label>
                                            <input type="email" class="form-control" name="email" id="profileEmail" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Mobile Number</label>
                                            <input type="text" class="form-control" name="phone" id="profilePhone" required>
                                        </div>
                                    </div>
                                    <div class="card-footer text-right">
                                        <button type="submit" class="btn btn-success font-weight-bold"><i class="fas fa-save mr-1"></i> Save Profile Details</button>
                                    </div>
                                </form>
                            </div>
                        </div>

                        <!-- Add Balance & Details -->
                        <div class="col-md-6">
                            <div class="card card-navy-brand">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold"><i class="fas fa-wallet mr-1"></i> Balance Management</h3>
                                </div>
                                <form id="addBalanceForm">
                                    <input type="hidden" name="action" value="add_balance">
                                    <input type="hidden" name="app_id" id="balanceAppId">
                                    <div class="card-body">
                                        <div id="balanceAlert" class="alert d-none"></div>
                                        
                                        <div class="row">
                                            <div class="col-6">
                                                <label class="text-muted">Account Number</label>
                                                <h4 class="font-weight-bold text-navy" id="displayAccountNumber">-</h4>
                                            </div>
                                            <div class="col-6 text-right">
                                                <label class="text-muted">Current Balance</label>
                                                <h4 class="font-weight-bold text-success" id="displayBalance">₹0.00</h4>
                                            </div>
                                        </div>
                                        <hr class="mt-2 mb-3">

                                        <div class="form-group">
                                            <label>Select Action</label>
                                            <select class="form-control" name="balance_action" id="balanceAction" required>
                                                <option value="add">Add Balance (Deposit / Credit)</option>
                                                <option value="deduct">Deduct Balance (Withdrawal / Debit)</option>
                                            </select>
                                        </div>
                                        
                                        <div class="form-group">
                                            <label id="amountLabel">Amount to Add (INR)</label>
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text">₹</span>
                                                </div>
                                                <input type="number" class="form-control" name="amount" min="1" step="0.01" placeholder="Enter amount..." required>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label>Custom UTR Number <small class="text-muted">(Optional - leave blank to auto-generate)</small></label>
                                            <input type="text" class="form-control" name="utr_id" placeholder="e.g. 612345678901" maxlength="25">
                                        </div>
                                        <div class="form-group mb-0">
                                            <label>Remarks / Description <small class="text-muted">(Optional - will show in notifications & transaction history)</small></label>
                                            <input type="text" class="form-control" name="remarks" placeholder="e.g. Deposit for Invoice #123" maxlength="255">
                                        </div>
                                    </div>
                                    <div class="card-footer text-right">
                                        <button type="submit" id="depositBtn" class="btn btn-primary font-weight-bold"><i class="fas fa-plus mr-1"></i> Add Balance</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- Security & Credentials Row -->
                    <div class="row mt-2">
                        <!-- Password Modifier -->
                        <div class="col-md-6">
                            <div class="card card-navy-brand">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold"><i class="fas fa-key mr-1"></i> Change Password</h3>
                                </div>
                                <form id="changePasswordForm">
                                    <input type="hidden" name="action" value="change_password">
                                    <input type="hidden" name="app_id" id="passwordAppId">
                                    <div class="card-body">
                                        <div id="passwordAlert" class="alert d-none"></div>
                                        
                                        <div class="form-group mb-0">
                                            <label>Password</label>
                                            <input type="text" class="form-control" name="new_password" id="profilePassword" placeholder="Enter password (min 6 characters)" required>
                                            <small class="text-muted d-block mt-1">This box shows the user's current password in plaintext as configured.</small>
                                        </div>
                                    </div>
                                    <div class="card-footer text-right">
                                        <button type="submit" class="btn btn-warning font-weight-bold text-navy"><i class="fas fa-lock-open mr-1"></i> Update Password</button>
                                    </div>
                                </form>
                            </div>
                        </div>

                        <!-- MPIN Modifier -->
                        <div class="col-md-6">
                            <div class="card card-navy-brand">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold"><i class="fas fa-shield-alt mr-1"></i> Reset Transaction MPIN</h3>
                                </div>
                                <form id="changeMpinForm">
                                    <input type="hidden" name="action" value="change_mpin">
                                    <input type="hidden" name="app_id" id="mpinAppId">
                                    <div class="card-body">
                                        <div id="mpinAlert" class="alert d-none"></div>
                                        
                                        <div class="form-group mb-0">
                                            <label>New 6-Digit MPIN</label>
                                            <input type="text" class="form-control" name="new_mpin" placeholder="Enter new 6-digit numeric MPIN" maxlength="6" pattern="\d{6}" required>
                                            <small class="text-muted d-block mt-1">MPINs are stored hashed securely. Entering a new one will override their current transaction MPIN.</small>
                                        </div>
                                    </div>
                                    <div class="card-footer text-right">
                                        <button type="submit" id="mpinBtn" class="btn btn-danger font-weight-bold"><i class="fas fa-fingerprint mr-1"></i> Update MPIN</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- Transaction Status Row -->
                    <div class="row mt-2">
                        <div class="col-md-12">
                            <div class="card card-navy-brand">
                                <div class="card-header">
                                    <h3 class="card-title font-weight-bold"><i class="fas fa-ban mr-1"></i> Transaction Status Manager</h3>
                                </div>
                                <form id="toggleTxForm">
                                    <input type="hidden" name="app_id" id="txAppId">
                                    <div class="card-body">
                                        <div id="txStatusAlert" class="alert d-none"></div>
                                        
                                        <div class="row">
                                            <div class="col-md-4">
                                                <div class="form-group">
                                                    <label>Transaction Status</label>
                                                    <select class="form-control" name="status" id="txStatusSelect" required>
                                                        <option value="on">Enabled (ON)</option>
                                                        <option value="off">Disabled (OFF)</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="col-md-8">
                                                <div class="form-group">
                                                    <label>Disabled Custom Message / Error Message</label>
                                                    <input type="text" class="form-control" name="message" id="txStatusMessage" placeholder="e.g. Account under security review. Outgoing transfers suspended.">
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group mb-0">
                                            <label>Remarks / Notification Details <small class="text-muted">(Optional - sent in email & push alert details)</small></label>
                                            <input type="text" class="form-control" name="remarks" id="txStatusRemarks" placeholder="e.g. Suspended due to suspicious AML pattern">
                                        </div>
                                        <div class="form-group mt-3 mb-0">
                                            <label>Failed Transaction Email Customizer <small class="text-muted">(Inner HTML/Text Template)</small></label>
                                            <textarea class="form-control font-family-monospace" name="email_template" id="txEmailTemplate" rows="5" placeholder="Customize the inner email block content..."></textarea>
                                            <div class="mt-2 d-flex justify-content-between align-items-center">
                                                <small class="text-muted">
                                                    Placeholders: <code>{name}</code>, <code>{account_number}</code>, <code>{amount}</code>, <code>{recipient_account}</code>, <code>{reason}</code>, <code>{date_time}</code>, <code>{reference_number}</code>
                                                </small>
                                                <button type="button" id="previewEmailBtn" class="btn btn-outline-info btn-sm font-weight-bold"><i class="fas fa-eye mr-1"></i> Preview HTML</button>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="card-footer text-right">
                                        <button type="submit" id="txStatusBtn" class="btn btn-primary font-weight-bold"><i class="fas fa-save mr-1"></i> Save Transaction Status</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- User History (Login Logs and Transactions) -->
                    <div class="card card-outline card-secondary mt-4">
                        <div class="card-header p-2">
                            <ul class="nav nav-pills">
                                <li class="nav-item"><a class="nav-link active font-weight-bold" href="#transactionsTab" data-toggle="tab"><i class="fas fa-exchange-alt mr-1"></i> Transaction History</a></li>
                                <li class="nav-item"><a class="nav-link font-weight-bold" href="#activitiesTab" data-toggle="tab"><i class="fas fa-user-clock mr-1"></i> Login & Activity Log</a></li>
                            </ul>
                        </div>
                        <div class="card-body p-0">
                            <div class="tab-content">
                                <!-- Transactions Tab -->
                                <div class="active tab-pane" id="transactionsTab">
                                    <div class="table-responsive" style="max-height: 400px;">
                                        <table class="table table-hover table-striped text-nowrap mb-0">
                                            <thead>
                                                <tr>
                                                    <th>Transaction ID</th>
                                                    <th>UTR ID</th>
                                                    <th>Flow</th>
                                                    <th>Sender</th>
                                                    <th>Recipient Account</th>
                                                    <th>Amount</th>
                                                    <th>Remarks</th>
                                                    <th>Date & Time</th>
                                                    <th>Status</th>
                                                </tr>
                                            </thead>
                                            <tbody id="transactionsTableBody">
                                                <!-- Populated dynamically -->
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                <!-- Activity Logs Tab -->
                                <div class="tab-pane" id="activitiesTab">
                                    <div class="table-responsive" style="max-height: 400px;">
                                        <table class="table table-hover table-striped text-nowrap mb-0">
                                            <thead>
                                                <tr>
                                                    <th>IP Address</th>
                                                    <th>Status</th>
                                                    <th>Details</th>
                                                    <th>Date & Time</th>
                                                </tr>
                                            </thead>
                                            <tbody id="activitiesTableBody">
                                                <!-- Populated dynamically -->
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
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

<script>
$(document).ready(function() {
    var searchTimer = null;
    var selectedAppId = null;

    // Search input keyup
    $('#searchInput').on('keyup', function() {
        var query = $(this).val().trim();
        clearTimeout(searchTimer);
        
        if (query.length < 2) {
            $('#searchResults').addClass('d-none').html('');
            return;
        }

        searchTimer = setTimeout(function() {
            $.ajax({
                url: 'user_profiles.php',
                method: 'GET',
                data: { action: 'search', query: query },
                dataType: 'json',
                success: function(data) {
                    if (data.length === 0) {
                        $('#searchResults').removeClass('d-none').html('<div class="p-3 text-muted">No users found matching query.</div>');
                        return;
                    }
                    var html = '';
                    data.forEach(function(user) {
                        var badgeClass = 'badge-secondary';
                        if (user.status === 'APPROVED') badgeClass = 'badge-success';
                        if (user.status === 'PENDING') badgeClass = 'badge-warning';
                        if (user.status === 'REJECTED') badgeClass = 'badge-danger';
                        
                        html += '<div class="search-item" data-id="' + user.app_id + '">' +
                                    '<div class="d-flex justify-content-between">' +
                                        '<strong>' + escapeHtml(user.full_name) + '</strong>' +
                                        '<span class="badge ' + badgeClass + '">' + user.status + '</span>' +
                                    '</div>' +
                                    '<div class="small text-muted">' + escapeHtml(user.email) + ' | ' + escapeHtml(user.phone) + '</div>' +
                                '</div>';
                    });
                    $('#searchResults').removeClass('d-none').html(html);
                }
            });
        }, 300);
    });

    // Select user from list
    $(document).on('click', '.search-item', function() {
        var appId = $(this).data('id');
        var name = $(this).find('strong').text();
        $('#searchInput').val(name);
        $('#searchResults').addClass('d-none').html('');
        loadUserDetails(appId);
    });

    // Close search box clicking outside
    $(document).on('click', function(e) {
        if (!$(e.target).closest('#searchInput, #searchResults').length) {
            $('#searchResults').addClass('d-none');
        }
    });

    // Load User Details Function
    function loadUserDetails(appId) {
        selectedAppId = appId;
        $('#noUserAlert').addClass('d-none');
        $('#userManagerContainer').removeClass('d-none');
        
        // Reset alerts
        $('.alert').addClass('d-none').removeClass('alert-success alert-danger').text('');

        $.ajax({
            url: 'user_profiles.php',
            method: 'GET',
            data: { action: 'get_details', app_id: appId },
            dataType: 'json',
            success: function(response) {
                if (!response.success) {
                    alert(response.message);
                    return;
                }
                var app = response.application;
                var acctNum = response.account_number;
                
                // Set form values
                $('#profileAppId, #balanceAppId, #passwordAppId, #mpinAppId, #txAppId').val(app.app_id);
                $('#profileName').val(app.full_name);
                $('#profileEmail').val(app.email);
                $('#profilePhone').val(app.phone);
                $('#profilePassword').val(app.password_hash);
                
                $('#txStatusSelect').val(parseInt(app.tx_enabled) === 0 ? 'off' : 'on');
                $('#txStatusMessage').val(app.tx_disabled_message || '');
                $('#txStatusRemarks').val('');
                var defaultEmailTemplate = '<div style="background:#fef2f2;padding:18px;border-radius:10px;border-left:5px solid #dc2626;margin-top:20px;">\n' +
                    '    <strong style="color:#dc2626;">✗ Money Transaction Failed</strong>\n' +
                    '    <p style="margin:10px 0 0;color:#555;line-height:24px;">The transaction could not be processed. Reason: {reason}</p>\n' +
                    '</div>';
                $('#txEmailTemplate').val(app.tx_failed_email_template || defaultEmailTemplate);
                
                // Display headers
                $('#displayAccountNumber').text(acctNum);
                $('#displayBalance').text('₹' + parseFloat(app.balance).toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2}));
                
                // Reset balance action type to default add
                $('#balanceAction').val('add').trigger('change');
                  // Control state based on account approval status
                if (acctNum === 'N/A' || app.status !== 'APPROVED') {
                    $('#depositBtn, #mpinBtn, #txStatusBtn, #previewEmailBtn').prop('disabled', true);
                    $('#addBalanceForm input, #addBalanceForm select, #changeMpinForm input, #toggleTxForm input, #toggleTxForm select, #toggleTxForm textarea').prop('disabled', true);
                    $('#balanceAlert').text('Balance options disabled. User account is not approved/activated.').addClass('alert-warning').removeClass('d-none');
                    $('#mpinAlert').text('MPIN options disabled. User account is not approved/activated.').addClass('alert-warning').removeClass('d-none');
                    $('#txStatusAlert').text('Transaction options disabled. User account is not approved/activated.').addClass('alert-warning').removeClass('d-none');
                } else {
                    $('#depositBtn, #mpinBtn, #txStatusBtn, #previewEmailBtn').prop('disabled', false);
                    $('#addBalanceForm input, #addBalanceForm select, #changeMpinForm input, #toggleTxForm input, #toggleTxForm select, #toggleTxForm textarea').prop('disabled', false);
                }

                // Render transactions
                var txnHtml = '';
                if (response.transactions.length === 0) {
                    txnHtml = '<tr><td colspan="9" class="text-center text-muted py-3">No transactions found.</td></tr>';
                } else {
                    response.transactions.forEach(function(txn) {
                        var flowBadge = txn.flow_type === 'DEBIT' ? '<span class="badge badge-danger">Debit</span>' : '<span class="badge badge-success">Credit</span>';
                        var amountColor = txn.flow_type === 'DEBIT' ? 'text-danger' : 'text-success';
                        var sign = txn.flow_type === 'DEBIT' ? '-' : '+';
                        var statusBadge = txn.status === 'SUCCESS' ? '<span class="badge badge-success">Success</span>' : '<span class="badge badge-warning">' + txn.status + '</span>';
                        
                        txnHtml += '<tr>' +
                                    '<td>' + escapeHtml(txn.transaction_id) + '</td>' +
                                    '<td>' + escapeHtml(txn.utr_id || 'N/A') + '</td>' +
                                    '<td>' + flowBadge + '</td>' +
                                    '<td>' + escapeHtml(txn.sender_name || 'System / Admin') + '</td>' +
                                    '<td>' + escapeHtml(txn.recipient_account) + '</td>' +
                                    '<td class="font-weight-bold ' + amountColor + '">' + sign + '₹' + parseFloat(txn.amount).toFixed(2) + '</td>' +
                                    '<td><span class="text-muted small">' + escapeHtml(txn.remarks || 'N/A') + '</span></td>' +
                                    '<td>' + escapeHtml(txn.created_at) + '</td>' +
                                    '<td>' + statusBadge + '</td>' +
                                   '</tr>';
                    });
                }
                $('#transactionsTableBody').html(txnHtml);

                // Render activities
                var actHtml = '';
                if (response.activities.length === 0) {
                    actHtml = '<tr><td colspan="4" class="text-center text-muted py-3">No login logs recorded.</td></tr>';
                } else {
                    response.activities.forEach(function(act) {
                        var badgeClass = act.status === 'SUCCESS' ? 'badge-success' : 'badge-danger';
                        actHtml += '<tr>' +
                                    '<td>' + escapeHtml(act.ip_address) + '</td>' +
                                    '<td><span class="badge ' + badgeClass + '">' + act.status + '</span></td>' +
                                    '<td>' + escapeHtml(act.details || 'N/A') + '</td>' +
                                    '<td>' + escapeHtml(act.created_at) + '</td>' +
                                   '</tr>';
                    });
                }
                $('#activitiesTableBody').html(actHtml);
            }
        });
    }

    // Submit basic profile form
    $('#basicProfileForm').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var alertDiv = $('#profileAlert');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger');

        $.ajax({
            url: 'user_profiles.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                }
            }
        });
    });

    // Balance action dropdown listener
    $('#balanceAction').on('change', function() {
        var action = $(this).val();
        var btn = $('#depositBtn');
        var label = $('#amountLabel');
        if (action === 'add') {
            label.text('Amount to Add (INR)');
            btn.html('<i class="fas fa-plus mr-1"></i> Add Balance')
               .removeClass('btn-danger')
               .addClass('btn-primary');
        } else {
            label.text('Amount to Deduct (INR)');
            btn.html('<i class="fas fa-minus mr-1"></i> Deduct Balance')
               .removeClass('btn-primary')
               .addClass('btn-danger');
        }
    });

    // Submit add balance form
    $('#addBalanceForm').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var alertDiv = $('#balanceAlert');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger');

        var action = $('#balanceAction').val();
        var confirmMsg = action === 'add' ? 'Are you sure you want to add this balance?' : 'Are you sure you want to deduct this balance?';
        if (!confirm(confirmMsg)) {
            return;
        }

        $.ajax({
            url: 'user_profiles.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                    form.find('input[name="amount"]').val('');
                    form.find('input[name="utr_id"]').val('');
                    form.find('input[name="remarks"]').val('');
                    // Reload details
                    loadUserDetails(selectedAppId);
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                }
            }
        });
    });

    // Submit change password form
    $('#changePasswordForm').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var alertDiv = $('#passwordAlert');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger');

        $.ajax({
            url: 'user_profiles.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                }
            }
        });
    });

    // Submit change mpin form
    $('#changeMpinForm').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var alertDiv = $('#mpinAlert');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger');

        $.ajax({
            url: 'user_profiles.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                    form.find('input[name="new_mpin"]').val('');
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                }
            }
        });
    });

    // Submit toggle transaction form
    $('#toggleTxForm').on('submit', function(e) {
        e.preventDefault();
        var form = $(this);
        var alertDiv = $('#txStatusAlert');
        var submitBtn = $('#txStatusBtn');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger alert-warning');
        submitBtn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin mr-1"></i> Saving...');

        $.ajax({
            url: '../api/admin_toggle_tx.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                submitBtn.prop('disabled', false).html('<i class="fas fa-save mr-1"></i> Save Transaction Status');
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                    loadUserDetails(selectedAppId);
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                }
            },
            error: function(xhr) {
                submitBtn.prop('disabled', false).html('<i class="fas fa-save mr-1"></i> Save Transaction Status');
                var msg = 'An unexpected error occurred.';
                if (xhr.responseJSON && xhr.responseJSON.message) {
                    msg = xhr.responseJSON.message;
                }
                alertDiv.text(msg).addClass('alert-danger').removeClass('d-none');
            }
        });
    });

    // Live preview email template click
    $(document).on('click', '#previewEmailBtn', function(e) {
        e.preventDefault();
        var rawTemplate = $('#txEmailTemplate').val();
        var userName = $('#profileName').val() || 'Test Customer';
        var accountNum = $('#displayAccountNumber').text() || '50134284571';
        var customMsg = $('#txStatusMessage').val() || 'Account under security review. Outgoing transfers suspended.';
        var mockAmount = '5000.00';
        var mockRecipient = '9182736450';

        var compiledHtml = compileEmailPreview(rawTemplate, userName, accountNum, mockAmount, mockRecipient, customMsg);
        $('#emailPreviewContent').html(compiledHtml);
        $('#emailPreviewModal').modal('show');
    });

    var defaultTemplate = '<div style="background:#fef2f2;padding:18px;border-radius:10px;border-left:5px solid #dc2626;margin-top:20px;">' +
        '<strong style="color:#dc2626;">✗ Money Transaction Failed</strong>' +
        '<p style="margin:10px 0 0;color:#555;line-height:24px;">The transaction could not be processed. Reason: {reason}</p>' +
    '</div>';

    function compileEmailPreview(rawTemplate, name, accountNumber, amount, recipientAccount, reason) {
        var template = rawTemplate.trim() || defaultTemplate;
        var dateTime = new Date().toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
        var ref = 'DF-' + Math.floor(10000000 + Math.random() * 90000000);
        
        // Replace placeholders
        template = template.replace(/{name}/g, escapeHtml(name))
                           .replace(/{account_number}/g, escapeHtml(accountNumber))
                           .replace(/{amount}/g, '₹' + parseFloat(amount).toFixed(2))
                           .replace(/{recipient_account}/g, escapeHtml(recipientAccount))
                           .replace(/{reason}/g, escapeHtml(reason))
                           .replace(/{date_time}/g, dateTime)
                           .replace(/{reference_number}/g, ref);

        // Deccan Finance full branded theme HTML wrapper
        var fullHtml = '<div style="margin:0;padding:20px;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;">' +
            '<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb;padding:20px 0; border-collapse: collapse;">' +
            '<tr><td align="center">' +
            '<table width="100%" max-width="600" style="max-width:600px;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 25px rgba(0,0,0,.08); border-collapse: collapse;">' +
            '<tr><td align="center" style="padding:35px 20px;background:linear-gradient(135deg, #ef4444, #b91c1c);">' +
            '<img src="https://deccanfinltd.world/assets/img/logo.png" width="80" style="display:block;margin-bottom:10px;margin: 0 auto 10px auto;">' +
            '<h1 style="margin:10px 0 5px;color:#fff;font-size:30px;text-align:center;">Deccan Finance</h1>' +
            '<p style="margin:0;color:#e7e7ff;font-size:15px;text-align:center;">Secure. Simple. Trusted.</p>' +
            '</td></tr>' +
            '<tr><td style="padding:40px;">' +
            '<h2 style="margin-top:0;color:#222;font-size:28px;">Transaction Failed</h2>' +
            '<p style="color:#555;font-size:16px;line-height:28px;">Hello <strong>' + escapeHtml(name) + '</strong>,</p>' +
            '<p style="color:#555;font-size:16px;line-height:28px;">A transaction attempt could not be processed on your account.</p>' +
            '<table width="100%" cellpadding="12" cellspacing="0" style="margin:30px 0;background:#f8f9ff;border-radius:12px; border-collapse: collapse;">' +
            '<tr><td style="color:#666;">Transaction Amount</td>' +
            '<td align="right" style="font-size:28px;font-weight:bold;color:#dc2626;">₹' + parseFloat(amount).toFixed(2) + '</td></tr>' +
            '<tr><td style="color:#666;">Available Balance</td>' +
            '<td align="right" style="font-size:18px;color:#222;"><strong>₹10,500.00</strong></td></tr>' +
            '<tr><td style="color:#666;">Date & Time</td>' +
            '<td align="right" style="color:#222;">' + dateTime + '</td></tr>' +
            '<tr><td style="color:#666;">Reference Number</td>' +
            '<td align="right" style="color:#222;">' + ref + '</td></tr>' +
            '<tr><td style="color:#666;">Transaction Type</td>' +
            '<td align="right" style="color:#222;">FAILED_TRANSACTION</td></tr>' +
            '<tr><td style="color:#666;">Description</td>' +
            '<td align="right" style="color:#222;">' + escapeHtml(recipientAccount) + '</td></tr>' +
            '</table>' +
            template +
            '</td></tr>' +
            '<tr><td style="padding:30px;background:#fafafa;border-top:1px solid #eee;text-align:center;">' +
            '<p style="margin:0;font-size:13px;color:#888;text-align:center;">This is an automated notification. Please do not reply to this email.</p>' +
            '<p style="margin-top:15px;font-size:13px;color:#999;text-align:center;">Need help? <a href="mailto:support@deccanfinltd.world" style="color:#ef4444;text-decoration:none;">support@deccanfinltd.world</a></p>' +
            '<p style="margin-top:20px;font-size:12px;color:#bbb;text-align:center;">© 2026 Deccan Finance. All Rights Reserved.</p>' +
            '</td></tr></table>' +
            '</td></tr></table></div>';

        return fullHtml;
    }

    // Helper functions
    function escapeHtml(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;')
                  .replace(/'/g, '&#039;');
    }
});
</script>
<!-- Email Preview Modal -->
<div class="modal fade" id="emailPreviewModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content" style="border-radius: 12px; overflow: hidden; border: none; box-shadow: 0 10px 30px rgba(0,0,0,0.2);">
            <div class="modal-header bg-info" style="border-bottom: none;">
                <h5 class="modal-title text-white font-weight-bold"><i class="fas fa-envelope mr-1"></i> Branded Email Live Preview</h5>
                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body p-0" style="background: #f4f7fb; overflow-y: auto; max-height: 75vh;">
                <!-- Preview Frame -->
                <div id="emailPreviewContent"></div>
            </div>
            <div class="modal-footer bg-light" style="border-top: none;">
                <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">Close Preview</button>
            </div>
        </div>
    </div>
</div>

</body>
</html>
