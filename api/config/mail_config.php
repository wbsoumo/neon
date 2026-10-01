<?php
/**
 * Deccan Finance - AWS SES SMTP Mail Configuration
 * This file retrieves SMTP credentials from environment variables to avoid hardcoding,
 * falling back to placeholders.
 */

define('SMTP_HOST', getenv('SES_SMTP_HOST') ?: 'email-smtp.ap-south-1.amazonaws.com');
define('SMTP_PORT', (int)(getenv('SES_SMTP_PORT') ?: 587));
define('SMTP_USER', getenv('SES_SMTP_USER') ?: 'AKIAZQCLJUKKVTVDY5XO');
define('SMTP_PASS', getenv('SES_SMTP_PASS') ?: 'BJ++8JXLReFCMquR8nVA/mwOskwfxKR/kzAkojlJWAXJ');
define('SMTP_SECURE', getenv('SES_SMTP_SECURE') ?: 'tls'); // tls or ssl
define('SMTP_FROM_EMAIL', getenv('SES_SMTP_FROM') ?: 'support@deccanfinltd.world');
define('SMTP_FROM_NAME', getenv('SES_SMTP_FROM_NAME') ?: 'Deccan Finance Support');
