<?php
/**
 * Deccan Finance - Login with Biometric Token API
 * Scope: Public
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method Not Allowed. Only POST requests are allowed.']);
    exit;
}

// Get POST or JSON payload
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// Validation
if (empty($data['biometric_token'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'biometric_token is required.']);
    exit;
}

$token = trim($data['biometric_token']);

try {
    // Lookup token in user_biometrics table
    $biometric = get_biometric_record($token);
    
    if (!$biometric) {
        log_user_login('BIOMETRIC', null, 'FAILED', 'Biometric token not found/registered');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid biometric credentials. Device not bound.']);
        exit;
    }
    
    $appId = $biometric['app_id'];
    
    // Load customer profile details
    $application = get_application_by_id($appId);
    if (!$application) {
        log_user_login('BIOMETRIC', $appId, 'FAILED', 'Customer application profile not found for biometric token');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Associated customer profile not found.']);
        exit;
    }
    
    // Fetch account details to check if biometric login is enabled
    $account = get_account_by_app_id($appId);
    if (!$account || empty($account['biometric_login_enabled'])) {
        log_user_login($application['phone'], $appId, 'FAILED', 'Biometric login is disabled by user.');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Biometric login is disabled by user.']);
        exit;
    }
    
    // Start session with a 365-day lifetime
    if (session_status() === PHP_SESSION_NONE) {
        ini_set('session.cookie_lifetime', 31536000);
        ini_set('session.gc_maxlifetime', 31536000);
        session_set_cookie_params([
            'lifetime' => 31536000,
            'path' => '/',
            'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
            'httponly' => true,
            'samesite' => 'Lax'
        ]);
        session_start();
    }
    
    $_SESSION['customer_logged_in'] = true;
    $_SESSION['customer_app_id'] = $application['app_id'];
    $_SESSION['customer_phone'] = $application['phone'];
    $_SESSION['customer_name'] = $application['full_name'];
    
    // Update FCM token if provided in request (support different parameter name variations)
    $fcmToken = null;
    if (!empty($data['fcm_token'])) {
        $fcmToken = trim($data['fcm_token']);
    } elseif (!empty($data['fmc_token'])) {
        $fcmToken = trim($data['fmc_token']);
    } elseif (!empty($data['fcmToken'])) {
        $fcmToken = trim($data['fcmToken']);
    } elseif (!empty($data['fmcToken'])) {
        $fcmToken = trim($data['fmcToken']);
    }
    
    if ($fcmToken !== null) {
        update_fcm_token($application['app_id'], $fcmToken);
    }
    
    // Clean response data
    $safeDetails = [
        'app_id' => $application['app_id'],
        'account_type' => $application['account_type'],
        'full_name' => $application['full_name'],
        'email' => $application['email'],
        'phone' => $application['phone'],
        'balance' => (float)$application['balance'],
        'status' => $application['status']
    ];
    
    log_user_login($application['phone'], $application['app_id'], 'SUCCESS', 'Authenticated using Biometrics on device: ' . ($biometric['device_name'] ?: 'Unknown'));
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Authentication successful.',
        'session_id' => session_id(),
        'user' => $safeDetails
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred during authentication: ' . $e->getMessage()
    ]);
}
