<?php
/**
 * Safe Database Auto-Importer for Neon Finance
 * Reads schema.sql and imports tables into database "helnovexaa_neon".
 * Skips existing tables/columns/keys gracefully without breaking.
 */

define("DB_HOST", "localhost");
define("DB_NAME", "helnovexaa_neon");
define("DB_USER", "helnovexaa_neon");
define("DB_PASS", "Soumojit1234@");

header("Content-Type: text/plain");

try {
    echo "Connecting to MySQL server at " . DB_HOST . "...\n";
    $pdo = new PDO("mysql:host=" . DB_HOST . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Ensuring database '" . DB_NAME . "' exists...\n";
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `" . DB_NAME . "`");

    $sqlFile = __DIR__ . "/schema.sql";
    if (!file_exists($sqlFile)) {
        die("Error: schema.sql file not found at " . $sqlFile . "\n");
    }

    echo "Reading schema.sql...\n";
    $sqlContent = file_get_contents($sqlFile);

    // Convert all CREATE TABLE to CREATE TABLE IF NOT EXISTS
    $sqlContent = preg_replace('/CREATE TABLE\s+`([^`]+)`/i', 'CREATE TABLE IF NOT EXISTS `$1`', $sqlContent);

    // Split SQL into individual statements
    $queries = preg_split('/;\s*[\r\n]+/', $sqlContent);

    $successCount = 0;
    $skippedCount = 0;

    echo "Executing database queries safely...\n\n";

    foreach ($queries as $query) {
        $query = trim($query);
        if (empty($query) || preg_match('/^(?:--|\/\*|#)/', $query)) {
            continue;
        }

        try {
            $pdo->exec($query);
            $successCount++;
        } catch (PDOException $e) {
            // Ignore "Table already exists", "Duplicate column", or "Duplicate key" errors
            $errorCode = $e->getCode();
            $errorMessage = $e->getMessage();
            if (
                strpos($errorMessage, 'already exists') !== false ||
                strpos($errorMessage, 'Duplicate column name') !== false ||
                strpos($errorMessage, 'Duplicate key name') !== false ||
                strpos($errorMessage, 'Multiple primary key defined') !== false ||
                $errorCode === '42S01' || $errorCode === '42000'
            ) {
                $skippedCount++;
            } else {
                echo "NOTICE: " . $errorMessage . "\n";
            }
        }
    }

    echo "\n--------------------------------------------------\n";
    echo "SUCCESS: Database sync completed for '" . DB_NAME . "'!\n";
    echo "Executed: $successCount queries\n";
    echo "Skipped (Already Exists): $skippedCount queries\n";
    echo "--------------------------------------------------\n";

} catch (Exception $e) {
    echo "ERROR importing database: " . $e->getMessage() . "\n";
}
