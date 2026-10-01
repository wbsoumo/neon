<?php
/**
 * Deccan Finance Limited Onboarding - Database Helper
 * Handles SQLite connection and application storage/rate limiting
 */

if (strpos(__FILE__, '/var/www/html/') !== false) {
    // EC2 Production Credentials
    define('DB_HOST', 'localhost');
    define('DB_NAME', 'helnovexaa_neon');
    define('DB_USER', 'helnovexaa_neon');
    define('DB_PASS', 'Soumojit1234@');
} else {
    // Local XAMPP Credentials
    define('DB_HOST', 'localhost');
    define('DB_NAME', 'helnovexaa_neon');
    define('DB_USER', 'helnovexaa_neon');
    define('DB_PASS', 'Soumojit1234@');
}

function get_db_connection() {
    try {
        // Connect to MySQL server first without selecting database to ensure it exists
        $dsn = "mysql:host=" . DB_HOST . ";charset=utf8mb4";
        $pdo = new PDO($dsn, DB_USER, DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        $pdo->exec("CREATE DATABASE IF NOT EXISTS " . DB_NAME . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
        $pdo->exec("USE " . DB_NAME);
        
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        
        // Auto-migration check: If applications table lacks signature_path, drop it to recreate with new columns
        $recreate = false;
        $tableExists = $pdo->query("SHOW TABLES LIKE 'applications'")->fetch();
        if ($tableExists) {
            try {
                $pdo->query("SELECT signature_path FROM applications LIMIT 1");
            } catch (PDOException $e) {
                $recreate = true;
            }
        }
        
        if ($recreate) {
            $pdo->exec("DROP TABLE IF EXISTS applications");
        }

        // Initialize tables if they don't exist
        $pdo->exec("CREATE TABLE IF NOT EXISTS applications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            app_id VARCHAR(50) UNIQUE NOT NULL,
            account_type VARCHAR(20) NOT NULL,
            full_name VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL,
            phone VARCHAR(20) NOT NULL,
            dob VARCHAR(20),
            gender VARCHAR(20),
            address TEXT NOT NULL,
            national_id VARCHAR(50) NOT NULL,
            initial_deposit DECIMAL(15,2),
            balance DECIMAL(15,2) DEFAULT 0.00,
            business_name VARCHAR(100),
            business_reg_no VARCHAR(100),
            expected_turnover DECIMAL(15,2),
            signature_path VARCHAR(255),
            photo_path VARCHAR(255),
            doc_pan_path VARCHAR(255),
            doc_aadhaar_path VARCHAR(255),
            status VARCHAR(20) DEFAULT 'PENDING',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS rate_limits (
            ip VARCHAR(50) NOT NULL,
            timestamp INT NOT NULL,
            INDEX idx_rate_limits_ip_time (ip, timestamp)
        ) ENGINE=InnoDB;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS admins (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS ip_whitelist (
            id INT AUTO_INCREMENT PRIMARY KEY,
            ip VARCHAR(50) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50),
            ip_address VARCHAR(50) NOT NULL,
            action VARCHAR(100) NOT NULL,
            details TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        // Seed initial whitelisted IPs if empty
        $count = $pdo->query("SELECT COUNT(*) FROM ip_whitelist")->fetchColumn();
        if ($count == 0) {
            $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('103.165.115.64')");
            $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('127.0.0.1')");
            $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('::1')");
        }

        return $pdo;
    } catch (PDOException $e) {
        die(json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]));
    }
}

/**
 * Checks if an IP is rate limited (max X requests in Y seconds)
 */
function is_rate_limited($ip, $maxRequests = 3, $seconds = 10) {
    $pdo = get_db_connection();
    $now = time();
    $cutoff = $now - $seconds;

    // Delete old logs
    $stmt = $pdo->prepare("DELETE FROM rate_limits WHERE timestamp < :cutoff");
    $stmt->execute([':cutoff' => $cutoff]);

    // Count recent requests from this IP
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM rate_limits WHERE ip = :ip AND timestamp >= :cutoff");
    $stmt->execute([':ip' => $ip, ':cutoff' => $cutoff]);
    $row = $stmt->fetch();
    $requestCount = $row ? $row['count'] : 0;

    // Insert current request log
    $stmt = $pdo->prepare("INSERT INTO rate_limits (ip, timestamp) VALUES (:ip, :timestamp)");
    $stmt->execute([':ip' => $ip, ':timestamp' => $now]);

    return $requestCount >= $maxRequests;
}

/**
 * Saves a new bank account application
 */
function save_application($data) {
    $pdo = get_db_connection();

    // Generate unique Application ID (FR-XXXXXX) if not provided
    if (!empty($data['app_id'])) {
        $appId = $data['app_id'];
    } else {
        $attempts = 0;
        do {
            $appId = 'FR-' . str_pad(mt_rand(100000, 999999), 6, '0', STR_PAD_LEFT);
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM applications WHERE app_id = :app_id");
            $stmt->execute([':app_id' => $appId]);
            $exists = $stmt->fetch()['count'] > 0;
            $attempts++;
        } while ($exists && $attempts < 10);
    }

    $sql = "INSERT INTO applications (
        app_id, account_type, full_name, email, phone, dob, gender, address, 
        national_id, initial_deposit, balance, business_name, business_reg_no, expected_turnover,
        signature_path, photo_path, doc_pan_path, doc_aadhaar_path
    ) VALUES (
        :app_id, :account_type, :full_name, :email, :phone, :dob, :gender, :address, 
        :national_id, :initial_deposit, :balance, :business_name, :business_reg_no, :expected_turnover,
        :signature_path, :photo_path, :doc_pan_path, :doc_aadhaar_path
    )";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':app_id' => $appId,
        ':account_type' => $data['account_type'],
        ':full_name' => $data['full_name'],
        ':email' => $data['email'],
        ':phone' => $data['phone'],
        ':dob' => isset($data['dob']) ? $data['dob'] : null,
        ':gender' => isset($data['gender']) ? $data['gender'] : null,
        ':address' => $data['address'],
        ':national_id' => $data['national_id'],
        ':initial_deposit' => isset($data['initial_deposit']) ? (float)$data['initial_deposit'] : 0.00,
        ':balance' => 0.00,
        ':business_name' => isset($data['business_name']) ? $data['business_name'] : null,
        ':business_reg_no' => isset($data['business_reg_no']) ? $data['business_reg_no'] : null,
        ':expected_turnover' => isset($data['expected_turnover']) ? (float)$data['expected_turnover'] : null,
        ':signature_path' => isset($data['signature_path']) ? $data['signature_path'] : null,
        ':photo_path' => isset($data['photo_path']) ? $data['photo_path'] : null,
        ':doc_pan_path' => isset($data['doc_pan_path']) ? $data['doc_pan_path'] : null,
        ':doc_aadhaar_path' => isset($data['doc_aadhaar_path']) ? $data['doc_aadhaar_path'] : null,
    ]);

    return $appId;
}

/**
 * Returns applications, optionally filtered by status
 */
function get_applications($status = null) {
    $pdo = get_db_connection();
    if ($status) {
        $stmt = $pdo->prepare("SELECT * FROM applications WHERE status = :status ORDER BY created_at DESC");
        $stmt->execute([':status' => $status]);
        return $stmt->fetchAll();
    } else {
        $stmt = $pdo->query("SELECT * FROM applications ORDER BY created_at DESC");
        return $stmt->fetchAll();
    }
}

/**
 * Updates application status (PENDING, APPROVED, REJECTED)
 */
function update_application_status($appId, $status) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE applications SET status = :status WHERE app_id = :app_id");
    return $stmt->execute([
        ':status' => $status,
        ':app_id' => $appId
    ]);
}

/**
 * Registers a new admin with hashed password
 */
function register_admin($username, $password) {
    $pdo = get_db_connection();
    
    // Check if username already exists
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admins WHERE username = :username");
    $stmt->execute([':username' => $username]);
    if ($stmt->fetch()['count'] > 0) {
        return ['success' => false, 'message' => 'Username already exists.'];
    }
    
    $hash = password_hash($password, PASSWORD_DEFAULT);
    
    $stmt = $pdo->prepare("INSERT INTO admins (username, password_hash) VALUES (:username, :password_hash)");
    try {
        $stmt->execute([
            ':username' => $username,
            ':password_hash' => $hash
        ]);
        return ['success' => true];
    } catch (PDOException $e) {
        return ['success' => false, 'message' => 'Database error: ' . $e->getMessage()];
    }
}

/**
 * Authenticates an admin and returns user info if successful
 */
function authenticate_admin($username, $password) {
    $pdo = get_db_connection();
    
    $stmt = $pdo->prepare("SELECT * FROM admins WHERE username = :username");
    $stmt->execute([':username' => $username]);
    $user = $stmt->fetch();
    
    if ($user && password_verify($password, $user['password_hash'])) {
        return ['success' => true, 'user' => $user];
    }
    return ['success' => false, 'message' => 'Invalid username or password.'];
}

/**
 * Updates application balance
 */
function update_application_balance($appId, $newBalance) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE applications SET balance = :balance WHERE app_id = :app_id");
    return $stmt->execute([
        ':balance' => $newBalance,
        ':app_id' => $appId
    ]);
}

/**
 * Updates application profile details
 */
function update_application_profile($appId, $data) {
    $pdo = get_db_connection();
    
    $sql = "UPDATE applications SET 
        full_name = :full_name,
        email = :email,
        phone = :phone,
        address = :address,
        national_id = :national_id";
        
    $params = [
        ':full_name' => $data['full_name'],
        ':email' => $data['email'],
        ':phone' => $data['phone'],
        ':address' => $data['address'],
        ':national_id' => $data['national_id'],
        ':app_id' => $appId
    ];
    
    if (isset($data['dob'])) {
        $sql .= ", dob = :dob";
        $params[':dob'] = $data['dob'];
    }
    if (isset($data['gender'])) {
        $sql .= ", gender = :gender";
        $params[':gender'] = $data['gender'];
    }
    if (isset($data['business_name'])) {
        $sql .= ", business_name = :business_name";
        $params[':business_name'] = $data['business_name'];
    }
    if (isset($data['business_reg_no'])) {
        $sql .= ", business_reg_no = :business_reg_no";
        $params[':business_reg_no'] = $data['business_reg_no'];
    }
    if (isset($data['expected_turnover'])) {
        $sql .= ", expected_turnover = :expected_turnover";
        $params[':expected_turnover'] = (float)$data['expected_turnover'];
    }
    
    $sql .= " WHERE app_id = :app_id";
    
    $stmt = $pdo->prepare($sql);
    return $stmt->execute($params);
}

/**
 * Resolves the client's actual network IP address
 */
function get_client_ip() {
    // For local testing: allow passing ?mock_ip=X.X.X.X in URL (restricted to localhost)
    if (isset($_SERVER['REMOTE_ADDR']) && ($_SERVER['REMOTE_ADDR'] === '127.0.0.1' || $_SERVER['REMOTE_ADDR'] === '::1')) {
        if (isset($_GET['mock_ip'])) {
            if (session_status() === PHP_SESSION_NONE) {
                session_start();
            }
            if ($_GET['mock_ip'] === 'clear') {
                unset($_SESSION['mock_ip']);
            } else {
                $_SESSION['mock_ip'] = trim($_GET['mock_ip']);
                return $_SESSION['mock_ip'];
            }
        }
        if (session_status() === PHP_SESSION_ACTIVE && isset($_SESSION['mock_ip'])) {
            return $_SESSION['mock_ip'];
        }
    }

    $headers = [
        'HTTP_CLIENT_IP',
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_FORWARDED',
        'HTTP_X_CLUSTER_CLIENT_IP',
        'HTTP_FORWARDED_FOR',
        'HTTP_FORWARDED',
        'HTTP_X_REAL_IP',
        'HTTP_CF_CONNECTING_IP'
    ];
    
    foreach ($headers as $header) {
        if (!empty($_SERVER[$header])) {
            $ips = explode(',', $_SERVER[$header]);
            foreach ($ips as $ip) {
                $ip = trim($ip);
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }
    }
    
    return $_SERVER['REMOTE_ADDR'];
}

/**
 * Returns list of whitelisted IPs
 */
function get_whitelisted_ips() {
    $pdo = get_db_connection();
    $stmt = $pdo->query("SELECT ip FROM ip_whitelist ORDER BY created_at DESC");
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

/**
 * Adds an IP to the whitelist
 */
function add_whitelisted_ip($ip) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("INSERT IGNORE INTO ip_whitelist (ip) VALUES (:ip)");
    return $stmt->execute([':ip' => trim($ip)]);
}

/**
 * Deletes an IP from the whitelist
 */
function delete_whitelisted_ip($ip) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("DELETE FROM ip_whitelist WHERE ip = :ip");
    return $stmt->execute([':ip' => trim($ip)]);
}

/**
 * Records an administrator activity log
 */
function log_admin_activity($username, $action, $details) {
    $pdo = get_db_connection();
    $ip = get_client_ip();
    $stmt = $pdo->prepare("INSERT INTO admin_logs (username, ip_address, action, details) VALUES (:username, :ip_address, :action, :details)");
    return $stmt->execute([
        ':username' => $username,
        ':ip_address' => $ip,
        ':action' => $action,
        ':details' => $details
    ]);
}

/**
 * Returns recorded administrator logs
 */
function get_admin_logs() {
    $pdo = get_db_connection();
    $stmt = $pdo->query("SELECT * FROM admin_logs ORDER BY created_at DESC");
    return $stmt->fetchAll();
}

/**
 * Verifies that the client IP is whitelisted
 */
function verify_ip_access() {
    $ip = get_client_ip();
    $whitelisted = get_whitelisted_ips();
    
    if (!in_array($ip, $whitelisted)) {
        http_response_code(403);
        ?>
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>403 Forbidden - Access Denied</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@3.2/dist/css/adminlte.min.css">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
            <link rel="icon" type="image/png" href="favicon.png">
            <style>
                body {
                    background-color: #02144a !important; /* Brand Navy */
                    color: white;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                }
                .forbidden-box {
                    background: white;
                    color: #333;
                    padding: 40px;
                    border-radius: 8px;
                    box-shadow: 0 4px 20px rgba(0,0,0,0.3);
                    max-width: 500px;
                    text-align: center;
                    border-top: 5px solid #fecb00; /* Brand Gold */
                }
                .lock-icon {
                    font-size: 4rem;
                    color: #dc3545;
                    margin-bottom: 20px;
                }
                .brand-title {
                    color: #031f73;
                    font-weight: 700;
                    margin-bottom: 10px;
                }
            </style>
        </head>
        <body>
            <div class="forbidden-box">
                <div class="lock-icon">
                    <i class="fas fa-user-shield"></i>
                </div>
                <h3 class="brand-title">Deccan Finance Admin Console</h3>
                <h5 class="text-danger font-weight-bold">403 Access Forbidden</h5>
                <p class="mt-3">Your IP address (<strong><?= htmlspecialchars($ip) ?></strong>) is not authorized to access this administration panel.</p>
                <p class="text-muted small">Please request authorization from the system administrator if you believe this is an error.</p>
            </div>
        </body>
        </html>
        <?php
        exit;
    }
}

