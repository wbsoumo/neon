<?php
/**
 * Deccan Finance - Get User Notifications API
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

// Allow both GET and POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only GET or POST requests are allowed.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

// Check for optional category filter
$category = null;
if (!empty($data['category'])) {
    $category = trim($data['category']);
} elseif (!empty($_GET['category'])) {
    $category = trim($_GET['category']);
}

try {
    $notifications = get_notifications_by_app_id($appId, $category);
    
    $formatted = [];
    foreach ($notifications as $n) {
        $formatted[] = [
            'id' => (int)$n['id'],
            'title' => $n['title'],
            'body' => $n['body'],
            'image_url' => $n['image_url'],
            'category' => $n['category'],
            'sent_status' => $n['sent_status'],
            'created_at' => $n['created_at']
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'notifications' => $formatted
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while retrieving notifications: ' . $e->getMessage()
    ]);
}
