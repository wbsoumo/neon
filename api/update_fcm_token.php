<?php
/**
 * Update FCM Token Endpoint
 * Public endpoint to store/sync user FCM push tokens
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method Not Allowed']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

$appId = !empty($data['app_id']) ? trim($data['app_id']) : (!empty($data['appId']) ? trim($data['appId']) : '');
$fcmToken = null;

if (!empty($data['fcm_token'])) {
    $fcmToken = trim($data['fcm_token']);
} elseif (!empty($data['fmc_token'])) {
    $fcmToken = trim($data['fmc_token']);
} elseif (!empty($data['fcmToken'])) {
    $fcmToken = trim($data['fcmToken']);
} elseif (!empty($data['fmcToken'])) {
    $fcmToken = trim($data['fmcToken']);
} elseif (!empty($data['token'])) {
    $fcmToken = trim($data['token']);
}

if (empty($appId) || empty($fcmToken)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'app_id and fcm_token are required.']);
    exit;
}

try {
    update_fcm_token($appId, $fcmToken);
    echo json_encode([
        'success' => true,
        'message' => 'FCM Token updated successfully',
        'app_id' => $appId,
        'fcm_token' => $fcmToken
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update FCM token: ' . $e->getMessage()
    ]);
}
