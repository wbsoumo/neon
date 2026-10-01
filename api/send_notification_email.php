<?php
/**
 * Deccan Finance - Automated Email Notification API
 * Trigger email notifications externally or internally using account number and notification type.
 */

header('Content-Type: application/json');
require_once 'db_helper.php';
require_once 'email_service.php';

// Accept request body
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$accountNumber = isset($data['account_number']) ? trim($data['account_number']) : '';
$type = isset($data['type']) ? strtolower(trim($data['type'])) : '';
$amount = isset($data['amount']) ? (float)$data['amount'] : null;
$reference = isset($data['reference']) ? trim($data['reference']) : null;
$remarks = isset($data['remarks']) ? trim($data['remarks']) : null;

if (empty($accountNumber)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameter: account_number'
    ]);
    exit;
}

if (!in_array($type, ['credit', 'debit', 'approved'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid notification type. Must be: credit, debit, or approved'
    ]);
    exit;
}

// Call Email Service
$res = EmailService::sendNotificationEmail($accountNumber, $type, $amount, $reference, $remarks);

if ($res['success']) {
    echo json_encode([
        'success' => true,
        'message' => 'Notification email sent successfully.'
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to send email. Details: ' . $res['message']
    ]);
}
