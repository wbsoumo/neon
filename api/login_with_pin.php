<?php
/**
 * Deccan Finance - Login with PIN API
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
$identity = '';
if (!empty($data['mobile'])) {
    $identity = trim($data['mobile']);
} elseif (!empty($data['email'])) {
    $identity = trim($data['email']);
} elseif (!empty($data['username'])) {
    $identity = trim($data['username']);
}

$pin = isset($data['pin']) ? trim($data['pin']) : '';

if (empty($identity) || empty($pin)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email/Mobile number and PIN are required.']);
    exit;
}

if (!preg_match('/^\d{4}$/', $pin)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid PIN format. PIN must be exactly 4 digits.']);
    exit;
}

try {
    $pdo = get_db_connection();
    
    // Extract digits for mobile lookup matching (last 10 digits)
    $cleanIdentityDigits = preg_replace('/\D/', '', $identity);
    $last10Digits = strlen($cleanIdentityDigits) >= 10 ? substr($cleanIdentityDigits, -10) : $cleanIdentityDigits;

    // Find application by phone number or email (supports matching last 10 digits regardless of country code)
    if (!empty($last10Digits) && !str_contains($identity, '@')) {
        $stmt = $pdo->prepare("
            SELECT * FROM applications 
            WHERE phone = :identity 
               OR email = :identity 
               OR RIGHT(REGEXP_REPLACE(phone, '[^0-9]', ''), 10) = :last10 
            LIMIT 1
        ");
        $stmt->execute([
            ':identity' => $identity,
            ':last10'   => $last10Digits
        ]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM applications WHERE phone = :identity OR email = :identity LIMIT 1");
        $stmt->execute([':identity' => $identity]);
    }
    $application = $stmt->fetch();
    
    if (!$application) {
        log_user_login($identity, null, 'FAILED', 'Account not found for provided credentials (PIN login)');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid email/mobile number or PIN.']);
        exit;
    }
    
    $appId = $application['app_id'];
    
    // Fetch account details
    $account = get_account_by_app_id($appId);
    if (!$account || empty($account['login_pin_hash'])) {
        log_user_login($identity, $appId, 'FAILED', 'Login PIN not set up for this account');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Login PIN is not set up for this account.']);
        exit;
    }
    
    // Check if PIN login is enabled
    if (empty($account['pin_login_enabled'])) {
        log_user_login($identity, $appId, 'FAILED', 'PIN login is disabled by user.');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'PIN login is disabled by user.']);
        exit;
    }
    
    // Verify login PIN using bcrypt
    if (!password_verify($pin, $account['login_pin_hash'])) {
        log_user_login($identity, $appId, 'FAILED', 'Incorrect Login PIN');
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid email/mobile number or PIN.']);
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
    
    log_user_login($identity, $application['app_id'], 'SUCCESS', 'Authenticated using Login PIN');
    
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
