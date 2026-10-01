<?php
/**
 * Deccan Finance - Toggle Login Settings API
 * Scope: Authenticated Customer Session (Approved Account)
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Get request parameters (POST/JSON/GET)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// Resolve session ID if passed explicitly
$passedSessionId = null;
if (!empty($data['session_id'])) {
    $passedSessionId = trim($data['session_id']);
} elseif (!empty($_GET['session_id'])) {
    $passedSessionId = trim($_GET['session_id']);
}

// Check headers for X-Session-ID or Authorization bearer
$headers = function_exists('getallheaders') ? getallheaders() : [];
if (empty($passedSessionId)) {
    if (!empty($headers['X-Session-ID'])) {
        $passedSessionId = trim($headers['X-Session-ID']);
    } elseif (!empty($headers['x-session-id'])) {
        $passedSessionId = trim($headers['x-session-id']);
    } elseif (!empty($_SERVER['HTTP_X_SESSION_ID'])) {
        $passedSessionId = trim($_SERVER['HTTP_X_SESSION_ID']);
    } elseif (!empty($headers['Authorization'])) {
        $auth = trim($headers['Authorization']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    } elseif (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = trim($_SERVER['HTTP_AUTHORIZATION']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    }
}

// If explicit session ID is provided, load it
if (!empty($passedSessionId)) {
    session_id($passedSessionId);
}

// Start PHP session
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check if customer is logged in
if (empty($_SESSION['customer_logged_in']) || empty($_SESSION['customer_app_id'])) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only POST requests are allowed.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    // Check if account exists
    $account = get_account_by_app_id($appId);
    if (!$account) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Account not yet approved.'
        ]);
        exit;
    }

    // Determine values to write (0 or 1)
    $pinEnabled = isset($data['pin_login_enabled']) ? (int)$data['pin_login_enabled'] : (int)$account['pin_login_enabled'];
    $biometricEnabled = isset($data['biometric_login_enabled']) ? (int)$data['biometric_login_enabled'] : (int)$account['biometric_login_enabled'];

    // Update settings
    update_login_settings($appId, $pinEnabled, $biometricEnabled);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Login settings updated successfully.',
        'settings' => [
            'pin_login_enabled' => (bool)$pinEnabled,
            'biometric_login_enabled' => (bool)$biometricEnabled
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while updating login settings: ' . $e->getMessage()
    ]);
}
