<?php
/**
 * Deccan Finance - Get Customer User Details API
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

$appId = $_SESSION['customer_app_id'];

try {
    $user = get_application_by_id($appId);
    
    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User details not found.'
        ]);
        exit;
    }
    
    // Remove sensitive data (like password_hash)
    unset($user['password_hash']);
    
    // Merge account number and mpin setup status if available
    $account = get_account_by_app_id($appId);
    
    // Set fallback tokens from applications table first
    $user['fcm_token'] = isset($user['fcm_token']) ? $user['fcm_token'] : null;
    $user['fmc_token'] = isset($user['fmc_token']) ? $user['fmc_token'] : null;
    
    if ($account) {
        $user['account_number'] = $account['account_number'];
        $user['has_mpin'] = !empty($account['mpin_hash']);
        $user['mpin'] = !empty($account['mpin_hash']) ? "CREATED" : "NOT_CREATED";
        $user['mpin_hash'] = $account['mpin_hash'];
        $user['has_login_pin'] = !empty($account['login_pin_hash']);
        $user['pin_login_enabled'] = isset($account['pin_login_enabled']) ? (bool)$account['pin_login_enabled'] : false;
        $user['biometric_login_enabled'] = isset($account['biometric_login_enabled']) ? (bool)$account['biometric_login_enabled'] : false;
        if (!empty($account['fcm_token'])) {
            $user['fcm_token'] = $account['fcm_token'];
        }
        if (!empty($account['fmc_token'])) {
            $user['fmc_token'] = $account['fmc_token'];
        }
    } else {
        $user['account_number'] = null;
        $user['has_mpin'] = false;
        $user['mpin'] = "NOT_CREATED";
        $user['mpin_hash'] = null;
        $user['has_login_pin'] = false;
        $user['pin_login_enabled'] = false;
        $user['biometric_login_enabled'] = false;
    }

    $user['has_biometric'] = has_user_biometric($appId);
    
    // Convert numeric fields to correct types
    if (isset($user['initial_deposit'])) {
        $user['initial_deposit'] = (float)$user['initial_deposit'];
    }
    if (isset($user['balance'])) {
        $user['balance'] = (float)$user['balance'];
    }
    if (isset($user['expected_turnover'])) {
        $user['expected_turnover'] = (float)$user['expected_turnover'];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'user' => $user
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while retrieving user details: ' . $e->getMessage()
    ]);
}
