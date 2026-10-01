<?php
/**
 * Deccan Finance - Contact Batch Upload / Synchronization API
 * Scope: Authenticated Customer Session
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

// Start session if not already active
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Verify customer is logged in
if (empty($_SESSION['customer_logged_in']) || empty($_SESSION['customer_app_id'])) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in to synchronize contacts.'
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

// Retrieve raw POST request body payload
$json = file_get_contents('php://input');
$data = json_decode($json, true);

if ($data === null || !isset($data['contacts']) || !is_array($data['contacts'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid JSON payload. Expected a JSON object with a "contacts" array.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];
$contacts = $data['contacts'];

try {
    save_contacts($appId, $contacts);
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Contacts synchronized successfully.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred during synchronization: ' . $e->getMessage()
    ]);
}
