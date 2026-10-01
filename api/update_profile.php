<?php
/**
 * Deccan Finance - Update Customer Profile API
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

$appId = $_SESSION['customer_app_id'];

try {
    $currentUser = get_application_by_id($appId);
    
    if (!$currentUser) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User profile not found.'
        ]);
        exit;
    }
    
    // Updatable profile fields
    $updatableFields = [
        'full_name', 'email', 'phone', 'address', 'national_id', 'aadhaar_number',
        'dob', 'gender', 'business_name', 'business_reg_no', 'expected_turnover'
    ];
    
    $updateData = [];
    foreach ($updatableFields as $field) {
        if (isset($data[$field])) {
            $updateData[$field] = $data[$field];
        } else {
            $updateData[$field] = $currentUser[$field];
        }
    }
    
    // Check unique phone uniqueness constraint
    if ($updateData['phone'] !== $currentUser['phone']) {
        $pdo = get_db_connection();
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM applications WHERE phone = :phone AND app_id != :app_id");
        $stmt->execute([':phone' => $updateData['phone'], ':app_id' => $appId]);
        if ($stmt->fetch()['count'] > 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'The mobile number is already registered to another account.'
            ]);
            exit;
        }
    }
    
    // Check unique email uniqueness constraint
    if (!empty($updateData['email']) && $updateData['email'] !== $currentUser['email']) {
        $pdo = get_db_connection();
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM applications WHERE email = :email AND app_id != :app_id");
        $stmt->execute([':email' => $updateData['email'], ':app_id' => $appId]);
        if ($stmt->fetch()['count'] > 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'The email address is already registered to another account.'
            ]);
            exit;
        }
    }
    
    // Perform database update
    update_application_profile($appId, $updateData);
    
    // Refresh session data if they changed full_name or phone
    $_SESSION['customer_name'] = $updateData['full_name'];
    $_SESSION['customer_phone'] = $updateData['phone'];
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Profile updated successfully.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while updating profile: ' . $e->getMessage()
    ]);
}
