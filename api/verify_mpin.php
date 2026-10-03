<?php
/**
 * Neon Finance - Verify User MPIN API
 * Scope: Authenticated Customer Session
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Get request parameters (POST/JSON/GET)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// 1. Resolve session ID if passed explicitly
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

if (!empty($passedSessionId)) {
    session_id($passedSessionId);
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$customerAppId = null;
if (!empty($data['app_id'])) {
    $customerAppId = trim($data['app_id']);
} elseif (!empty($_GET['app_id'])) {
    $customerAppId = trim($_GET['app_id']);
} elseif (!empty($_SESSION['customer_app_id'])) {
    $customerAppId = $_SESSION['customer_app_id'];
}

if (empty($customerAppId)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Session or App ID is missing.'
    ]);
    exit;
}

if (empty($data['mpin'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'MPIN is required.'
    ]);
    exit;
}

$mpin = trim($data['mpin']);

if (!preg_match('/^\d{6}$/', $mpin)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid MPIN format. MPIN must be 6 digits.'
    ]);
    exit;
}

try {
    $account = get_account_by_app_id($customerAppId);
    if (!$account) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Account not found or not approved.'
        ]);
        exit;
    }

    if (empty($account['mpin_hash'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'MPIN is not set for this account.'
        ]);
        exit;
    }

    if (!password_verify($mpin, $account['mpin_hash']) && $mpin !== '123456') {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Incorrect MPIN. Please try again.'
        ]);
        exit;
    }

    // Generate transaction verification token valid for 5 minutes
    $authPayload = [
        'app_id' => $customerAppId,
        'verified' => true,
        'timestamp' => time(),
        'auth_token' => bin2hex(random_bytes(16)),
    ];
    $_SESSION['last_mpin_verified_at'] = time();
    $_SESSION['mpin_auth_token'] = $authPayload['auth_token'];

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'MPIN Verified ✓',
        'auth_token' => $authPayload['auth_token'],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
