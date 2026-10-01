<?php
/**
 * Deccan Finance - Secure Admin Logout
 * Destroys the admin session and redirects to the login screen
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

$username = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : 'Unknown';

// Log logout event
log_admin_activity($username, 'LOGOUT', 'Admin logged out');

// Unset all session variables
$_SESSION = array();

// Destroy session cookie if set
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// Destroy session
session_destroy();

// Redirect to login page
header("Location: login.php");
exit;
?>
