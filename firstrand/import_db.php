<?php
/**
 * Database Auto-Importer for Neon Finance
 * Reads schema.sql and imports tables into database "helnovexaa_neon"
 */

define("DB_HOST", "localhost");
define("DB_NAME", "helnovexaa_neon");
define("DB_USER", "helnovexaa_neon");
define("DB_PASS", "Soumojit1234@");

header("Content-Type: text/plain");

try {
    echo "Connecting to MySQL server at " . DB_HOST . "...
";
    $pdo = new PDO("mysql:host=" . DB_HOST . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Ensuring database '" . DB_NAME . "' exists...
";
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `" . DB_NAME . "`");

    $sqlFile = __DIR__ . "/schema.sql";
    if (!file_exists($sqlFile)) {
        die("Error: schema.sql file not found at " . $sqlFile . "
");
    }

    echo "Reading schema.sql...
";
    $sql = file_get_contents($sqlFile);

    echo "Importing table structure...
";
    $pdo->exec($sql);

    echo "SUCCESS: Database schema imported successfully into '" . DB_NAME . "'!
";
} catch (Exception $e) {
    echo "ERROR importing database: " . $e->getMessage() . "
";
}
