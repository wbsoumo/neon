<?php
/**
 * Deccan Finance - Regulatory Compliance Document Manager (SOF, FDI, FEMA, AML)
 * Allows setting texts, uploading images & PDFs on a per-user basis with push notification actions.
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

// Map types to human readable titles
$typeTitles = [
    'sof' => 'Sources of Fund (SOF)',
    'fdi' => 'Foreign Direct Investment (FDI)',
    'fema' => 'Foreign Exchange Management Act (FEMA)',
    'aml' => 'Anti-Money Laundering (AML)'
];

// Handle AJAX POST requests
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    $action = isset($_POST['action']) ? $_POST['action'] : '';

    if ($action === 'SAVE_COMPLIANCE') {
        $appId = isset($_POST['app_id']) ? trim($_POST['app_id']) : '';
        $type = isset($_POST['type']) ? trim($_POST['type']) : '';
        $textContent = isset($_POST['text_content']) ? trim($_POST['text_content']) : '';
        $sendNotification = isset($_POST['send_notification']) && $_POST['send_notification'] == '1';
        $notifTitle = isset($_POST['notif_title']) ? trim($_POST['notif_title']) : '';
        $notifBody = isset($_POST['notif_body']) ? trim($_POST['notif_body']) : '';

        if (empty($appId)) {
            echo json_encode(['success' => false, 'message' => 'User selection is required.']);
            exit;
        }

        if (!in_array($type, ['sof', 'fdi', 'fema', 'aml'])) {
            echo json_encode(['success' => false, 'message' => 'Invalid compliance type specified.']);
            exit;
        }

        // Retrieve existing compliance data to preserve files if not re-uploaded
        $existing = get_user_compliance($appId, $type);
        $imagePath = $existing ? $existing['image_path'] : null;
        $pdfPath = $existing ? $existing['pdf_path'] : null;

        $uploadDir = '../uploads/compliance/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        // Process Image Upload
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $imageName = $_FILES['image']['name'];
            $imageTmp = $_FILES['image']['tmp_name'];
            $imageSize = $_FILES['image']['size'];
            $imageExt = strtolower(pathinfo($imageName, PATHINFO_EXTENSION));
            $allowedImgExt = ['jpg', 'jpeg', 'png', 'gif'];

            if (!in_array($imageExt, $allowedImgExt)) {
                echo json_encode(['success' => false, 'message' => 'Invalid image format. Only JPG, JPEG, PNG, and GIF allowed.']);
                exit;
            }
            if ($imageSize > 5 * 1024 * 1024) {
                echo json_encode(['success' => false, 'message' => 'Image size exceeds maximum limit of 5MB.']);
                exit;
            }

            // Remove old file if it exists
            if ($imagePath && file_exists('../' . $imagePath)) {
                @unlink('../' . $imagePath);
            }

            $newImgName = $type . '_image_' . $appId . '_' . time() . '.' . $imageExt;
            if (move_uploaded_file($imageTmp, $uploadDir . $newImgName)) {
                $imagePath = 'uploads/compliance/' . $newImgName;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to save uploaded image.']);
                exit;
            }
        }

        // Process PDF Upload
        if (isset($_FILES['pdf']) && $_FILES['pdf']['error'] === UPLOAD_ERR_OK) {
            $pdfName = $_FILES['pdf']['name'];
            $pdfTmp = $_FILES['pdf']['tmp_name'];
            $pdfSize = $_FILES['pdf']['size'];
            $pdfExt = strtolower(pathinfo($pdfName, PATHINFO_EXTENSION));

            if ($pdfExt !== 'pdf') {
                echo json_encode(['success' => false, 'message' => 'Invalid document format. Only PDF files are allowed.']);
                exit;
            }
            if ($pdfSize > 10 * 1024 * 1024) {
                echo json_encode(['success' => false, 'message' => 'PDF size exceeds maximum limit of 10MB.']);
                exit;
            }

            // Remove old file if it exists
            if ($pdfPath && file_exists('../' . $pdfPath)) {
                @unlink('../' . $pdfPath);
            }

            $newPdfName = $type . '_pdf_' . $appId . '_' . time() . '.pdf';
            if (move_uploaded_file($pdfTmp, $uploadDir . $newPdfName)) {
                $pdfPath = 'uploads/compliance/' . $newPdfName;
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to save uploaded PDF file.']);
                exit;
            }
        }

        // Save compliance record in database
        $dbResult = save_user_compliance($appId, $type, $textContent, $imagePath, $pdfPath);
        
        if (!$dbResult) {
            echo json_encode(['success' => false, 'message' => 'Failed to save compliance details in the database.']);
            exit;
        }

        $notificationSent = false;
        $notificationError = '';

        if ($sendNotification) {
            // Trigger push notification to user
            $title = !empty($notifTitle) ? $notifTitle : ($typeTitles[$type] . " Regulatory Update");
            $body = !empty($notifBody) ? $notifBody : ("A new document / update has been uploaded regarding your " . $typeTitles[$type] . ". Tap here to view details.");
            
            // Build absolute path to dynamic image if available
            $imageUrl = null;
            if ($imagePath) {
                $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
                $imageUrl = $protocol . '://' . $_SERVER['HTTP_HOST'] . '/' . ltrim($imagePath, '/');
            }

            $deepLinkData = [
                'click_action' => 'OPEN_COMPLIANCE',
                'page' => $type,
                'screen' => $type,
                'deep_link' => 'fastrand://compliance/' . $type
            ];

            $notifResult = send_notification_to_user($appId, $title, $body, $deepLinkData, $imageUrl, 'Updates');
            if ($notifResult['success']) {
                $notificationSent = true;
            } else {
                $notificationError = $notifResult['message'];
            }
        }

        log_admin_activity($username, 'SAVE_COMPLIANCE', "Saved regulatory data for user: $appId (Type: $type, Notified: " . ($notificationSent ? 'Yes' : 'No') . ")");
        
        echo json_encode([
            'success' => true,
            'message' => 'Compliance details saved successfully.' . ($sendNotification ? ($notificationSent ? ' Push notification sent.' : ' Failed to send push: ' . $notificationError) : ''),
            'notification_sent' => $notificationSent
        ]);
        exit;
    }

    if ($action === 'RESEND_NOTIFICATION') {
        $appId = isset($_POST['app_id']) ? trim($_POST['app_id']) : '';
        $type = isset($_POST['type']) ? trim($_POST['type']) : '';
        $notifTitle = isset($_POST['notif_title']) ? trim($_POST['notif_title']) : '';
        $notifBody = isset($_POST['notif_body']) ? trim($_POST['notif_body']) : '';

        if (empty($appId) || empty($type)) {
            echo json_encode(['success' => false, 'message' => 'User selection and compliance type are required.']);
            exit;
        }

        $compliance = get_user_compliance($appId, $type);
        if (!$compliance) {
            echo json_encode(['success' => false, 'message' => 'No compliance data exists for this user. Please save compliance details first.']);
            exit;
        }

        $title = !empty($notifTitle) ? $notifTitle : ($typeTitles[$type] . " Regulatory Alert");
        $body = !empty($notifBody) ? $notifBody : ("Please review your updated compliance details regarding " . $typeTitles[$type] . ". Tap here to open.");

        $imageUrl = null;
        if (!empty($compliance['image_path'])) {
            $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
            $imageUrl = $protocol . '://' . $_SERVER['HTTP_HOST'] . '/' . ltrim($compliance['image_path'], '/');
        }

        $deepLinkData = [
            'click_action' => 'OPEN_COMPLIANCE',
            'page' => $type,
            'screen' => $type,
            'deep_link' => 'fastrand://compliance/' . $type
        ];

        $notifResult = send_notification_to_user($appId, $title, $body, $deepLinkData, $imageUrl, 'Updates');
        
        if ($notifResult['success']) {
            log_admin_activity($username, 'RESEND_COMPLIANCE_NOTIFICATION', "Resent regulatory alert for user: $appId (Type: $type)");
            echo json_encode(['success' => true, 'message' => 'App notification resent successfully.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Notification dispatch failed: ' . $notifResult['message']]);
        }
        exit;
    }

    echo json_encode(['success' => false, 'message' => 'Invalid action requested.']);
    exit;
}

// Fetch user data for selector dropdown
$allApps = get_applications();

// Selected user ID
$selectedAppId = isset($_GET['app_id']) ? trim($_GET['app_id']) : '';

// Retrieve compliance records if a user is selected
$complianceData = [];
$selectedAppDetails = null;

if (!empty($selectedAppId)) {
    $selectedAppDetails = get_application_by_id($selectedAppId);
    if ($selectedAppDetails) {
        foreach (['sof', 'fdi', 'fema', 'aml'] as $t) {
            $complianceData[$t] = get_user_compliance($selectedAppId, $t);
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Compliance Document Manager</title>

    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- AdminLTE Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">

</head>
<body class="hold-transition sidebar-mini layout-fixed">
<div class="wrapper">

    <!-- Top Navbar -->
    <nav class="main-header navbar navbar-expand navbar-white navbar-light">
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
                        <a href="compliance.php" class="nav-link active">
                            <i class="nav-icon fas fa-file-contract"></i>
                            <p>Compliance Manager</p>
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
                        <h1 class="m-0 text-navy font-weight-bold">Regulatory Compliance Manager</h1>
                    </div>
                    <div class="col-sm-6">
                        <ol class="breadcrumb float-sm-right">
                            <li class="breadcrumb-item"><a href="dashboard.php">Admin</a></li>
                            <li class="breadcrumb-item active">Compliance Manager</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="content">
            <div class="container-fluid">
                <div class="row">
                    <!-- User Selection Column -->
                    <div class="col-md-4">
                        <div class="card card-navy-brand card-primary shadow-sm" style="border-top: 3px solid #031f73;">
                            <div class="card-header">
                                <h3 class="card-title font-weight-bold">
                                    <i class="fas fa-users mr-1"></i> Target Customer
                                </h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group mb-0">
                                    <label for="user_selector" class="font-weight-bold text-navy">Select Customer Account</label>
                                    <select class="form-control" id="user_selector" onchange="loadUserCompliance(this.value)">
                                        <option value="">-- Choose User --</option>
                                        <?php
                                        foreach ($allApps as $app) {
                                            $selectedAttr = ($app['app_id'] === $selectedAppId) ? 'selected' : '';
                                            echo '<option value="' . htmlspecialchars($app['app_id']) . '" ' . $selectedAttr . '>' . 
                                                htmlspecialchars($app['full_name']) . ' (' . htmlspecialchars($app['app_id']) . ') [' . htmlspecialchars($app['status']) . ']' . 
                                                '</option>';
                                        }
                                        ?>
                                    </select>
                                </div>

                                <?php if ($selectedAppDetails): ?>
                                    <div class="mt-4 p-3 bg-light rounded border border-navy">
                                        <h5 class="text-navy font-weight-bold"><i class="fas fa-user-circle mr-1"></i> Profile Summary</h5>
                                        <hr class="my-2">
                                        <table class="table table-sm table-borderless mb-0 small text-dark">
                                            <tr>
                                                <td class="font-weight-bold" style="width: 100px;">Full Name</td>
                                                <td><?= htmlspecialchars($selectedAppDetails['full_name']) ?></td>
                                            </tr>
                                            <tr>
                                                <td class="font-weight-bold">Email</td>
                                                <td><?= htmlspecialchars($selectedAppDetails['email']) ?></td>
                                            </tr>
                                            <tr>
                                                <td class="font-weight-bold">Phone</td>
                                                <td><?= htmlspecialchars($selectedAppDetails['phone']) ?></td>
                                            </tr>
                                            <tr>
                                                <td class="font-weight-bold text-danger">Password</td>
                                                <td class="text-danger font-weight-bold"><?= htmlspecialchars($selectedAppDetails['password_hash']) ?></td>
                                            </tr>
                                            <tr>
                                                <td class="font-weight-bold">Status</td>
                                                <td>
                                                    <span class="badge badge-<?= $selectedAppDetails['status'] === 'APPROVED' ? 'success' : ($selectedAppDetails['status'] === 'PENDING' ? 'warning' : 'danger') ?>">
                                                        <?= htmlspecialchars($selectedAppDetails['status']) ?>
                                                    </span>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>

                    <!-- Compliance Tabs/Form Column -->
                    <div class="col-md-8">
                        <?php if (empty($selectedAppId)): ?>
                            <div class="card shadow-sm h-100 min-vh-50 d-flex justify-content-center align-items-center bg-light">
                                <div class="text-center py-5 text-muted">
                                    <i class="fas fa-file-contract fa-4x mb-3 text-navy"></i>
                                    <p class="font-weight-bold">Please select a target customer to view and manage their compliance documentation.</p>
                                </div>
                            </div>
                        <?php else: ?>
                            <div class="card card-navy-brand card-tabs card-primary card-outline shadow-lg">
                                <div class="card-header p-0 pt-1 border-bottom-0">
                                    <ul class="nav nav-tabs" id="compliance-custom-tabs" role="tablist">
                                        <?php 
                                        $first = true;
                                        foreach ($typeTitles as $tKey => $tTitle): 
                                        ?>
                                            <li class="nav-item">
                                                <a class="nav-link <?= $first ? 'active' : '' ?>" 
                                                   id="tab-<?= $tKey ?>-link" 
                                                   data-toggle="pill" 
                                                   href="#tab-<?= $tKey ?>" 
                                                   role="tab" 
                                                   aria-controls="tab-<?= $tKey ?>" 
                                                   aria-selected="<?= $first ? 'true' : 'false' ?>">
                                                    <i class="fas fa-file-alt mr-1"></i> <?= htmlspecialchars($tKey === 'sof' ? 'SOF' : ($tKey === 'fdi' ? 'FDI' : ($tKey === 'fema' ? 'FEMA' : 'AML'))) ?>
                                                </a>
                                            </li>
                                        <?php 
                                            $first = false;
                                        endforeach; 
                                        ?>
                                    </ul>
                                </div>
                                <div class="card-body">
                                    <div class="tab-content" id="compliance-custom-tabs-content">
                                        <?php 
                                        $first = true;
                                        foreach ($typeTitles as $tKey => $tTitle): 
                                            $record = isset($complianceData[$tKey]) ? $complianceData[$tKey] : null;
                                        ?>
                                            <div class="tab-pane fade <?= $first ? 'show active' : '' ?>" 
                                                 id="tab-<?= $tKey ?>" 
                                                 role="tabpanel" 
                                                 aria-labelledby="tab-<?= $tKey ?>-link">
                                                 
                                                <h4 class="text-navy font-weight-bold border-bottom pb-2 mb-4">
                                                    Manage <?= htmlspecialchars($tTitle) ?> details
                                                </h4>

                                                <form class="compliance-form" enctype="multipart/form-data">
                                                    <input type="hidden" name="action" value="SAVE_COMPLIANCE">
                                                    <input type="hidden" name="app_id" value="<?= htmlspecialchars($selectedAppId) ?>">
                                                    <input type="hidden" name="type" value="<?= htmlspecialchars($tKey) ?>">

                                                    <!-- Text Content -->
                                                    <div class="form-group">
                                                        <label class="font-weight-bold text-navy">Description / Regulatory text</label>
                                                        <textarea class="form-control" name="text_content" rows="5" placeholder="Enter regulatory description text for this user..."><?= htmlspecialchars($record ? $record['text_content'] : '') ?></textarea>
                                                    </div>

                                                    <div class="row">
                                                        <!-- Image File Upload -->
                                                        <div class="col-md-6">
                                                            <div class="form-group">
                                                                <label class="font-weight-bold text-navy">Regulatory Image Attachment</label>
                                                                <div class="custom-file mb-2">
                                                                    <input type="file" class="custom-file-input" name="image" accept="image/*" onchange="previewFilename(this)">
                                                                    <label class="custom-file-label">Choose image file...</label>
                                                                </div>
                                                                <small class="text-muted d-block">Allowed formats: JPG, JPEG, PNG, GIF. Max: 5MB.</small>
                                                                
                                                                <?php if ($record && !empty($record['image_path'])): ?>
                                                                    <div class="mt-3 p-2 bg-light border rounded text-center">
                                                                        <span class="small font-weight-bold text-success"><i class="fas fa-check-circle mr-1"></i> Current Image:</span>
                                                                        <br><a href="../<?= htmlspecialchars($record['image_path']) ?>" target="_blank" class="small text-primary font-weight-bold text-truncate d-inline-block" style="max-width: 100%;"><i class="fas fa-external-link-alt mr-1"></i> View Attached Image</a>
                                                                        <div class="mt-2">
                                                                            <img src="../<?= htmlspecialchars($record['image_path']) ?>" class="img-thumbnail" style="max-height: 150px; max-width: 100%; object-fit: contain; display: block; margin: 0 auto;" alt="Compliance Attachment">
                                                                        </div>
                                                                    </div>
                                                                <?php else: ?>
                                                                    <span class="badge badge-warning mt-2"><i class="fas fa-exclamation-circle mr-1"></i> No image attached</span>
                                                                <?php endif; ?>
                                                            </div>
                                                        </div>

                                                        <!-- PDF Document Upload -->
                                                        <div class="col-md-6">
                                                            <div class="form-group">
                                                                <label class="font-weight-bold text-navy">Regulatory PDF Document</label>
                                                                <div class="custom-file mb-2">
                                                                    <input type="file" class="custom-file-input" name="pdf" accept="application/pdf" onchange="previewFilename(this)">
                                                                    <label class="custom-file-label">Choose PDF file...</label>
                                                                </div>
                                                                <small class="text-muted d-block">Allowed format: PDF only. Max: 10MB.</small>

                                                                <?php if ($record && !empty($record['pdf_path'])): ?>
                                                                    <div class="mt-3 p-2 bg-light border rounded">
                                                                        <span class="small font-weight-bold text-success"><i class="fas fa-check-circle mr-1"></i> Current PDF:</span>
                                                                        <br><a href="../<?= htmlspecialchars($record['pdf_path']) ?>" target="_blank" class="small text-primary font-weight-bold text-truncate d-inline-block" style="max-width: 100%;"><i class="fas fa-file-pdf mr-1"></i> View / Download PDF</a>
                                                                    </div>
                                                                <?php else: ?>
                                                                    <span class="badge badge-warning mt-2"><i class="fas fa-exclamation-circle mr-1"></i> No PDF attached</span>
                                                                <?php endif; ?>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <hr class="my-4">

                                                     <div class="card card-outline card-navy bg-light p-3 mb-3" style="border-top: 2px solid #031f73;">
                                                         <div class="custom-control custom-checkbox mb-2">
                                                             <input type="checkbox" class="custom-control-input notif-toggle-chk" id="notify-check-<?= $tKey ?>" name="send_notification" value="1" checked onchange="toggleNotifFields('<?= $tKey ?>')">
                                                             <label class="custom-control-label text-navy font-weight-bold" for="notify-check-<?= $tKey ?>">
                                                                 <i class="fas fa-bell mr-1"></i> Send push notification to user on save
                                                             </label>
                                                         </div>
                                                         
                                                         <div id="notif-fields-<?= $tKey ?>">
                                                             <div class="form-group mb-2">
                                                                 <label class="small font-weight-bold text-navy">Notification Title</label>
                                                                 <input type="text" class="form-control form-control-sm" name="notif_title" id="notif-title-<?= $tKey ?>" value="<?= htmlspecialchars($tTitle) ?> Update" placeholder="Enter custom title">
                                                             </div>
                                                             <div class="form-group mb-0">
                                                                 <label class="small font-weight-bold text-navy">Notification Message Description</label>
                                                                 <textarea class="form-control form-control-sm notif-body-textarea" name="notif_body" id="notif-body-<?= $tKey ?>" rows="2" placeholder="Auto-generates short extract as you type above description..."></textarea>
                                                             </div>
                                                         </div>
                                                     </div>

                                                     <div class="d-flex justify-content-between align-items-center">
                                                         <div></div>
                                                         <div>
                                                             <?php if ($record): ?>
                                                                 <button type="button" class="btn btn-warning font-weight-bold shadow-sm mr-2" onclick="resendNotification('<?= htmlspecialchars($selectedAppId) ?>', '<?= htmlspecialchars($tKey) ?>')">
                                                                     <i class="fas fa-redo-alt mr-1"></i> Resend Notification
                                                                 </button>
                                                             <?php endif; ?>
                                                             <button type="submit" class="btn btn-primary font-weight-bold shadow-sm px-4">
                                                                 <i class="fas fa-save mr-1"></i> Save Changes
                                                             </button>
                                                         </div>
                                                     </div>
                                                </form>
                                            </div>
                                        <?php 
                                            $first = false;
                                        endforeach; 
                                        ?>
                                    </div>
                                </div>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Footer -->
    <footer class="main-footer">
        <div class="float-right d-none d-sm-inline">
            Deccan Finance Console
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
    function loadUserCompliance(appId) {
        if (appId) {
            window.location.href = 'compliance.php?app_id=' + encodeURIComponent(appId);
        } else {
            window.location.href = 'compliance.php';
        }
    }

    function previewFilename(input) {
        const fileName = input.value.split('\\').pop();
        if (fileName) {
            input.nextElementSibling.classList.add("selected");
            input.nextElementSibling.innerHTML = fileName;
        } else {
            input.nextElementSibling.classList.remove("selected");
            input.nextElementSibling.innerHTML = "Choose file...";
        }
    }

    // Handles compliance forms submission
    document.querySelectorAll('.compliance-form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            const btn = this.querySelector('button[type="submit"]');
            const btnText = btn.innerHTML;
            
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Saving...';

            const formData = new FormData(this);
            fetch('compliance.php', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                btn.disabled = false;
                btn.innerHTML = btnText;

                if (data.success) {
                    alert(data.message);
                    // Reload page to reflect new uploaded files
                    window.location.reload();
                } else {
                    alert('Error: ' + data.message);
                }
            })
            .catch(err => {
                btn.disabled = false;
                btn.innerHTML = btnText;
                alert('An error occurred during submission.');
                console.error(err);
            });
        });
    });

    // Toggle notification inputs block based on checkbox status
    window.toggleNotifFields = function(type) {
        const chk = document.getElementById('notify-check-' + type);
        const fields = document.getElementById('notif-fields-' + type);
        if (chk && fields) {
            fields.style.display = chk.checked ? 'block' : 'none';
        }
    };

    // Auto-populate notification description from short extract of compliance text
    document.querySelectorAll('textarea[name="text_content"]').forEach(textarea => {
        textarea.addEventListener('input', function() {
            const form = this.closest('form');
            const type = form.querySelector('input[name="type"]').value;
            const bodyTextarea = form.querySelector('#notif-body-' + type);
            
            if (bodyTextarea && (!bodyTextarea.dataset.manuallyEdited || bodyTextarea.value === '')) {
                let text = this.value.trim();
                // Strip HTML tags if any
                text = text.replace(/<[^>]*>/g, '');
                if (text.length > 70) {
                    text = text.substring(0, 70) + '...';
                }
                if (text) {
                    bodyTextarea.value = text;
                } else {
                    bodyTextarea.value = '';
                }
            }
        });
    });

    // Track if admin edited the notification message manually
    document.querySelectorAll('.notif-body-textarea').forEach(textarea => {
        textarea.addEventListener('input', function() {
            this.dataset.manuallyEdited = 'true';
        });
    });

    // Handles manual resend notification
    window.resendNotification = function(appId, type) {
        if (!confirm('Are you sure you want to resend the compliance push notification to the user?')) {
            return;
        }

        const form = document.querySelector('#tab-' + type + ' form');
        const notifTitle = form.querySelector('input[name="notif_title"]').value;
        const notifBody = form.querySelector('textarea[name="notif_body"]').value;

        const formData = new FormData();
        formData.append('action', 'RESEND_NOTIFICATION');
        formData.append('app_id', appId);
        formData.append('type', type);
        formData.append('notif_title', notifTitle);
        formData.append('notif_body', notifBody);

        fetch('compliance.php', {
            method: 'POST',
            body: formData
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                alert(data.message);
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(err => {
            alert('An error occurred while resending.');
            console.error(err);
        });
    };
</script>
</body>
</html>
