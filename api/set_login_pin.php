<?php
/**
 * Deccan Finance - Set Login PIN API
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

// Validate parameter
if (empty($data['login_pin'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'login_pin is required.'
    ]);
    exit;
}

$pin = trim($data['login_pin']);

// Login PIN must be exactly 4 digits numeric
if (!preg_match('/^\d{4}$/', $pin)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid PIN format. PIN must be exactly 4 digits.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    // Check if account exists (only approved applications have account records)
    $account = get_account_by_app_id($appId);
    
    if (!$account) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Account not yet approved.'
        ]);
        exit;
    }
    
    // Hash PIN securely using bcrypt
    $pinHash = password_hash($pin, PASSWORD_DEFAULT);
    
    // Save to database
    set_account_login_pin($appId, $pinHash);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Login PIN configured successfully.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while setting Login PIN: ' . $e->getMessage()
    ]);
}
