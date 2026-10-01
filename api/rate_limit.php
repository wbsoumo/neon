<?php
/**
 * FirstRand Bank Onboarding - Rate Limit API
 * Verifies client IP rate of requests
 */

header('Content-Type: application/json');
require_once 'db_helper.php';

$ip = get_client_ip();

// Check if rate limited: maximum 3 requests within 10 seconds
if (is_rate_limited($ip, 3, 10)) {
    http_response_code(429);
    echo json_encode([
        'success' => false,
        'error' => 'rate_limited',
        'message' => 'Security Threat Detected: Too many requests from this IP in a short period. Access temporarily throttled.'
    ]);
} else {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'IP verified. No security threats detected. Establishing secure connection tunnel...',
        'ip' => $ip
    ]);
}
