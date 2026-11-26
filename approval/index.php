<?php
/**
 * Neon Finance - IP Approval Portal (/approval)
 * Allows adding an IP address to the admin access whitelist.
 */

require_once '../api/db_helper.php';

$clientIp = get_client_ip();
$error = '';
$successMsg = '';
$inputIp = $clientIp;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $ip = isset($_POST['ip']) ? trim($_POST['ip']) : '';
    $inputIp = $ip;

    if (empty($ip)) {
        $error = 'IP Address field cannot be empty.';
    } elseif (!filter_var($ip, FILTER_VALIDATE_IP)) {
        $error = 'Please enter a valid IPv4 or IPv6 address.';
    } else {
        try {
            $existingIps = get_whitelisted_ips();
            if (in_array($ip, $existingIps, true)) {
                $successMsg = 'IP address ' . htmlspecialchars($ip) . ' is already whitelisted for admin access.';
            } else {
                $res = add_whitelisted_ip($ip);
                if ($res) {
                    try {
                        log_admin_activity('APPROVAL_PORTAL', 'ADD_IP_WHITELIST', "Added IP to whitelist via /approval: $ip");
                    } catch (Exception $logEx) {
                        error_log('Failed to log /approval whitelist action: ' . $logEx->getMessage());
                    }
                    $successMsg = 'Successfully added IP address ' . htmlspecialchars($ip) . ' to the admin whitelist.';
                } else {
                    $error = 'Failed to add IP address to the whitelist.';
                }
            }
        } catch (Exception $e) {
            $error = 'Database error: ' . htmlspecialchars($e->getMessage());
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - IP Approval</title>

    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="../admin/admin_neon.css">
    <link rel="icon" type="image/png" href="../admin/favicon.png">

    <style>
        body.approval-page {
            background-color: #f1f5f9 !important;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            font-family: 'Plus Jakarta Sans', sans-serif;
            padding: 16px;
        }
        .approval-box {
            width: 100%;
            max-width: 440px;
        }
        .approval-logo img {
            height: 42px;
            margin-bottom: 12px;
        }
        .approval-logo a {
            color: #0f172a !important;
            font-weight: 800;
            font-size: 1.7rem;
            letter-spacing: -0.5px;
        }
        .approval-card {
            background-color: #ffffff !important;
            border: 1px solid #e2e8f0 !important;
            border-radius: 16px !important;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08) !important;
            padding: 32px !important;
        }
        .detected-ip-banner {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 10px 14px;
            font-size: 0.875rem;
            color: #334155;
        }
    </style>
</head>
<body class="hold-transition approval-page">
<div class="approval-box">
    <div class="approval-logo text-center mb-4">
        <a href="../admin/login.php" class="d-flex align-items-center justify-content-center gap-2">
            <img src="../assets/7PzcYdFs3fE3HNk64pDrpdmsSOk.svg" alt="Neon Logo" onerror="this.src='../logo.png';">
            <span><span style="color: #ff0054;">neon</span> approval</span>
        </a>
    </div>

    <div class="card approval-card">
        <h5 class="font-weight-bold text-center mb-2" style="color: #0f172a;">Admin IP Whitelist Approval</h5>
        <p class="text-muted text-center small mb-4">
            Enter an IPv4 or IPv6 address to authorize access to the admin panel.
        </p>

        <div class="detected-ip-banner d-flex align-items-center justify-content-between mb-3">
            <span><i class="fas fa-network-wired mr-2 text-primary"></i>Your IP: <strong id="detected-ip"><?= htmlspecialchars($clientIp) ?></strong></span>
            <button type="button" class="btn btn-xs btn-outline-primary font-weight-bold" onclick="document.getElementById('ip-input').value = document.getElementById('detected-ip').innerText;">
                Use My IP
            </button>
        </div>

        <?php if (!empty($error)): ?>
            <div class="alert alert-danger small" role="alert">
                <i class="fas fa-ban mr-1"></i> <?= $error ?>
            </div>
        <?php endif; ?>

        <?php if (!empty($successMsg)): ?>
            <div class="alert alert-success small" role="alert">
                <i class="fas fa-check-circle mr-1"></i> <?= $successMsg ?>
            </div>
        <?php endif; ?>

        <form method="post" action="">
            <div class="form-group">
                <label for="ip-input" class="font-weight-bold small text-dark">IP Address to Approve</label>
                <div class="input-group">
                    <input type="text" id="ip-input" name="ip" class="form-control" value="<?= htmlspecialchars($inputIp) ?>" placeholder="e.g. 203.0.113.45" required>
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas fa-shield-alt"></span>
                        </div>
                    </div>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-block font-weight-bold py-2 mt-3">
                <i class="fas fa-plus-circle mr-1"></i> Add IP to Admin Access
            </button>
        </form>

        <div class="text-center mt-4 pt-3 border-top">
            <a href="../admin/login.php" class="small font-weight-bold">
                <i class="fas fa-arrow-right mr-1"></i> Go to Admin Login
            </a>
        </div>
    </div>
</div>
</body>
</html>

