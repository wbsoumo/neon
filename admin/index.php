<?php
/**
 * Deccan Finance Limited Onboarding - Admin Home Redirection
 * Routes users to login or dashboard based on session, protected by IP Whitelisting
 */

require_once '../api/db_helper.php';

// Verify IP address whitelist
verify_ip_access();

session_start();

if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    header("Location: dashboard.php");
    exit;
} else {
    header("Location: login.php");
    exit;
}
?>
