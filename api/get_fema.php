<?php
/**
 * Deccan Finance - Get FEMA (Foreign Exchange Management Act) details for user
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
    $compliance = get_user_compliance($appId, 'fema');
    
    // Resolve absolute project base URL for uploads
    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
    $host = $_SERVER['HTTP_HOST'];
    $scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME']);
    $projectDir = '';
    if (strpos($scriptName, '/api/') !== false) {
        $projectDir = substr($scriptName, 0, strpos($scriptName, '/api/'));
    } else {
        $projectDir = dirname($scriptName);
    }
    $projectDir = rtrim(str_replace('\\', '/', $projectDir), '/');
    $baseUrl = $protocol . '://' . $host . $projectDir;

    $text = '';
    $imageUrl = null;
    $pdfUrl = null;
    $createdAt = null;
    $updatedAt = null;

    if ($compliance) {
        $text = $compliance['text_content'] ?: '';
        if (!empty($compliance['image_path'])) {
            $imageUrl = $baseUrl . '/' . $compliance['image_path'];
        }
        if (!empty($compliance['pdf_path'])) {
            $pdfUrl = $baseUrl . '/' . $compliance['pdf_path'];
        }
        $createdAt = $compliance['created_at'];
        $updatedAt = $compliance['updated_at'];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'app_id' => $appId,
        'type' => 'fema',
        'text' => $text,
        'image_url' => $imageUrl,
        'pdf_url' => $pdfUrl,
        'created_at' => $createdAt,
        'updated_at' => $updatedAt
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while retrieving FEMA details: ' . $e->getMessage()
    ]);
}
