<?php
/**
 * Deccan Finance - Verify Aadhaar Last 6 Digits API
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

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only POST requests are allowed.'
    ]);
    exit;
}

// Validate Aadhaar parameter
if (empty($data['aadhaar_last_6'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Aadhaar last 6 digits are required.'
    ]);
    exit;
}

$aadhaarLast6Input = trim($data['aadhaar_last_6']);

// Aadhaar last 6 digits must be exactly 6 digits numeric
if (!preg_match('/^\d{6}$/', $aadhaarLast6Input)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid Aadhaar verification format. Must be exactly 6 digits.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    // Fetch application details to verify Aadhaar digits
    $app = get_application_by_id($appId);
    if (!$app || empty($app['aadhaar_number'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Registered Aadhaar number not found.'
        ]);
        exit;
    }
    
    // Compare last 6 digits of registered Aadhaar with input
    $registeredAadhaar = str_replace([' ', '-'], '', $app['aadhaar_number']);
    $registeredLast6 = substr($registeredAadhaar, -6);
    
    if ($aadhaarLast6Input !== $registeredLast6) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Aadhaar verification failed. Digits do not match.'
        ]);
        exit;
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Aadhaar verified successfully.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while verifying Aadhaar: ' . $e->getMessage()
    ]);
}
