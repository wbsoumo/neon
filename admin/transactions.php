<?php
/**
 * Deccan Finance - All Transactions Manager
 * Scope: Administrator Console
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

$page = 'transactions';
$error = '';
$success = '';

// --- AJAX Endpoint: Change Status ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'change_transaction_status') {
    header('Content-Type: application/json');
    
    $txnId = trim($_POST['transaction_id'] ?? '');
    $newStatus = trim($_POST['status'] ?? '');
    $utrId = trim($_POST['utr_id'] ?? '');
    $remarks = trim($_POST['remarks'] ?? '');
    
    if (empty($txnId) || empty($newStatus)) {
        echo json_encode(['success' => false, 'message' => 'Transaction ID and Status are required.']);
        exit;
    }
    
    // UTR verification for SUCCESS status
    if ($newStatus === 'SUCCESS' && empty($utrId)) {
        echo json_encode(['success' => false, 'message' => 'UTR ID is required to mark a transaction as SUCCESS.']);
        exit;
    }
    
    $sendNotif = ($newStatus === 'SUCCESS') && (isset($_POST['send_notification']) && $_POST['send_notification'] == '1');
    
    try {
        update_transaction_status($txnId, $newStatus, $utrId, $remarks, $sendNotif);
        log_admin_activity($username, 'CHANGE_TRANSACTION_STATUS', "Manually changed status of transaction $txnId to $newStatus (UTR: $utrId, Remarks: $remarks, Notified: " . ($sendNotif ? 'Yes' : 'No') . ")");
        echo json_encode(['success' => true, 'message' => "Successfully updated transaction status to $newStatus."]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
    exit;
}

// Fetch all transactions from database
$transactions = get_all_transactions();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - All Transactions Manager</title>
    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">

    <style>
        .badge-status {
            font-size: 85%;
            padding: 0.4em 0.6em;
            border-radius: 4px;
        }
    </style>
</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

    <!-- Navbar -->
    <nav class="main-header navbar navbar-expand navbar-white navbar-light">
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link" data-widget="pushmenu" href="#" role="button"><i class="fas fa-bars"></i></a>
            </li>
            <li class="nav-item d-none d-sm-inline-block">
                <a href="dashboard.php" class="nav-link">Home</a>
            </li>
        </ul>
        <ul class="navbar-nav ml-auto">
            <li class="nav-item">
                <a class="nav-link text-warning font-weight-bold" href="logout.php">
                    <i class="fas fa-sign-out-alt mr-1"></i> Log Out
                </a>
            </li>
        </ul>
    </nav>

    <!-- Main Sidebar Container -->
    <aside class="main-sidebar sidebar-light-primary elevation-4">
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
                        <a href="transactions.php" class="nav-link active">
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
                        <a href="dashboard.php?page=statements" class="nav-link">
                            <i class="nav-icon fas fa-file-invoice"></i>
                            <p>Generated Statements</p>
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
                </ul>
            </nav>
        </div>
    </aside>

    <!-- Content Wrapper -->
    <div class="content-wrapper">
        <section class="content-header">
            <div class="container-fluid">
                <div class="row mb-2">
                    <div class="col-sm-6">
                        <h1 class="font-weight-bold text-dark"><i class="fas fa-exchange-alt mr-2 text-primary"></i> All Transactions Manager</h1>
                    </div>
                </div>
            </div>
        </section>

        <!-- Main content -->
        <section class="content">
            <div class="container-fluid">
                
                <!-- Search and Filters Card -->
                <div class="card filter-card">
                    <div class="card-body">
                        <form id="filterForm" onsubmit="return false;">
                            <div class="row">
                                <div class="col-md-4 col-sm-12 mb-3">
                                    <label for="searchQuery" class="font-weight-bold">Search</label>
                                    <div class="input-group">
                                        <div class="input-group-prepend">
                                            <span class="input-group-text"><i class="fas fa-search text-muted"></i></span>
                                        </div>
                                        <input type="text" id="searchQuery" class="form-control" placeholder="Search by Txn ID, name, account, UTR...">
                                    </div>
                                </div>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <label for="filterType" class="font-weight-bold">Transaction Type</label>
                                    <select id="filterType" class="form-control">
                                        <option value="ALL">All Types</option>
                                        <option value="BANK_TRANSFER">BANK_TRANSFER (Payout)</option>
                                        <option value="P2P">P2P (Internal Transfer)</option>
                                        <option value="DEPOSIT">DEPOSIT (PayIn)</option>
                                    </select>
                                </div>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <label for="filterStatus" class="font-weight-bold">Status</label>
                                    <select id="filterStatus" class="form-control">
                                        <option value="ALL">All Statuses</option>
                                        <option value="SUCCESS">SUCCESS</option>
                                        <option value="PENDING">PENDING</option>
                                        <option value="FAILED">FAILED</option>
                                        <option value="FAILED_HELD">FAILED_HELD</option>
                                    </select>
                                </div>
                                <div class="col-md-2 col-sm-12 mb-3 d-flex align-items-end">
                                    <button type="button" class="btn btn-secondary btn-block font-weight-bold" id="resetFiltersBtn">
                                        <i class="fas fa-undo mr-1"></i> Reset
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Transaction List Card -->
                <div class="card card-outline card-primary">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h3 class="card-title font-weight-bold mb-0">Recorded Transactions (<span id="visibleCount"><?= count($transactions) ?></span>)</h3>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover table-striped mb-0" id="transactionsTable">
                                <thead>
                                    <tr>
                                        <th>Txn ID</th>
                                        <th>Created At</th>
                                        <th>Type</th>
                                        <th>Sender / User</th>
                                        <th>Recipient / Beneficiary</th>
                                        <th>Amount</th>
                                        <th>Status</th>
                                        <th>UTR ID</th>
                                        <th>Remarks</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="transactionsTableBody">
                                    <?php if (empty($transactions)): ?>
                                        <tr id="noTransactionsRow">
                                            <td colspan="10" class="text-center text-muted py-5 font-weight-bold">No transactions found in database.</td>
                                        </tr>
                                    <?php else: ?>
                                        <?php foreach ($transactions as $txn): ?>
                                            <?php
                                            // Format badges
                                            $typeBadge = 'badge-secondary';
                                            if ($txn['type'] === 'BANK_TRANSFER') $typeBadge = 'badge-primary';
                                            elseif ($txn['type'] === 'P2P') $typeBadge = 'badge-info';
                                            elseif ($txn['type'] === 'DEPOSIT') $typeBadge = 'badge-teal';

                                            $statusBadge = 'badge-warning';
                                            if ($txn['status'] === 'SUCCESS') $statusBadge = 'badge-success';
                                            elseif ($txn['status'] === 'FAILED') $statusBadge = 'badge-danger';
                                            
                                            // Resolving display names
                                            $senderDisplay = htmlspecialchars($txn['sender_name'] ?? 'SYSTEM / GATEWAY');
                                            if ($txn['sender_app_id'] && $txn['sender_app_id'] !== 'SYSTEM') {
                                                $senderDisplay .= ' (' . htmlspecialchars($txn['sender_app_id']) . ')';
                                            }
                                            
                                            $recipientDisplay = '';
                                            if (!empty($txn['recipient_name'])) {
                                                $recipientDisplay .= htmlspecialchars($txn['recipient_name']);
                                            }
                                            if (!empty($txn['recipient_account'])) {
                                                if ($recipientDisplay) $recipientDisplay .= '<br>';
                                                $recipientDisplay .= '<span class="text-muted small">A/C: ' . htmlspecialchars($txn['recipient_account']) . '</span>';
                                            }
                                            if (!empty($txn['ifsc_code'])) {
                                                $recipientDisplay .= '<br><span class="text-muted small font-weight-bold">IFSC: ' . htmlspecialchars($txn['ifsc_code']) . '</span>';
                                            }
                                            if (empty($recipientDisplay)) {
                                                $recipientDisplay = '<span class="text-muted">N/A</span>';
                                            }
                                            ?>
                                            <tr class="txn-row" 
                                                data-id="<?= htmlspecialchars($txn['transaction_id']) ?>"
                                                data-type="<?= htmlspecialchars($txn['type']) ?>"
                                                data-status="<?= htmlspecialchars($txn['status']) ?>"
                                                data-sender="<?= strtolower(htmlspecialchars($txn['sender_name'] . ' ' . $txn['sender_app_id'])) ?>"
                                                data-recipient="<?= strtolower(htmlspecialchars(($txn['recipient_name'] ?? '') . ' ' . ($txn['recipient_account'] ?? '') . ' ' . ($txn['ifsc_code'] ?? ''))) ?>"
                                                data-utr="<?= strtolower(htmlspecialchars($txn['utr_id'] ?? '')) ?>">
                                                <td class="font-weight-bold"><?= htmlspecialchars($txn['transaction_id']) ?></td>
                                                <td class="small text-muted"><?= htmlspecialchars($txn['created_at']) ?></td>
                                                <td><span class="badge <?= $typeBadge ?>"><?= htmlspecialchars($txn['type']) ?></span></td>
                                                <td><?= $senderDisplay ?></td>
                                                <td><?= $recipientDisplay ?></td>
                                                <td class="font-weight-bold text-dark">₹<?= number_format($txn['amount'], 2) ?></td>
                                                <td><span class="badge badge-status <?= $statusBadge ?>"><?= htmlspecialchars($txn['status']) ?></span></td>
                                                <td><code class="text-indigo"><?= htmlspecialchars($txn['utr_id'] ?? 'N/A') ?></code></td>
                                                <td class="small text-muted" style="max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<?= htmlspecialchars($txn['remarks'] ?: ($txn['status_details'] ?? '')) ?>">
                                                    <?= htmlspecialchars($txn['remarks'] ?: ($txn['status_details'] ?? 'N/A')) ?>
                                                </td>
                                                <td>
                                                    <button class="btn btn-xs btn-primary font-weight-bold edit-status-btn"
                                                            data-txn-id="<?= htmlspecialchars($txn['transaction_id']) ?>"
                                                            data-current-status="<?= htmlspecialchars($txn['status']) ?>"
                                                            data-current-utr="<?= htmlspecialchars($txn['utr_id'] ?? '') ?>"
                                                            data-current-remarks="<?= htmlspecialchars($txn['remarks'] ?: ($txn['status_details'] ?? '')) ?>"
                                                            data-txn-amount="<?= htmlspecialchars($txn['amount']) ?>"
                                                            data-txn-type="<?= htmlspecialchars($txn['type']) ?>"
                                                            data-sender-name="<?= htmlspecialchars($txn['sender_name'] ?? 'SYSTEM') ?>">
                                                        <i class="fas fa-edit mr-1"></i> Edit Status
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

            </div>
        </section>
    </div>
</div>

<!-- CHANGE STATUS MODAL -->
<div class="modal fade" id="changeStatusModal" tabindex="-1" role="dialog" aria-labelledby="changeStatusModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title font-weight-bold" id="changeStatusModalLabel"><i class="fas fa-edit mr-2"></i> Update Transaction Status</h5>
                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form id="changeStatusForm">
                <input type="hidden" name="action" value="change_transaction_status">
                <input type="hidden" name="transaction_id" id="modalTxnIdInput">
                
                <div class="modal-body">
                    <div id="modalAlert" class="alert d-none"></div>
                    
                    <!-- Transaction Overview Card -->
                    <div class="card card-light mb-3">
                        <div class="card-body p-3">
                            <div class="row">
                                <div class="col-6">
                                    <span class="text-muted small">Transaction ID</span><br>
                                    <strong id="modalTxnIdDisplay" class="text-primary">--</strong>
                                </div>
                                <div class="col-6 text-right">
                                    <span class="text-muted small">Amount</span><br>
                                    <strong id="modalAmountDisplay" class="text-dark">₹0.00</strong>
                                </div>
                            </div>
                            <hr class="my-2">
                            <div class="row">
                                <div class="col-6">
                                    <span class="text-muted small">Type</span><br>
                                    <span id="modalTypeDisplay" class="badge">--</span>
                                </div>
                                <div class="col-6 text-right">
                                    <span class="text-muted small">Sender</span><br>
                                    <strong id="modalSenderDisplay" class="text-muted">--</strong>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Form Controls -->
                    <div class="form-group">
                        <label for="modalStatusSelect" class="font-weight-bold">Select New Status</label>
                        <select class="form-control" name="status" id="modalStatusSelect" required>
                            <option value="SUCCESS">SUCCESS</option>
                            <option value="PENDING">PENDING</option>
                            <option value="FAILED">FAILED</option>
                            <option value="FAILED_HELD">FAILED_HELD</option>
                        </select>
                        <small class="text-info form-text">
                            <strong>Note:</strong> Marking a Payout (BANK_TRANSFER) as FAILED automatically refunds the user's balance. Reverting a FAILED transaction re-deducts the balance.
                        </small>
                    </div>
                    
                    <div class="form-group">
                        <label for="modalUtrInput" class="font-weight-bold">Bank UTR / Reference ID</label>
                        <input type="text" class="form-control" name="utr_id" id="modalUtrInput" placeholder="Enter bank UTR number">
                        <small class="form-text text-danger d-none" id="utrRequiredMsg">
                            UTR ID is required when status is set to SUCCESS.
                        </small>
                    </div>

                    <div class="form-group" id="modalSendNotifGroup">
                        <div class="custom-control custom-checkbox">
                            <input type="checkbox" class="custom-control-input" name="send_notification" id="modalSendNotifCheck" value="1" checked>
                            <label class="custom-control-label text-navy font-weight-bold" for="modalSendNotifCheck">
                                <i class="fas fa-bell mr-1"></i> Send push notification to user
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="modalRemarksInput" class="font-weight-bold">Remarks / Internal Status Details</label>
                        <textarea class="form-control" name="remarks" id="modalRemarksInput" rows="3" placeholder="Status details/remarks for transaction logs..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary font-weight-bold" id="modalSubmitBtn">
                        <i class="fas fa-save mr-1"></i> Update Status
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- REQUIRED SCRIPTS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
$(document).ready(function() {
    
    // Filters and Search implementation (Local jQuery Filtering)
    function applyFilters() {
        var query = $('#searchQuery').val().toLowerCase().trim();
        var type = $('#filterType').val();
        var status = $('#filterStatus').val();
        
        var visibleCount = 0;
        var hasRows = false;
        
        $('.txn-row').each(function() {
            var row = $(this);
            var rowId = row.data('id').toLowerCase();
            var rowType = row.data('type');
            var rowStatus = row.data('status');
            var rowSender = row.data('sender');
            var rowRecipient = row.data('recipient');
            var rowUtr = row.data('utr');
            
            // Query filter match
            var matchesQuery = (
                rowId.indexOf(query) !== -1 ||
                rowSender.indexOf(query) !== -1 ||
                rowRecipient.indexOf(query) !== -1 ||
                rowUtr.indexOf(query) !== -1
            );
            
            // Type filter match
            var matchesType = (type === 'ALL' || rowType === type);
            
            // Status filter match
            var matchesStatus = (status === 'ALL' || rowStatus === status);
            
            if (matchesQuery && matchesType && matchesStatus) {
                row.show();
                visibleCount++;
                hasRows = true;
            } else {
                row.hide();
            }
        });
        
        $('#visibleCount').text(visibleCount);
        
        // Show/hide empty state
        if (!hasRows) {
            if ($('#noTransactionsRow').length === 0) {
                $('#transactionsTableBody').append('<tr id="noTransactionsRow"><td colspan="10" class="text-center text-muted py-5 font-weight-bold">No transactions match the selected filters.</td></tr>');
            } else {
                $('#noTransactionsRow').show();
                $('#noTransactionsRow td').text('No transactions match the selected filters.');
            }
        } else {
            $('#noTransactionsRow').hide();
        }
    }
    
    // Wire up filter triggers
    $('#searchQuery').on('keyup', applyFilters);
    $('#filterType, #filterStatus').on('change', applyFilters);
    
    // Reset Filters Button
    $('#resetFiltersBtn').on('click', function() {
        $('#searchQuery').val('');
        $('#filterType').val('ALL');
        $('#filterStatus').val('ALL');
        applyFilters();
    });
    
    // Edit Status Button modal opener
    $('.edit-status-btn').on('click', function() {
        var btn = $(this);
        var txnId = btn.data('txn-id');
        var currentStatus = btn.data('current-status');
        var currentUtr = btn.data('current-utr');
        var currentRemarks = btn.data('current-remarks');
        var txnAmount = btn.data('txn-amount');
        var txnType = btn.data('txn-type');
        var senderName = btn.data('sender-name');
        
        // Populate modal fields
        $('#modalTxnIdInput').val(txnId);
        $('#modalTxnIdDisplay').text(txnId);
        $('#modalAmountDisplay').text('₹' + parseFloat(txnAmount).toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2}));
        
        // Setup type badge style
        var typeBadgeClass = 'badge-secondary';
        if (txnType === 'BANK_TRANSFER') typeBadgeClass = 'badge-primary';
        else if (txnType === 'P2P') typeBadgeClass = 'badge-info';
        else if (txnType === 'DEPOSIT') typeBadgeClass = 'badge-teal';
        
        $('#modalTypeDisplay').text(txnType).removeClass().addClass('badge ' + typeBadgeClass);
        $('#modalSenderDisplay').text(senderName);
        
        $('#modalStatusSelect').val(currentStatus);
        $('#modalUtrInput').val(currentUtr);
        $('#modalRemarksInput').val(currentRemarks);
        
        // Trigger validation helper
        toggleStatusFields(currentStatus);
        
        // Reset alerts
        $('#modalAlert').addClass('d-none').removeClass('alert-success alert-danger').text('');
        
        // Show modal
        $('#changeStatusModal').modal('show');
    });
    
    // Helper to toggle UTR requirements and notification checkbox visibility based on status input
    function toggleStatusFields(status) {
        if (status === 'SUCCESS') {
            $('#modalUtrInput').prop('required', true);
            $('#utrRequiredMsg').removeClass('d-none');
            $('#modalSendNotifGroup').removeClass('d-none');
        } else {
            $('#modalUtrInput').prop('required', false);
            $('#utrRequiredMsg').addClass('d-none');
            $('#modalSendNotifGroup').addClass('d-none');
        }
    }
    
    $('#modalStatusSelect').on('change', function() {
        toggleStatusFields($(this).val());
    });
    
    // Handle status change submission via AJAX
    $('#changeStatusForm').on('submit', function(e) {
        e.preventDefault();
        
        var form = $(this);
        var submitBtn = $('#modalSubmitBtn');
        var alertDiv = $('#modalAlert');
        
        // Disable submit button during processing
        submitBtn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin mr-1"></i> Saving...');
        alertDiv.addClass('d-none').removeClass('alert-success alert-danger');
        
        $.ajax({
            url: 'transactions.php',
            method: 'POST',
            data: form.serialize(),
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alertDiv.text(response.message).addClass('alert-success').removeClass('d-none');
                    // Reload page after brief delay to show final updated table
                    setTimeout(function() {
                        location.reload();
                    }, 1200);
                } else {
                    alertDiv.text(response.message).addClass('alert-danger').removeClass('d-none');
                    submitBtn.prop('disabled', false).html('<i class="fas fa-save mr-1"></i> Update Status');
                }
            },
            error: function() {
                alertDiv.text('An unexpected error occurred. Please try again.').addClass('alert-danger').removeClass('d-none');
                submitBtn.prop('disabled', false).html('<i class="fas fa-save mr-1"></i> Update Status');
            }
        });
    });
});
</script>
</body>
</html>
