<?php
/**
 * FirstRand Bank Onboarding - Submit Application API
 * Receives form POST, decodes and saves base64 captures, and saves database record
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
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
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid Request Body.']);
    exit;
}

// Auto-fill national_id <-> aadhaar_number compatibility
if (empty($data['aadhaar_number']) && !empty($data['national_id'])) {
    $data['aadhaar_number'] = $data['national_id'];
}
if (empty($data['national_id']) && !empty($data['aadhaar_number'])) {
    $data['national_id'] = $data['aadhaar_number'];
}

// Basic validation for common fields
$requiredCommon = [
    'account_type', 'full_name', 'email', 'phone', 'address', 'national_id',
    'signature_data', 'portrait_data', 'doc_pan_data', 'doc_aadhaar_data'
];
foreach ($requiredCommon as $field) {
    if (empty($data[$field])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Field ' . str_replace('_', ' ', $field) . ' is required.']);
        exit;
    }
}

// Type-specific validation
if ($data['account_type'] === 'SAVINGS' || $data['account_type'] === 'NRI' || $data['account_type'] === 'JOINT' || $data['account_type'] === 'INVEST') {
    $requiredSavings = ['dob', 'gender', 'initial_deposit'];
    foreach ($requiredSavings as $field) {
        if (empty($data[$field])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Field ' . str_replace('_', ' ', $field) . ' is required for ' . htmlspecialchars($data['account_type']) . ' Account.']);
            exit;
        }
    }
} elseif ($data['account_type'] === 'CURRENT' || $data['account_type'] === 'CORPORATE') {
    // If business fields not submitted (e.g. from universal onboarding form), set intelligent defaults
    if (empty($data['business_name'])) {
        $data['business_name'] = !empty($data['full_name']) ? ($data['full_name'] . ' Enterprise') : 'Commercial Operations';
    }
    if (empty($data['business_reg_no'])) {
        $data['business_reg_no'] = !empty($data['national_id']) ? $data['national_id'] : ('CHE-' . rand(100000, 999999));
    }
    if (empty($data['expected_turnover'])) {
        $data['expected_turnover'] = !empty($data['initial_deposit']) ? ((float)$data['initial_deposit'] * 12) : 50000;
    }
} else {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid account type selected.']);
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
    // Generate a temporary unique application ID to prefix saved filenames
    $appId = 'FR-' . str_pad(mt_rand(100000, 999999), 6, '0', STR_PAD_LEFT);

    // Save images
    $sigPath = save_base64_image($data['signature_data'], 'sig_' . $appId . '.png');
    $photoPath = save_base64_image($data['portrait_data'], 'portrait_' . $appId . '.jpg');
    $panPath = save_base64_image($data['doc_pan_data'], 'pan_' . $appId . '.jpg');
    $aadhaarPath = save_base64_image($data['doc_aadhaar_data'], 'aadhaar_' . $appId . '.jpg');

    if (!$sigPath || !$photoPath || !$panPath || !$aadhaarPath) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Failed to process biometric captures. Please try retaking them.']);
        exit;
    }

    // Attach paths to database model
    $dbData = $data;
    $dbData['app_id'] = $appId; // Override / force generated ID
    $dbData['signature_path'] = $sigPath;
    $dbData['photo_path'] = $photoPath;
    $dbData['doc_pan_path'] = $panPath;
    $dbData['doc_aadhaar_path'] = $aadhaarPath;

    // Save to DB
    $savedAppId = save_application($dbData);

    // Send email notification
    try {
        require_once 'email_service.php';
        EmailService::sendApplicationReviewEmail($dbData['email'], $dbData['full_name'], $savedAppId);
    } catch (Exception $mailEx) {
        error_log("Failed to send application review email: " . $mailEx->getMessage());
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'app_id' => $savedAppId,
        'message' => 'Your application has been received and is currently in review. Please save your application ID.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while saving your application: ' . $e->getMessage()
    ]);
}
