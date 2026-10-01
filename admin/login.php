<?php
/**
 * Neon Finance - Secure Admin Login
 * Authenticates admin credentials and initiates session authorization
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

// If already logged in, redirect to dashboard
if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    header('Location: dashboard.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username']);
    $password = $_POST['password'];

    if (empty($username) || empty($password)) {
        $error = 'Please enter both username and password.';
    } else {
        $res = authenticate_admin($username, $password);
        if ($res['success']) {
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['admin_user'] = $res['user']['username'];
            
            // Log successful login
            log_admin_activity($username, 'LOGIN_SUCCESS', 'Admin logged in successfully');
            
            header('Location: dashboard.php');
            exit;
        } else {
            // Log failed login
            log_admin_activity($username, 'LOGIN_FAILED', 'Failed login attempt (Invalid credentials)');
            $error = $res['message'];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Neon Finance - Admin Login</title>

    <!-- Google Font: Plus Jakarta Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=fallback">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- Theme style -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="admin_neon.css">

    <style>
        body.login-page {
            background-color: #f1f5f9 !important;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .login-box {
            width: 400px;
        }
        .login-logo img {
            height: 42px;
            margin-bottom: 12px;
        }
        .login-logo a {
            color: #0f172a !important;
            font-weight: 800;
            font-size: 1.8rem;
            letter-spacing: -0.5px;
        }
        .login-card-body {
            background-color: #ffffff !important;
            border: 1px solid #e2e8f0 !important;
            border-radius: 16px !important;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08) !important;
            padding: 32px !important;
        }
        .login-box-msg {
            color: #64748b !important;
            font-size: 0.95rem;
            margin-bottom: 24px;
        }
        .input-group-text {
            background-color: #f8fafc !important;
            border: 1px solid #cbd5e1 !important;
            border-left: none !important;
            color: #ff0054 !important;
        }
        .form-control {
            border-right: none !important;
        }
    </style>
</head>
<body class="hold-transition login-page">
<div class="login-box">
    <div class="login-logo text-center mb-4">
        <a href="#" class="d-flex align-items-center justify-content-center gap-2">
            <img src="../assets/7PzcYdFs3fE3HNk64pDrpdmsSOk.svg" alt="Neon Logo" onerror="this.src='../logo.png';">
            <span><span style="color: #ff0054;">neon</span> admin</span>
        </a>
    </div>
    <!-- /.login-logo -->
    <div class="card">
        <div class="card-body login-card-body">
            <p class="login-box-msg text-center">Sign in to start your administrator session</p>

            <?php if (!empty($error)): ?>
                <div class="alert alert-danger alert-dismissible" style="background-color: rgba(239, 68, 68, 0.2); border: 1px solid #ef4444; color: #fca5a5;">
                    <button type="button" class="close" data-dismiss="alert" aria-hidden="true" style="color:#ffffff;">&times;</button>
                    <i class="icon fas fa-ban mr-1"></i> <?= htmlspecialchars($error) ?>
                </div>
            <?php endif; ?>

            <form action="login.php" method="post">
                <div class="input-group mb-3">
                    <input type="text" name="username" class="form-control" placeholder="Username" required>
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas fa-user"></span>
                        </div>
                    </div>
                </div>
                <div class="input-group mb-4">
                    <input type="password" name="password" class="form-control" placeholder="Password" required>
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas fa-lock"></span>
                        </div>
                    </div>
                </div>
                <div class="row align-items-center mt-4">
                    <div class="col-6">
                        <a href="register.php" class="small font-weight-bold" style="color: #00f2fe;">Register Admin</a>
                    </div>
                    <!-- /.col -->
                    <div class="col-6">
                        <button type="submit" class="btn btn-primary btn-block">Sign In</button>
                    </div>
                    <!-- /.col -->
                </div>
            </form>
        </div>
        <!-- /.login-card-body -->
    </div>
</div>
<!-- /.login-box -->

<!-- jQuery -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<!-- Bootstrap 4 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/4.6.1/js/bootstrap.bundle.min.js"></script>
<!-- AdminLTE App -->
<script src="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/js/adminlte.min.js"></script>
</body>
</html>
