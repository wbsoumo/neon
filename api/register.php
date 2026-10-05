<?php
/**
 * Deccan Finance - Register Application API
 * Receives form POST, decodes and saves base64 captures, hashes the password, and saves database record
 */

ob_start();
header('Content-Type: application/json');
require_once 'db_helper.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ob_clean();
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method Not Allowed.']);
    exit;
}

// Get POST or JSON payload
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
}

if (!$data) {
    ob_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid Request Body.']);
    exit;
}

// Basic validation for mandatory credentials
$requiredCommon = ['account_type', 'full_name', 'email', 'phone', 'password'];
foreach ($requiredCommon as $field) {
    if (empty($data[$field])) {
        ob_clean();
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Field ' . str_replace('_', ' ', $field) . ' is required.']);
        exit;
    }
}

// Check if phone/mobile already registered
$pdo = get_db_connection();
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM applications WHERE phone = :phone");
$stmt->execute([':phone' => $data['phone']]);
if ($stmt->fetch()['count'] > 0) {
    ob_clean();
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'An account is already registered with this mobile number.']);
    exit;
}

// Helper to decode and save base64 images to server files
function save_base64_image($base64String, $filename) {
    if (empty($base64String)) return null;

    $parts = explode(',', $base64String);
    if (count($parts) < 2) return null;

    $rawData = base64_decode($parts[1]);
    if ($rawData === false) return null;

    $uploadsDir = dirname(__DIR__) . '/uploads';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0777, true);
    }

    $filePath = $uploadsDir . '/' . $filename;
    file_put_contents($filePath, $rawData);

    // Return the relative path for database storage
    return 'uploads/' . $filename;
}

try {
    // Generate a unique application ID
    $appId = 'FR-' . str_pad(mt_rand(100000, 999999), 6, '0', STR_PAD_LEFT);

    // Save images dynamically based on provided fields
    $sigPath = !empty($data['signature_data']) ? save_base64_image($data['signature_data'], 'sig_' . $appId . '.png') : null;
    $photoPath = !empty($data['portrait_data']) ? save_base64_image($data['portrait_data'], 'portrait_' . $appId . '.jpg') : null;
    $panPath = !empty($data['doc_pan_data']) ? save_base64_image($data['doc_pan_data'], 'doc_id_' . $appId . '.jpg') : null;
    $aadhaarPath = !empty($data['doc_aadhaar_data']) ? save_base64_image($data['doc_aadhaar_data'], 'doc_addr_' . $appId . '.jpg') : null;
    $proofAddrPath = !empty($data['doc_proof_address_data']) ? save_base64_image($data['doc_proof_address_data'], 'proof_addr_' . $appId . '.jpg') : null;

    // Attach paths to data
    $dbData = $data;
    $dbData['app_id'] = $appId;
    $dbData['signature_path'] = $sigPath;
    $dbData['photo_path'] = $photoPath;
    $dbData['doc_pan_path'] = $panPath;
    $dbData['doc_aadhaar_path'] = $aadhaarPath;
    $dbData['doc_proof_address_path'] = $proofAddrPath;
    $dbData['password_hash'] = $data['password'];

    // Save to DB
    $savedAppId = save_application($dbData);

    // Send email notification
    try {
        require_once 'email_service.php';
        EmailService::sendApplicationReviewEmail($dbData['email'], $dbData['full_name'], $savedAppId);
    } catch (Exception $mailEx) {
        error_log("Failed to send application review email: " . $mailEx->getMessage());
    }

    ob_clean();
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'app_id' => $savedAppId,
        'message' => 'Your account has been registered and is currently in review. Please save your application ID.'
    ]);
} catch (Exception $e) {
    ob_clean();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while registering your account: ' . $e->getMessage()
    ]);
}
