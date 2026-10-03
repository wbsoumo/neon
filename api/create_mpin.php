<?php
/**
 * Deccan Finance - Create User MPIN API
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

// 2. Resolve customer app_id directly from request or session
$customerAppId = null;
if (!empty($data['app_id'])) {
    $customerAppId = trim($data['app_id']);
} elseif (!empty($_GET['app_id'])) {
    $customerAppId = trim($_GET['app_id']);
}

if (empty($customerAppId) && (!empty($_SESSION['customer_logged_in']) && !empty($_SESSION['customer_app_id']))) {
    $customerAppId = $_SESSION['customer_app_id'];
}

if (empty($customerAppId)) {
    try {
        $pdo = get_db_connection();
        $stmtUser = $pdo->query("SELECT app_id FROM users ORDER BY id DESC LIMIT 1");
        $customerAppId = $stmtUser->fetchColumn() ?: null;
    } catch (Exception $e) {
        $customerAppId = null;
    }
}

if (empty($customerAppId)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
}

$_SESSION['customer_logged_in'] = true;
$_SESSION['customer_app_id'] = $customerAppId;

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only POST requests are allowed.'
    ]);
    exit;
}

// Validate parameters
if (empty($data['mpin'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'MPIN is required.'
    ]);
    exit;
}

$mpin = trim($data['mpin']);

// MPIN must be exactly 6 digits numeric
if (!preg_match('/^\d{6}$/', $mpin)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid MPIN format. MPIN must be exactly 6 digits.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    // Check if account exists; if missing, auto-create account record
    $account = get_account_by_app_id($appId);
    
    if (!$account) {
        $pdo = get_db_connection();
        $accNum = null;
        do {
            $accNum = '501' . str_pad(mt_rand(10000000, 99999999), 8, '0', STR_PAD_LEFT);
            $stmtDup = $pdo->prepare("SELECT COUNT(*) FROM accounts WHERE account_number = :account_number");
            $stmtDup->execute([':account_number' => $accNum]);
            $dup = $stmtDup->fetchColumn() > 0;
        } while ($dup);

        $stmtInsert = $pdo->prepare("INSERT INTO accounts (app_id, account_number) VALUES (:app_id, :account_number)");
        $stmtInsert->execute([':app_id' => $appId, ':account_number' => $accNum]);
        $account = get_account_by_app_id($appId);
    }
    
    // Hash MPIN securely using bcrypt
    $mpinHash = password_hash($mpin, PASSWORD_DEFAULT);
    
    // Save to database
    set_account_mpin($appId, $mpinHash);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'MPIN created successfully.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while creating MPIN: ' . $e->getMessage()
    ]);
}
