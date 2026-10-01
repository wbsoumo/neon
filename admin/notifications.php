<?php
/**
 * Deccan Finance - Push Notification Dispatcher
 * Standalone console page to dispatch individual/bulk alerts to devices.
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

// Process action request (SEND_BULK_NOTIFICATION)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    $action = isset($_POST['action']) ? $_POST['action'] : '';
    
    if ($action === 'SEND_BULK_NOTIFICATION') {
        $target = isset($_POST['target']) ? trim($_POST['target']) : 'SINGLE'; // 'SINGLE' or 'ALL'
        $targetAppId = isset($_POST['target_app_id']) ? trim($_POST['target_app_id']) : '';
        $title = isset($_POST['title']) ? trim($_POST['title']) : '';
        $body = isset($_POST['body']) ? trim($_POST['body']) : '';
        $category = isset($_POST['category']) ? trim($_POST['category']) : 'Updates';
        
        if (empty($title) || empty($body)) {
            echo json_encode(['success' => false, 'message' => 'Notification Title and Message/Body are required.']);
            exit;
        }
        
        // Handle optional photo attachment upload
        $imageUrl = null;
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
            $fileTmpPath = $_FILES['photo']['tmp_name'];
            $fileName = $_FILES['photo']['name'];
            $fileSize = $_FILES['photo']['size'];
            
            $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
            $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
            
            if (!in_array($fileExtension, $allowedExtensions)) {
                echo json_encode(['success' => false, 'message' => 'Invalid file format. Only JPG, JPEG, PNG, and GIF images are allowed.']);
                exit;
            }
            
            // Enforce 5MB limit
            if ($fileSize > 5 * 1024 * 1024) {
                echo json_encode(['success' => false, 'message' => 'Image size exceeds maximum limit of 5MB.']);
                exit;
            }
            
            $uploadDir = '../uploads/notifications/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }
            
            $newFileName = 'notify_' . time() . '_' . mt_rand(1000, 9999) . '.' . $fileExtension;
            $destPath = $uploadDir . $newFileName;
            
            if (move_uploaded_file($fileTmpPath, $destPath)) {
                // Generate public image URL
                $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
                $imageUrl = $protocol . '://' . $_SERVER['HTTP_HOST'] . '/uploads/notifications/' . $newFileName;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to save uploaded image.']);
                exit;
            }
        }
        
        $tokens = [];
        if ($target === 'ALL') {
            $tokens = get_all_fcm_tokens();
        } else {
            // Find application token for targetAppId
            if (empty($targetAppId)) {
                echo json_encode(['success' => false, 'message' => 'Please select a recipient user.']);
                exit;
            }
            $targetApp = get_application_by_id($targetAppId);
            if (!$targetApp) {
                echo json_encode(['success' => false, 'message' => 'Recipient user not found.']);
                exit;
            }
            
            // Get fcm_token from accounts or applications
            $acc = get_account_by_app_id($targetAppId);
            $tokenVal = null;
            if ($acc && !empty($acc['fcm_token'])) {
                $tokenVal = $acc['fcm_token'];
            } elseif (!empty($targetApp['fcm_token'])) {
                $tokenVal = $targetApp['fcm_token'];
            }
            
            $tokens[] = [
                'app_id' => $targetAppId,
                'fcm_token' => $tokenVal,
                'full_name' => $targetApp['full_name']
            ];
        }
        
        if (empty($tokens)) {
            echo json_encode(['success' => false, 'message' => 'No active recipient devices found with registered FCM tokens.']);
            exit;
        }
        
        $sentCount = 0;
        $lastError = 'FCM dispatch failed.';
        foreach ($tokens as $t) {
            $res = send_fcm_notification($t['fcm_token'], $title, $body, ['app_id' => $t['app_id']], $imageUrl, $category);
            if ($res['success']) {
                $sentCount++;
            } else {
                if (!empty($res['message'])) {
                    $lastError = $res['message'];
                }
            }
        }
        
        if ($sentCount === 0) {
            echo json_encode([
                'success' => false,
                'message' => $lastError
            ]);
            exit;
        }
        
        log_admin_activity($username, 'SEND_BULK_NOTIFICATION', "Sent push notification (Target: $target, Image: " . ($imageUrl ? 'Yes' : 'No') . ") to $sentCount users.");
        echo json_encode([
            'success' => true, 
            'message' => "Successfully sent push notification to $sentCount users.", 
            'sent_count' => $sentCount,
            'image_url' => $imageUrl
        ]);
        exit;
    }
    
    echo json_encode(['success' => false, 'message' => 'Invalid Action']);
    exit;
}

// Fetch all applications for dropdown selection
$allApps = get_applications();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Push Notification Dispatcher</title>

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
        
        .text-navy {
            color: #031f73 !important;
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
                        <a href="notifications.php" class="nav-link active">
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
                        <h1 class="m-0 text-navy font-weight-bold">Push Notification Dispatcher</h1>
                    </div>
                    <div class="col-sm-6">
                        <ol class="breadcrumb float-sm-right">
                            <li class="breadcrumb-item"><a href="dashboard.php">Admin</a></li>
                            <li class="breadcrumb-item active">Send Notifications</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="content">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-8 offset-md-2">
                        <div class="card card-navy-brand card-primary shadow-lg" style="border-top: 3px solid #031f73;">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">
                                    <i class="fas fa-bell mr-2"></i> Dispatch Push Notification
                                </h3>
                            </div>
                            <div class="card-body p-4">
                                <form id="bulk-notifications-form" enctype="multipart/form-data">
                                    <input type="hidden" name="action" value="SEND_BULK_NOTIFICATION">
                                    
                                    <!-- Target Audience Selection -->
                                    <div class="form-group">
                                        <label class="font-weight-bold text-navy">Target Audience</label>
                                        <div class="mt-2">
                                            <div class="custom-control custom-radio custom-control-inline">
                                                <input type="radio" id="target_single" name="target" value="SINGLE" class="custom-control-input" checked>
                                                <label class="custom-control-label" for="target_single">Single User</label>
                                            </div>
                                            <div class="custom-control custom-radio custom-control-inline">
                                                <input type="radio" id="target_all" name="target" value="ALL" class="custom-control-input">
                                                <label class="custom-control-label" for="target_all">All Users (Broadcast)</label>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <!-- Single User Selection Dropdown -->
                                    <div class="form-group" id="single-user-select-group">
                                        <label for="target_app_id" class="font-weight-bold text-navy">Select Recipient User</label>
                                        <select class="form-control" id="target_app_id" name="target_app_id" required>
                                            <option value="">-- Choose User --</option>
                                            <?php
                                            foreach ($allApps as $app) {
                                                $acc = get_account_by_app_id($app['app_id']);
                                                $hasToken = (!empty($app['fcm_token']) || ($acc && !empty($acc['fcm_token'])));
                                                $tokenStatus = $hasToken ? "Active Device Token" : "No Token (Will be logged only)";
                                                echo '<option value="' . htmlspecialchars($app['app_id']) . '">' . 
                                                    htmlspecialchars($app['full_name']) . ' (' . htmlspecialchars($app['app_id']) . ') - ' . $tokenStatus . 
                                                    '</option>';
                                            }
                                            ?>
                                        </select>
                                    </div>
                                    
                                    <!-- Notification Title -->
                                    <div class="form-group">
                                        <label for="notification_title" class="font-weight-bold text-navy">Notification Title</label>
                                        <input type="text" class="form-control" id="notification_title" name="title" placeholder="Enter alert title" required>
                                    </div>
                                    
                                    <!-- Category Select -->
                                    <div class="form-group">
                                        <label for="notification_category" class="font-weight-bold text-navy">Category</label>
                                        <select class="form-control" id="notification_category" name="category" required>
                                            <option value="Updates" selected>Updates</option>
                                            <option value="Transactions">Transactions</option>
                                            <option value="Offers">Offers</option>
                                            <option value="Security">Security</option>
                                        </select>
                                    </div>
                                    
                                    <!-- Notification Message -->
                                    <div class="form-group">
                                        <label for="notification_body" class="font-weight-bold text-navy">Message Body</label>
                                        <textarea class="form-control" id="notification_body" name="body" rows="4" placeholder="Enter notification message body" required></textarea>
                                    </div>
                                    
                                    <!-- Photo Attachment -->
                                    <div class="form-group">
                                        <label for="notification_photo" class="font-weight-bold text-navy">Attach Photo (Optional)</label>
                                        <div class="custom-file">
                                            <input type="file" class="custom-file-input" id="notification_photo" name="photo" accept="image/*">
                                            <label class="custom-file-label" for="notification_photo">Choose image file...</label>
                                        </div>
                                        <small class="text-muted">Supported formats: JPG, JPEG, PNG, GIF. Max file size: 5MB.</small>
                                        <div id="image-preview-wrapper" class="mt-3 text-center" style="display: none;">
                                            <img id="image-preview" src="#" alt="Preview" class="img-thumbnail" style="max-height: 200px;">
                                        </div>
                                    </div>
                                    
                                    <!-- Submit Button -->
                                    <button type="submit" class="btn btn-primary btn-block font-weight-bold shadow-sm" id="btn-bulk-send">
                                        <i class="fas fa-paper-plane mr-1"></i> Dispatch Notification
                                    </button>
                                </form>
                                
                                <!-- Receipt Details Card -->
                                <div class="card mt-4 bg-light shadow-sm" id="bulk-receipt-card" style="display: none; border-left: 5px solid #28a745;">
                                    <div class="card-body">
                                        <h5 class="text-success font-weight-bold mb-3"><i class="fas fa-check-circle mr-1"></i> Dispatch Success Receipt</h5>
                                        <table class="table table-bordered table-sm mb-0 bg-white">
                                            <tbody>
                                                <tr>
                                                    <td class="font-weight-bold" style="width: 150px;">Status</td>
                                                    <td><span class="badge badge-success">DELIVERED</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="font-weight-bold">Recipients Notified</td>
                                                    <td id="receipt-recipients">0 users</td>
                                                </tr>
                                                <tr>
                                                    <td class="font-weight-bold">Attached Photo</td>
                                                    <td id="receipt-photo-attachment">None</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
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
            Deccan Finance Security Console v1.2
        </div>
        <strong>&copy; 2026 Deccan Finance.</strong> All rights reserved.
    </footer>
</div>

<!-- jQuery -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<!-- Bootstrap 4 -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/js/bootstrap.bundle.min.js"></script>
<!-- AdminLTE App -->
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>

<script>
    // Handle toggle UI select groups
    const radSingle = document.getElementById('target_single');
    const radAll = document.getElementById('target_all');
    const userSelectGroup = document.getElementById('single-user-select-group');
    const userSelectInput = document.getElementById('target_app_id');

    radSingle.addEventListener('change', function() {
        if (this.checked) {
            userSelectGroup.style.display = 'block';
            userSelectInput.setAttribute('required', 'required');
        }
    });

    radAll.addEventListener('change', function() {
        if (this.checked) {
            userSelectGroup.style.display = 'none';
            userSelectInput.removeAttribute('required');
        }
    });

    // Image file attachment preview
    const photoInput = document.getElementById('notification_photo');
    const previewWrapper = document.getElementById('image-preview-wrapper');
    const previewImg = document.getElementById('image-preview');

    if (photoInput) {
        photoInput.addEventListener('change', function() {
            const fileName = this.value.split('\\').pop();
            this.nextElementSibling.classList.add("selected");
            this.nextElementSibling.innerHTML = fileName || "Choose image file...";
            
            if (this.files && this.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    previewImg.src = e.target.result;
                    previewWrapper.style.display = 'block';
                }
                reader.readAsDataURL(this.files[0]);
            } else {
                previewWrapper.style.display = 'none';
            }
        });
    }

    const bulkForm = document.getElementById('bulk-notifications-form');
    if (bulkForm) {
        bulkForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const btn = document.getElementById('btn-bulk-send');
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Dispatched alerts...';
            
            const formData = new FormData(this);
            fetch('notifications.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Dispatch Notification';
                
                if (data.success) {
                    document.getElementById('bulk-receipt-card').style.display = 'block';
                    document.getElementById('receipt-recipients').innerText = data.sent_count + ' user(s)';
                    if (data.image_url) {
                        document.getElementById('receipt-photo-attachment').innerHTML = `<a href="${data.image_url}" target="_blank">View Uploaded Image</a>`;
                    } else {
                        document.getElementById('receipt-photo-attachment').innerText = 'None';
                    }
                    alert(data.message);
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(err => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-paper-plane mr-1"></i> Dispatch Notification';
                alert('An error occurred during submission.');
                console.error(err);
            });
        });
    }
</script>
</body>
</html>
