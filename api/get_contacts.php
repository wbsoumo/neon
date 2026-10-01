<?php
/**
 * Deccan Finance - Get Synchronized Contacts API
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
        'message' => 'Unauthorized. Please log in to retrieve contacts.'
    ]);
    exit;
}

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method Not Allowed. Only GET requests are allowed.'
    ]);
    exit;
}

$appId = $_SESSION['customer_app_id'];

try {
    $contacts = get_contacts_by_app_id($appId);
    
    // Format contacts to match the exact uploaded format
    $formattedContacts = [];
    foreach ($contacts as $contact) {
        $formattedContacts[] = [
            'name' => $contact['name'],
            'phone' => $contact['phone']
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'contacts' => $formattedContacts
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while retrieving contacts: ' . $e->getMessage()
    ]);
}
