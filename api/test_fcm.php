<?php
/**
 * Test FCM Notification Dispatcher Script
 * Executes send_fcm_notification locally and prints exact response/logs
 */

header('Content-Type: application/json');
require_once __DIR__ . '/db_helper.php';

$appId = isset($_GET['app_id']) ? trim($_GET['app_id']) : 'FR-569609';
$title = isset($_GET['title']) ? trim($_GET['title']) : 'Neon Bank Test Alert';
$body = isset($_GET['body']) ? trim($_GET['body']) : 'This is a live high priority test notification dispatched from API script!';

try {
    $application = get_application_by_id($appId);
    if (!$application) {
        echo json_encode(['success' => false, 'message' => "Application $appId not found."]);
        exit;
    }

    $fcmToken = !empty($application['fcm_token']) ? $application['fcm_token'] : (!empty($application['fmc_token']) ? $application['fmc_token'] : null);
    
    if (empty($fcmToken) || $fcmToken === 'NOT_REGISTERED') {
        echo json_encode([
            'success' => false,
            'message' => "No FCM token registered for application $appId in local DB.",
            'user' => $application['full_name']
        ]);
        exit;
    }

    $res = send_fcm_notification($fcmToken, $title, $body, ['app_id' => $appId, 'test' => 'true'], null, 'Transactions');

    echo json_encode([
        'success' => true,
        'message' => 'FCM notification dispatch executed.',
        'target_app_id' => $appId,
        'user' => $application['full_name'],
        'fcm_token' => $fcmToken,
        'fcm_dispatch_result' => $res
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
