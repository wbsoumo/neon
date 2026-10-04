<?php
date_default_timezone_set('Asia/Kolkata');
ini_set('display_errors', 0);
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);

// Configure custom private session storage directory to prevent automatic 24-minute system session deletion
session_save_path(__DIR__ . '/sessions');

if (strpos(__FILE__, '/var/www/html/') !== false) {
    // cPanel / Production Credentials
    define('DB_HOST', 'localhost');
    define('DB_NAME', 'helnovexaa_neon');
    define('DB_USER', 'helnovexaa_neon');
    define('DB_PASS', 'Soumojit1234@');
} else {
    // Local / Testing Credentials
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
        $pdo->exec("SET time_zone = '+05:30'");
        
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        
        $init_file = __DIR__ . '/sessions/.db_initialized';
        if (!file_exists($init_file)) {
            // Auto-migration check: If applications table lacks signature_path, drop it to recreate with new columns
            $recreate = false;
            $tableExists = $pdo->query("SHOW TABLES LIKE 'applications'")->fetch();
            if ($tableExists) {
                try {
                    $pdo->query("SELECT signature_path FROM applications LIMIT 1");
                } catch (PDOException $e) {
                    $recreate = true;
                }
                
                // Also check for password_hash column and add it if missing
                if (!$recreate) {
                    try {
                        $pdo->query("SELECT password_hash FROM applications LIMIT 1");
                    } catch (PDOException $e) {
                        $pdo->exec("ALTER TABLE applications ADD COLUMN password_hash VARCHAR(255) NULL AFTER expected_turnover");
                    }
                }
                
                // Also check for aadhaar_number column and add it if missing
                if (!$recreate) {
                    try {
                        $pdo->query("SELECT aadhaar_number FROM applications LIMIT 1");
                    } catch (PDOException $e) {
                        $pdo->exec("ALTER TABLE applications ADD COLUMN aadhaar_number VARCHAR(20) NULL AFTER national_id");
                    }
                }
                
                // Also check for tx_enabled column and add it if missing
                if (!$recreate) {
                    try {
                        $pdo->query("SELECT tx_enabled FROM applications LIMIT 1");
                    } catch (PDOException $e) {
                        $pdo->exec("ALTER TABLE applications ADD COLUMN tx_enabled TINYINT DEFAULT 1");
                    }
                }

                // Also check for tx_disabled_message column and add it if missing
                if (!$recreate) {
                    try {
                        $pdo->query("SELECT tx_disabled_message FROM applications LIMIT 1");
                    } catch (PDOException $e) {
                        $pdo->exec("ALTER TABLE applications ADD COLUMN tx_disabled_message VARCHAR(255) NULL");
                    }
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
                aadhaar_number VARCHAR(20) NULL,
                initial_deposit DECIMAL(15,2),
                balance DECIMAL(15,2) DEFAULT 0.00,
                business_name VARCHAR(100),
                business_reg_no VARCHAR(100),
                expected_turnover DECIMAL(15,2),
                password_hash VARCHAR(255),
                signature_path VARCHAR(255),
                photo_path VARCHAR(255),
                doc_pan_path VARCHAR(255),
                doc_aadhaar_path VARCHAR(255),
                status VARCHAR(20) DEFAULT 'PENDING',
                tx_enabled TINYINT DEFAULT 1,
                tx_disabled_message VARCHAR(255) NULL,
                tx_failed_email_template TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            $pdo->exec("CREATE TABLE IF NOT EXISTS contacts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                app_id VARCHAR(50) NOT NULL,
                name VARCHAR(100) NULL,
                phone VARCHAR(50) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_contacts_app_id (app_id),
                UNIQUE KEY uq_app_contact (app_id, phone)
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

            $pdo->exec("CREATE TABLE IF NOT EXISTS user_login_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                phone VARCHAR(20) NOT NULL,
                app_id VARCHAR(50) NULL,
                ip_address VARCHAR(50) NOT NULL,
                status VARCHAR(20) NOT NULL,
                details TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            $pdo->exec("CREATE TABLE IF NOT EXISTS accounts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                app_id VARCHAR(50) NOT NULL UNIQUE,
                account_number VARCHAR(11) NOT NULL UNIQUE,
                mpin_hash VARCHAR(255) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            $pdo->exec("CREATE TABLE IF NOT EXISTS transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                transaction_id VARCHAR(50) UNIQUE NOT NULL,
                sender_app_id VARCHAR(50) NOT NULL,
                recipient_account VARCHAR(50) NOT NULL,
                amount DECIMAL(15,2) NOT NULL,
                type VARCHAR(20) NOT NULL,
                utr_id VARCHAR(50) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_txn_sender (sender_app_id),
                INDEX idx_txn_utr (utr_id)
            ) ENGINE=InnoDB;");

            $pdo->exec("CREATE TABLE IF NOT EXISTS beneficiaries (
                id INT AUTO_INCREMENT PRIMARY KEY,
                sender_app_id VARCHAR(50) NOT NULL,
                type VARCHAR(20) NOT NULL,
                beneficiary_name VARCHAR(100) NOT NULL,
                beneficiary_account_number VARCHAR(50) NOT NULL,
                ifsc_code VARCHAR(20) NULL,
                daily_limit DECIMAL(15,2) DEFAULT 0.00,
                nickname VARCHAR(50) NULL,
                status VARCHAR(20) DEFAULT 'PENDING',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_beneficiaries_sender (sender_app_id),
                UNIQUE KEY uq_sender_beneficiary_acc (sender_app_id, beneficiary_account_number, type)
            ) ENGINE=InnoDB;");

            // Auto-migration check: add login_pin_hash to accounts table if missing
            try {
                $pdo->query("SELECT login_pin_hash FROM accounts LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE accounts ADD COLUMN login_pin_hash VARCHAR(255) NULL AFTER mpin_hash");
            }

            try {
                $pdo->query("SELECT pin_login_enabled FROM accounts LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE accounts ADD COLUMN pin_login_enabled TINYINT DEFAULT 0 AFTER login_pin_hash");
            }

            try {
                $pdo->query("SELECT biometric_login_enabled FROM accounts LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE accounts ADD COLUMN biometric_login_enabled TINYINT DEFAULT 0 AFTER pin_login_enabled");
            }

            try {
                $pdo->query("SELECT fcm_token FROM accounts LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE accounts ADD COLUMN fcm_token TEXT NULL AFTER biometric_login_enabled");
            }
            try {
                $pdo->query("SELECT fmc_token FROM accounts LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE accounts ADD COLUMN fmc_token TEXT NULL AFTER fcm_token");
            }

            try {
                $pdo->query("SELECT fcm_token FROM applications LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE applications ADD COLUMN fcm_token TEXT NULL");
            }
            try {
                $pdo->query("SELECT fmc_token FROM applications LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE applications ADD COLUMN fmc_token TEXT NULL");
            }

            // Ensure any existing tables are altered to TEXT to prevent long token errors
            try {
                $pdo->exec("ALTER TABLE accounts MODIFY COLUMN fcm_token TEXT NULL");
                $pdo->exec("ALTER TABLE accounts MODIFY COLUMN fmc_token TEXT NULL");
                $pdo->exec("ALTER TABLE applications MODIFY COLUMN fcm_token TEXT NULL");
                $pdo->exec("ALTER TABLE applications MODIFY COLUMN fmc_token TEXT NULL");
            } catch (PDOException $e) {
                // Ignore if fails
            }

            // Create user_biometrics table
            $pdo->exec("CREATE TABLE IF NOT EXISTS user_biometrics (
                id INT AUTO_INCREMENT PRIMARY KEY,
                app_id VARCHAR(50) NOT NULL,
                biometric_token VARCHAR(255) NOT NULL UNIQUE,
                device_name VARCHAR(100) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_biometric_app (app_id)
            ) ENGINE=InnoDB;");

            // Create user_compliance table for SOF, FDI, FEMA, AML documents
            $pdo->exec("CREATE TABLE IF NOT EXISTS user_compliance (
                id INT AUTO_INCREMENT PRIMARY KEY,
                app_id VARCHAR(50) NOT NULL,
                type VARCHAR(20) NOT NULL,
                text_content TEXT NULL,
                image_path VARCHAR(255) NULL,
                pdf_path VARCHAR(255) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY uq_app_type (app_id, type),
                INDEX idx_user_compliance_app (app_id)
            ) ENGINE=InnoDB;");

            // Alter transactions table to support P2B/Payout fields
            try {
                $pdo->exec("ALTER TABLE transactions MODIFY COLUMN utr_id VARCHAR(50) NULL");
            } catch (PDOException $e) {
                // Ignore if fails
            }
            try {
                $pdo->query("SELECT status FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN status VARCHAR(50) DEFAULT 'SUCCESS'");
            }
            try {
                $pdo->query("SELECT recipient_name FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN recipient_name VARCHAR(100) NULL");
            }
            try {
                $pdo->query("SELECT ifsc_code FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN ifsc_code VARCHAR(20) NULL");
            }
            try {
                $pdo->query("SELECT provider FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN provider VARCHAR(50) NULL");
            }
            try {
                $pdo->query("SELECT status_details FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN status_details TEXT NULL");
            }
            try {
                $pdo->query("SELECT remarks FROM transactions LIMIT 1");
            } catch (PDOException $e) {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN remarks TEXT NULL");
            }

            // Seed initial whitelisted IPs if empty
            $count = $pdo->query("SELECT COUNT(*) FROM ip_whitelist")->fetchColumn();
            if ($count == 0) {
                $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('103.165.115.64')");
                $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('127.0.0.1')");
                $pdo->exec("INSERT INTO ip_whitelist (ip) VALUES ('::1')");
            }

            // Create smtp_settings table
            $pdo->exec("CREATE TABLE IF NOT EXISTS smtp_settings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                smtp_host VARCHAR(255) NOT NULL,
                smtp_port INT NOT NULL,
                smtp_encryption VARCHAR(10) NOT NULL,
                smtp_user VARCHAR(255) NOT NULL,
                smtp_pass_encrypted VARCHAR(255) NOT NULL,
                from_email VARCHAR(255) NOT NULL,
                from_name VARCHAR(255) NOT NULL,
                reply_to VARCHAR(255) NOT NULL,
                smtp_auth TINYINT(1) DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            // Seed default SMTP Settings if empty or outdated
            try {
                $method = 'AES-256-CBC';
                $key = 'DeccanSecureKey2026!';
                $iv = substr(hash('sha256', $key), 0, 16);
                $pass = 'Soumojit1234@';
                $encryptedPass = base64_encode(openssl_encrypt($pass, $method, $key, 0, $iv));

                $existingSmtp = $pdo->query("SELECT * FROM smtp_settings ORDER BY id DESC LIMIT 1")->fetch();
                if (!$existingSmtp || ($existingSmtp['from_email'] ?? '') !== 'no-reply@neonfinswiss.world') {
                    $pdo->exec("DELETE FROM smtp_settings");
                    $stmt = $pdo->prepare("INSERT INTO smtp_settings 
                        (smtp_host, smtp_port, smtp_encryption, smtp_user, smtp_pass_encrypted, from_email, from_name, reply_to, smtp_auth) 
                        VALUES 
                        ('neonfinswiss.world', 465, 'SSL', 'no-reply@neonfinswiss.world', :pass, 'no-reply@neonfinswiss.world', 'Neon Bank', 'no-reply@neonfinswiss.world', 1)");
                    $stmt->execute([':pass' => $encryptedPass]);
                }
            } catch (\Throwable $smtpErr) {
                error_log("SMTP seed warning: " . $smtpErr->getMessage());
            }

            // Create email_logs table
            $pdo->exec("CREATE TABLE IF NOT EXISTS email_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                recipient VARCHAR(255) NOT NULL,
                cc VARCHAR(255) NULL,
                bcc VARCHAR(255) NULL,
                subject VARCHAR(255) NOT NULL,
                body TEXT NOT NULL,
                sender VARCHAR(255) NOT NULL,
                status VARCHAR(20) NOT NULL,
                error_message TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            // Create password_resets table
            $pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
                id INT AUTO_INCREMENT PRIMARY KEY,
                app_id VARCHAR(50) NOT NULL,
                email VARCHAR(255) NOT NULL,
                otp VARCHAR(10) NOT NULL,
                session_id VARCHAR(255) NOT NULL,
                is_verified TINYINT DEFAULT 0,
                expires_at DATETIME NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            // Create system_settings table
            $pdo->exec("CREATE TABLE IF NOT EXISTS system_settings (
                setting_key VARCHAR(50) PRIMARY KEY,
                setting_value TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;");

            // Seed default settings if empty
            $count = $pdo->query("SELECT COUNT(*) FROM system_settings WHERE setting_key = 'maintenance_mode'")->fetchColumn();
            if ($count == 0) {
                $pdo->exec("INSERT INTO system_settings (setting_key, setting_value) VALUES ('maintenance_mode', '0')");
            }

            if (is_dir(__DIR__ . '/sessions') && is_writable(__DIR__ . '/sessions')) {
                @file_put_contents($init_file, date('Y-m-d H:i:s'));
            }
        }

        // Run migration checks outside the initialization file check to guarantee execution on update
        try {
            $pdo->query("SELECT tx_enabled FROM applications LIMIT 1");
        } catch (PDOException $e) {
            $pdo->exec("ALTER TABLE applications ADD COLUMN tx_enabled TINYINT DEFAULT 1");
        }

        try {
            $pdo->query("SELECT tx_disabled_message FROM applications LIMIT 1");
        } catch (PDOException $e) {
            $pdo->exec("ALTER TABLE applications ADD COLUMN tx_disabled_message VARCHAR(255) NULL");
        }

        try {
            $pdo->query("SELECT tx_failed_email_template FROM applications LIMIT 1");
        } catch (PDOException $e) {
            $pdo->exec("ALTER TABLE applications ADD COLUMN tx_failed_email_template TEXT NULL");
        }

        // Onboarding On Demand Auto-Migrations
        $newColumns = [
            'nationality' => 'VARCHAR(100) NULL',
            'residency_country' => 'VARCHAR(100) NULL',
            'employment_status' => 'VARCHAR(100) NULL',
            'employer_name' => 'VARCHAR(150) NULL',
            'income_range' => 'VARCHAR(100) NULL',
            'source_of_funds' => 'VARCHAR(100) NULL',
            'account_purpose' => 'VARCHAR(100) NULL',
            'tax_residency' => 'VARCHAR(100) NULL',
            'tax_id_no' => 'VARCHAR(100) NULL',
            'passport_no' => 'VARCHAR(100) NULL',
            'doc_proof_address_path' => 'VARCHAR(255) NULL',
            'nominee_name' => 'VARCHAR(150) NULL',
            'nominee_relation' => 'VARCHAR(100) NULL',
            'nominee_phone' => 'VARCHAR(50) NULL',
            'pep_declaration' => 'VARCHAR(10) NULL',
            'consent_agreed_at' => 'DATETIME NULL',
            'consent_ip' => 'VARCHAR(50) NULL'
        ];
        foreach ($newColumns as $col => $typeDef) {
            try {
                $pdo->query("SELECT $col FROM applications LIMIT 1");
            } catch (PDOException $e) {
                try {
                    $pdo->exec("ALTER TABLE applications ADD COLUMN $col $typeDef");
                } catch (PDOException $ex) {}
            }
        }

        // Ensure transactions table exists before running column check
        $pdo->exec("CREATE TABLE IF NOT EXISTS transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            transaction_id VARCHAR(50) UNIQUE NOT NULL,
            sender_app_id VARCHAR(50) NOT NULL,
            recipient_account VARCHAR(50) NOT NULL,
            amount DECIMAL(15,2) NOT NULL,
            type VARCHAR(20) NOT NULL,
            utr_id VARCHAR(50) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'SUCCESS',
            recipient_name VARCHAR(100) NULL,
            ifsc_code VARCHAR(20) NULL,
            provider VARCHAR(50) NULL,
            status_details TEXT NULL,
            remarks TEXT NULL,
            INDEX idx_txn_sender (sender_app_id),
            INDEX idx_txn_utr (utr_id)
        ) ENGINE=InnoDB;");

        try {
            $pdo->query("SELECT remarks FROM transactions LIMIT 1");
        } catch (PDOException $e) {
            try {
                $pdo->exec("ALTER TABLE transactions ADD COLUMN remarks TEXT NULL");
            } catch (PDOException $ex) {}
        }

        // Create user_spaces table
        $pdo->exec("CREATE TABLE IF NOT EXISTS user_spaces (
            id INT AUTO_INCREMENT PRIMARY KEY,
            space_id VARCHAR(50) UNIQUE NOT NULL,
            app_id VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            category VARCHAR(50) NOT NULL,
            icon_key VARCHAR(50) NOT NULL,
            currency VARCHAR(10) DEFAULT 'CHF',
            balance DECIMAL(15,2) DEFAULT 0.00,
            target_amount DECIMAL(15,2) NULL,
            target_date VARCHAR(20) NULL,
            color_hex VARCHAR(20) NULL,
            allocation_type VARCHAR(20) DEFAULT 'NONE',
            allocation_value DECIMAL(15,2) DEFAULT 0.00,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_spaces_app (app_id)
        ) ENGINE=InnoDB;");

        // Create space_transactions table
        $pdo->exec("CREATE TABLE IF NOT EXISTS space_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            transaction_id VARCHAR(50) UNIQUE NOT NULL,
            space_id VARCHAR(50) NOT NULL,
            app_id VARCHAR(50) NOT NULL,
            type VARCHAR(20) NOT NULL, -- ADD, WITHDRAW, AUTOMATIC, REVERSAL
            amount DECIMAL(15,2) NOT NULL,
            currency VARCHAR(10) DEFAULT 'CHF',
            source_dest VARCHAR(100) NOT NULL,
            status VARCHAR(20) DEFAULT 'SUCCESS',
            reference_id VARCHAR(100) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_space_tx_space (space_id),
            INDEX idx_space_tx_app (app_id)
        ) ENGINE=InnoDB;");

        // Create space_allocation_rules table
        $pdo->exec("CREATE TABLE IF NOT EXISTS space_allocation_rules (
            id INT AUTO_INCREMENT PRIMARY KEY,
            space_id VARCHAR(50) UNIQUE NOT NULL,
            app_id VARCHAR(50) NOT NULL,
            rule_type VARCHAR(20) NOT NULL, -- FIXED_MONTHLY, PERCENTAGE_INCOMING
            rule_value DECIMAL(15,2) NOT NULL,
            is_active TINYINT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_alloc_app (app_id)
        ) ENGINE=InnoDB;");

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
        national_id, aadhaar_number, initial_deposit, balance, business_name, business_reg_no, expected_turnover,
        password_hash, signature_path, photo_path, doc_pan_path, doc_aadhaar_path,
        nationality, residency_country, employment_status, employer_name, income_range, source_of_funds,
        account_purpose, tax_residency, tax_id_no, passport_no, doc_proof_address_path, nominee_name,
        nominee_relation, nominee_phone, pep_declaration, consent_agreed_at, consent_ip
    ) VALUES (
        :app_id, :account_type, :full_name, :email, :phone, :dob, :gender, :address, 
        :national_id, :aadhaar_number, :initial_deposit, :balance, :business_name, :business_reg_no, :expected_turnover,
        :password_hash, :signature_path, :photo_path, :doc_pan_path, :doc_aadhaar_path,
        :nationality, :residency_country, :employment_status, :employer_name, :income_range, :source_of_funds,
        :account_purpose, :tax_residency, :tax_id_no, :passport_no, :doc_proof_address_path, :nominee_name,
        :nominee_relation, :nominee_phone, :pep_declaration, :consent_agreed_at, :consent_ip
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
        ':national_id' => isset($data['national_id']) ? $data['national_id'] : 'NOT_REQUIRED',
        ':aadhaar_number' => isset($data['aadhaar_number']) ? $data['aadhaar_number'] : null,
        ':initial_deposit' => isset($data['initial_deposit']) ? (float)$data['initial_deposit'] : 0.00,
        ':balance' => 0.00,
        ':business_name' => isset($data['business_name']) ? $data['business_name'] : null,
        ':business_reg_no' => isset($data['business_reg_no']) ? $data['business_reg_no'] : null,
        ':expected_turnover' => isset($data['expected_turnover']) ? (float)$data['expected_turnover'] : null,
        ':password_hash' => isset($data['password_hash']) ? $data['password_hash'] : null,
        ':signature_path' => isset($data['signature_path']) ? $data['signature_path'] : null,
        ':photo_path' => isset($data['photo_path']) ? $data['photo_path'] : null,
        ':doc_pan_path' => isset($data['doc_pan_path']) ? $data['doc_pan_path'] : null,
        ':doc_aadhaar_path' => isset($data['doc_aadhaar_path']) ? $data['doc_aadhaar_path'] : null,
        ':nationality' => isset($data['nationality']) ? $data['nationality'] : null,
        ':residency_country' => isset($data['residency_country']) ? $data['residency_country'] : null,
        ':employment_status' => isset($data['employment_status']) ? $data['employment_status'] : null,
        ':employer_name' => isset($data['employer_name']) ? $data['employer_name'] : null,
        ':income_range' => isset($data['income_range']) ? $data['income_range'] : null,
        ':source_of_funds' => isset($data['source_of_funds']) ? $data['source_of_funds'] : null,
        ':account_purpose' => isset($data['account_purpose']) ? $data['account_purpose'] : null,
        ':tax_residency' => isset($data['tax_residency']) ? $data['tax_residency'] : null,
        ':tax_id_no' => isset($data['tax_id_no']) ? $data['tax_id_no'] : null,
        ':passport_no' => isset($data['passport_no']) ? $data['passport_no'] : null,
        ':doc_proof_address_path' => isset($data['doc_proof_address_path']) ? $data['doc_proof_address_path'] : null,
        ':nominee_name' => isset($data['nominee_name']) ? $data['nominee_name'] : null,
        ':nominee_relation' => isset($data['nominee_relation']) ? $data['nominee_relation'] : null,
        ':nominee_phone' => isset($data['nominee_phone']) ? $data['nominee_phone'] : null,
        ':pep_declaration' => isset($data['pep_declaration']) ? $data['pep_declaration'] : 'NO',
        ':consent_agreed_at' => isset($data['consent_agreed_at']) ? $data['consent_agreed_at'] : date('Y-m-d H:i:s'),
        ':consent_ip' => isset($data['consent_ip']) ? $data['consent_ip'] : get_client_ip()
    ]);

    return $appId;
}

/**
 * Returns applications, optionally filtered by status
 */
function get_applications($status = null) {
    $pdo = get_db_connection();
    if ($status) {
        $stmt = $pdo->prepare("SELECT a.*, acc.account_number, acc.fcm_token, acc.fmc_token FROM applications a LEFT JOIN accounts acc ON a.app_id = acc.app_id WHERE a.status = :status ORDER BY a.created_at DESC");
        $stmt->execute([':status' => $status]);
        return $stmt->fetchAll();
    } else {
        $stmt = $pdo->query("SELECT a.*, acc.account_number, acc.fcm_token, acc.fmc_token FROM applications a LEFT JOIN accounts acc ON a.app_id = acc.app_id ORDER BY a.created_at DESC");
        return $stmt->fetchAll();
    }
}

/**
 * Updates application status (PENDING, APPROVED, REJECTED)
 */
function update_application_status($appId, $status) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE applications SET status = :status WHERE app_id = :app_id");
    $success = $stmt->execute([
        ':status' => $status,
        ':app_id' => $appId
    ]);
    
    if ($success && $status === 'APPROVED') {
        // Generate and save 11-digit account number if it doesn't already exist
        $stmtCheck = $pdo->prepare("SELECT COUNT(*) FROM accounts WHERE app_id = :app_id");
        $stmtCheck->execute([':app_id' => $appId]);
        if ($stmtCheck->fetchColumn() == 0) {
            $accNum = null;
            do {
                $accNum = '501' . str_pad(mt_rand(10000000, 99999999), 8, '0', STR_PAD_LEFT);
                $stmtDup = $pdo->prepare("SELECT COUNT(*) FROM accounts WHERE account_number = :account_number");
                $stmtDup->execute([':account_number' => $accNum]);
                $dup = $stmtDup->fetchColumn() > 0;
            } while ($dup);
            
            $stmtInsert = $pdo->prepare("INSERT INTO accounts (app_id, account_number) VALUES (:app_id, :account_number)");
            $stmtInsert->execute([':app_id' => $appId, ':account_number' => $accNum]);
        }
        
        // Fetch generated account number to include in notification body
        $stmtAcc = $pdo->prepare("SELECT account_number FROM accounts WHERE app_id = :app_id LIMIT 1");
        $stmtAcc->execute([':app_id' => $appId]);
        $accNumVal = $stmtAcc->fetchColumn() ?: '';
        
        $notifyTitle = "Account Approved!";
        $notifyBody = "Congratulations! Your Deccan Finance account has been approved." . ($accNumVal ? " Your account number is: $accNumVal." : "");
        send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Security');

        // Trigger email notification
        try {
            require_once __DIR__ . '/email_service.php';
            if ($accNumVal) {
                EmailService::sendNotificationEmail($accNumVal, 'approved');
            }
        } catch (Exception $mailEx) {
            error_log("Failed to send account approval email: " . $mailEx->getMessage());
        }
    }
    
    return $success;
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
    if (isset($data['aadhaar_number'])) {
        $sql .= ", aadhaar_number = :aadhaar_number";
        $params[':aadhaar_number'] = $data['aadhaar_number'];
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
 * Records a customer login attempt (success or failure)
 */
function log_user_login($phone, $appId, $status, $details = null) {
    $pdo = get_db_connection();
    $ip = get_client_ip();
    $stmt = $pdo->prepare("INSERT INTO user_login_logs (phone, app_id, ip_address, status, details) VALUES (:phone, :app_id, :ip_address, :status, :details)");
    return $stmt->execute([
        ':phone' => $phone,
        ':app_id' => $appId,
        ':ip_address' => $ip,
        ':status' => $status,
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
            <link rel="icon" type="image/png" href="../assets/img/favicon.png">
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
                <h3 class="brand-title">Deccan Finance</h3>
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

/**
 * Batch saves or updates contacts for a customer application
 */
function save_contacts($appId, $contacts) {
    $pdo = get_db_connection();
    if (empty($contacts)) {
        return true;
    }
    
    // Prepare the SQL query using ON DUPLICATE KEY UPDATE
    // Since we have a UNIQUE KEY on (app_id, phone), if the pair exists, it will update the name.
    $sql = "INSERT INTO contacts (app_id, name, phone) VALUES (:app_id, :name, :phone) 
            ON DUPLICATE KEY UPDATE name = :update_name";
    
    $stmt = $pdo->prepare($sql);
    
    $pdo->beginTransaction();
    try {
        foreach ($contacts as $contact) {
            $name = isset($contact['name']) ? trim($contact['name']) : null;
            $phone = isset($contact['phone']) ? trim($contact['phone']) : '';
            
            // Skip if phone is empty
            if ($phone === '') {
                continue;
            }
            
            $stmt->execute([
                ':app_id' => $appId,
                ':name' => $name,
                ':phone' => $phone,
                ':update_name' => $name
            ]);
        }
        $pdo->commit();
        return true;
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/**
 * Fetches all synchronized contacts for an application ID
 */
function get_contacts_by_app_id($appId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT name, phone, created_at FROM contacts WHERE app_id = :app_id ORDER BY name ASC, phone ASC");
    $stmt->execute([':app_id' => $appId]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Fetches application details by application ID
 */
function get_application_by_id($appId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM applications WHERE app_id = :app_id LIMIT 1");
    $stmt->execute([':app_id' => $appId]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Checks the transaction enabled status of a customer account
 */
function check_user_tx_status($appId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT tx_enabled, tx_disabled_message FROM applications WHERE app_id = :app_id LIMIT 1");
    $stmt->execute([':app_id' => $appId]);
    $row = $stmt->fetch();
    if ($row) {
        return [
            'enabled' => (int)$row['tx_enabled'] !== 0,
            'message' => $row['tx_disabled_message'] ?: 'Transactions are disabled for your account.'
        ];
    }
    return ['enabled' => true, 'message' => ''];
}

/**
 * Fetches the account record by app_id
 */
function get_account_by_app_id($appId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM accounts WHERE app_id = :app_id LIMIT 1");
    $stmt->execute([':app_id' => $appId]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Fetches the account record by account_number
 */
function get_account_by_number($accountNumber) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM accounts WHERE account_number = :account_number LIMIT 1");
    $stmt->execute([':account_number' => $accountNumber]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Updates the MPIN hash in the accounts table
 */
function set_account_mpin($appId, $mpinHash) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE accounts SET mpin_hash = :mpin_hash WHERE app_id = :app_id");
    return $stmt->execute([
        ':mpin_hash' => $mpinHash,
        ':app_id' => $appId
    ]);
}

/**
 * Executes a P2P transfer (sender balance deduction and recipient balance addition) inside a transaction
 */
function execute_p2p_transfer($senderAppId, $recipientAppId, $amount) {
    $pdo = get_db_connection();
    $pdo->beginTransaction();
    try {
        // 1. Deduct from sender
        $stmtDeduct = $pdo->prepare("UPDATE applications SET balance = balance - :amount WHERE app_id = :sender_app_id");
        $stmtDeduct->execute([
            ':amount' => $amount,
            ':sender_app_id' => $senderAppId
        ]);
        
        // 2. Add to recipient
        $stmtAdd = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :recipient_app_id");
        $stmtAdd->execute([
            ':amount' => $amount,
            ':recipient_app_id' => $recipientAppId
        ]);
        
        $pdo->commit();
        return true;
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/**
 * Executes a payout transfer (sender balance deduction) inside a transaction
 */
function execute_payout_transfer($senderAppId, $amount) {
    $pdo = get_db_connection();
    $pdo->beginTransaction();
    try {
        // Deduct from sender
        $stmtDeduct = $pdo->prepare("UPDATE applications SET balance = balance - :amount WHERE app_id = :sender_app_id");
        $stmtDeduct->execute([
            ':amount' => $amount,
            ':sender_app_id' => $senderAppId
        ]);
        
        $pdo->commit();
        return true;
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/**
 * Records a transaction in the database
 */
function record_transaction($senderAppId, $recipientAccount, $amount, $type, $utrId = null, $status = 'SUCCESS', $recipientName = null, $ifscCode = null, $provider = null, $statusDetails = null, $remarks = null) {
    $pdo = get_db_connection();
    
    // Generate transaction ID
    $transactionId = 'TXN-' . strtoupper(substr(md5(uniqid(rand(), true)), 0, 10));
    
    if ($type === 'P2P' && empty($utrId)) {
        // Generate a unique 12-digit numeric UTR ID
        $attempts = 0;
        do {
            $utrId = '';
            for ($i = 0; $i < 12; $i++) {
                $utrId .= mt_rand(0, 9);
            }
            // Check if unique
            $stmt = $pdo->prepare("SELECT COUNT(*) FROM transactions WHERE utr_id = :utr_id");
            $stmt->execute([':utr_id' => $utrId]);
            $exists = $stmt->fetchColumn() > 0;
            $attempts++;
        } while ($exists && $attempts < 10);
    }
    
    $stmt = $pdo->prepare("INSERT INTO transactions (transaction_id, sender_app_id, recipient_account, amount, type, utr_id, status, recipient_name, ifsc_code, provider, status_details, remarks) 
                           VALUES (:transaction_id, :sender_app_id, :recipient_account, :amount, :type, :utr_id, :status, :recipient_name, :ifsc_code, :provider, :status_details, :remarks)");
    $stmt->execute([
        ':transaction_id' => $transactionId,
        ':sender_app_id' => $senderAppId,
        ':recipient_account' => $recipientAccount,
        ':amount' => $amount,
        ':type' => $type,
        ':utr_id' => $utrId,
        ':status' => $status,
        ':recipient_name' => $recipientName,
        ':ifsc_code' => $ifscCode,
        ':provider' => $provider,
        ':status_details' => $statusDetails,
        ':remarks' => $remarks
    ]);
    
    return [
        'transaction_id' => $transactionId,
        'utr_id' => $utrId
    ];
}

/**
 * Fetches all transactions for a given application ID (both sent and received)
 */
function get_transactions_by_app_id($appId) {
    $pdo = get_db_connection();
    
    // First, resolve the user's account number
    $account = get_account_by_app_id($appId);
    $accountNumber = $account ? $account['account_number'] : '';
    
    // Select all transactions where the user is sender or recipient
    $stmt = $pdo->prepare("
        SELECT t.*, 
               CASE WHEN t.sender_app_id = :app_id THEN 'DEBIT' ELSE 'CREDIT' END as flow_type,
               sa.full_name as sender_name,
               ra.full_name as recipient_name
        FROM transactions t
        LEFT JOIN applications sa ON t.sender_app_id = sa.app_id
        LEFT JOIN accounts acc ON t.recipient_account = acc.account_number
        LEFT JOIN applications ra ON acc.app_id = ra.app_id
        WHERE t.sender_app_id = :app_id OR (t.recipient_account = :account_number AND :account_number <> '')
        ORDER BY t.created_at DESC
    ");
    $stmt->execute([
        ':app_id' => $appId,
        ':account_number' => $accountNumber
    ]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Adds a beneficiary to the sender's account mapping
 */
function add_beneficiary($senderAppId, $type, $name, $accountNumber, $ifscCode = null, $dailyLimit = 0.00, $nickname = null, $status = 'PENDING') {
    $pdo = get_db_connection();
    
    // Check if beneficiary is already added for this type
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM beneficiaries WHERE sender_app_id = :sender AND beneficiary_account_number = :number AND type = :type");
    $stmt->execute([
        ':sender' => $senderAppId,
        ':number' => $accountNumber,
        ':type' => $type
    ]);
    if ($stmt->fetchColumn() > 0) {
        throw new Exception("Beneficiary with this account number and type is already added.");
    }
    
    $stmt = $pdo->prepare("INSERT INTO beneficiaries (sender_app_id, type, beneficiary_name, beneficiary_account_number, ifsc_code, daily_limit, nickname, status) 
                           VALUES (:sender, :type, :name, :number, :ifsc, :limit, :nickname, :status)");
    return $stmt->execute([
        ':sender' => $senderAppId,
        ':type' => $type,
        ':name' => $name,
        ':number' => $accountNumber,
        ':ifsc' => $ifscCode,
        ':limit' => $dailyLimit,
        ':nickname' => $nickname,
        ':status' => $status
    ]);
}

/**
 * Returns all beneficiaries added by a sender
 */
function get_beneficiaries($senderAppId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM beneficiaries WHERE sender_app_id = :sender ORDER BY beneficiary_name ASC");
    $stmt->execute([':sender' => $senderAppId]);
    return $stmt->fetchAll();
}

/**
 * Returns all pending beneficiaries for admin approval
 */
function get_pending_beneficiaries() {
    $pdo = get_db_connection();
    $stmt = $pdo->query("SELECT b.*, a.full_name as sender_name FROM beneficiaries b 
                         JOIN applications a ON b.sender_app_id = a.app_id 
                         WHERE b.status = 'PENDING' ORDER BY b.created_at DESC");
    return $stmt->fetchAll();
}

/**
 * Updates status of a beneficiary (APPROVED/REJECTED)
 */
function update_beneficiary_status($id, $status) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE beneficiaries SET status = :status WHERE id = :id");
    return $stmt->execute([
        ':status' => $status,
        ':id' => $id
    ]);
}

/**
 * Sets or updates the login PIN hash in the accounts table and enables PIN login
 */
function set_account_login_pin($appId, $pinHash) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE accounts SET login_pin_hash = :hash, pin_login_enabled = 1 WHERE app_id = :app_id");
    return $stmt->execute([
        ':hash' => $pinHash,
        ':app_id' => $appId
    ]);
}

/**
 * Registers a new biometric token linked to a customer and enables biometric login
 */
function register_biometric_token($appId, $token, $deviceName = null) {
    $pdo = get_db_connection();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("INSERT INTO user_biometrics (app_id, biometric_token, device_name) VALUES (:app_id, :token, :device_name)");
        $stmt->execute([
            ':app_id' => $appId,
            ':token' => $token,
            ':device_name' => $deviceName
        ]);
        
        $stmt2 = $pdo->prepare("UPDATE accounts SET biometric_login_enabled = 1 WHERE app_id = :app_id");
        $stmt2->execute([':app_id' => $appId]);
        
        $pdo->commit();
        return true;
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
}

/**
 * Retrieves biometric token record
 */
function get_biometric_record($token) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM user_biometrics WHERE biometric_token = :token LIMIT 1");
    $stmt->execute([':token' => $token]);
    return $stmt->fetch();
}

/**
 * Checks if user has any registered biometrics
 */
function has_user_biometric($appId) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM user_biometrics WHERE app_id = :app_id");
    $stmt->execute([':app_id' => $appId]);
    return $stmt->fetchColumn() > 0;
}

/**
 * Updates PIN and Biometric login settings toggles for an account
 */
function update_login_settings($appId, $pinEnabled, $biometricEnabled) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("UPDATE accounts SET pin_login_enabled = :pin_enabled, biometric_login_enabled = :bio_enabled WHERE app_id = :app_id");
    return $stmt->execute([
        ':pin_enabled' => (int)$pinEnabled,
        ':bio_enabled' => (int)$biometricEnabled,
        ':app_id' => $appId
    ]);
}

/**
 * Updates the Firebase Cloud Messaging registration token for an account
 */
function update_fcm_token($appId, $fcmToken) {
    $pdo = get_db_connection();
    
    // Update applications table
    $stmt1 = $pdo->prepare("UPDATE applications SET fcm_token = :fcm_token, fmc_token = :fmc_token WHERE app_id = :app_id");
    $stmt1->execute([
        ':fcm_token' => $fcmToken,
        ':fmc_token' => $fcmToken,
        ':app_id' => $appId
    ]);
    
    // Update accounts table (if exists)
    $stmt2 = $pdo->prepare("UPDATE accounts SET fcm_token = :fcm_token, fmc_token = :fmc_token WHERE app_id = :app_id");
    return $stmt2->execute([
        ':fcm_token' => $fcmToken,
        ':fmc_token' => $fcmToken,
        ':app_id' => $appId
    ]);
}

/**
 * Simulates or sends a Firebase Cloud Messaging push notification.
 * If service credentials are set, dispatches via the real FCM HTTP v1 API.
 * Logs target payload to fastrand/logs/fcm_notifications.log, and
 * creates/updates the user_notifications table in the database to record the alert history.
 */
function send_fcm_notification($fcmToken, $title, $body, $data = [], $imageUrl = null, $category = 'Updates') {
    $fcmTokenVal = !empty($fcmToken) ? trim($fcmToken) : 'NO_TOKEN_REGISTERED';
    if (!is_array($data)) {
        $data = [];
    }
    $data['category'] = $category;

    $notification = [
        'title' => $title,
        'body' => $body
    ];
    if ($imageUrl) {
        $notification['image'] = $imageUrl;
    }

    $message = [
        'token' => $fcmTokenVal,
        'notification' => $notification
    ];
    
    if (!empty($data) && is_array($data)) {
        $stringData = [];
        foreach ($data as $k => $v) {
            if ($v !== null) {
                $stringData[(string)$k] = (string)$v;
            }
        }
        if (!empty($stringData)) {
            $message['data'] = $stringData;
        }
    }

    $payload = [
        'message' => $message
    ];
    
    // Check if Firebase service credentials are set
    $creds = get_firebase_credentials();
    $isRealSend = false;
    $sendResult = null;
    $sentStatus = 'SUCCESS';
    $errorMessage = '';
    
    if ($creds && !empty($creds['project_id']) && $fcmTokenVal !== 'NO_TOKEN_REGISTERED') {
        $accessToken = get_google_access_token($creds);
        if ($accessToken) {
            $isRealSend = true;
            $url = 'https://fcm.googleapis.com/v1/projects/' . $creds['project_id'] . '/messages:send';
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json'
            ]);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            
            $fcmResponse = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            $sendResult = json_decode($fcmResponse, true);
            if ($httpCode === 200) {
                $sentStatus = 'SUCCESS';
            } else {
                $sentStatus = 'FAILED';
                $errorMessage = isset($sendResult['error']['message']) ? $sendResult['error']['message'] : 'FCM API rejected dispatch request.';
            }
        } else {
            $errorMessage = 'Failed to generate Google OAuth2 access token. Please check your private key format.';
            $sentStatus = 'FAILED';
        }
    } else {
        // Simulated or logged notification (no credentials saved or no token provided)
        $sentStatus = 'SUCCESS';
        if ($fcmTokenVal === 'NO_TOKEN_REGISTERED') {
            $errorMessage = 'Simulated: No device token registered for recipient.';
        }
    }
    
    // Log target payload
    $logDir = __DIR__ . '/logs';
    if (!is_dir($logDir)) {
        mkdir($logDir, 0777, true);
    }
    
    $logEntry = [
        'time' => date('Y-m-d H:i:s'),
        'is_real_send' => $isRealSend,
        'sent_status' => $sentStatus,
        'error' => $errorMessage,
        'payload' => $payload,
        'fcm_response' => $sendResult
    ];
    file_put_contents($logDir . '/fcm_notifications.log', json_encode($logEntry) . "\n", FILE_APPEND);
    
    // DB tracking
    $pdo = get_db_connection();
    
    // Resolve app_id
    $appId = null;
    if (isset($data['app_id'])) {
        $appId = trim($data['app_id']);
    }
    if (empty($appId) && !empty($fcmToken) && $fcmToken !== 'NO_TOKEN_REGISTERED') {
        try {
            $stmt = $pdo->prepare("SELECT app_id FROM accounts WHERE fcm_token = :token LIMIT 1");
            $stmt->execute([':token' => $fcmToken]);
            $appId = $stmt->fetchColumn();
            if (!$appId) {
                $stmt = $pdo->prepare("SELECT app_id FROM applications WHERE fcm_token = :token LIMIT 1");
                $stmt->execute([':token' => $fcmToken]);
                $appId = $stmt->fetchColumn();
            }
        } catch (PDOException $ex) {
            // Ignore if tables do not exist yet
        }
    }

    try {
        $pdo->query("SELECT id FROM user_notifications LIMIT 1");
    } catch (PDOException $e) {
        $pdo->exec("CREATE TABLE IF NOT EXISTS user_notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            app_id VARCHAR(50) NULL,
            fcm_token TEXT NOT NULL,
            title VARCHAR(255) NOT NULL,
            body TEXT NOT NULL,
            image_url VARCHAR(255) NULL,
            category VARCHAR(50) DEFAULT 'Updates',
            sent_status VARCHAR(20) DEFAULT 'SUCCESS',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_notifications_app_id (app_id)
        ) ENGINE=InnoDB;");
    }

    // Auto migrate table to add app_id if not exists
    try {
        $pdo->query("SELECT app_id FROM user_notifications LIMIT 1");
    } catch (PDOException $e) {
        try {
            $pdo->exec("ALTER TABLE user_notifications ADD COLUMN app_id VARCHAR(50) NULL AFTER id, ADD INDEX idx_user_notifications_app_id (app_id)");
        } catch (PDOException $ex) {}
    }

    // Auto migrate table to add image_url if not exists
    try {
        $pdo->query("SELECT image_url FROM user_notifications LIMIT 1");
    } catch (PDOException $e) {
        $pdo->exec("ALTER TABLE user_notifications ADD COLUMN image_url VARCHAR(255) NULL AFTER body");
    }

    // Auto migrate table to add category if not exists
    try {
        $pdo->query("SELECT category FROM user_notifications LIMIT 1");
    } catch (PDOException $e) {
        $pdo->exec("ALTER TABLE user_notifications ADD COLUMN category VARCHAR(50) DEFAULT 'Updates' AFTER image_url");
    }
    
    // Ensure existing user_notifications tables are altered to TEXT for fcm_token to support long keys
    try {
        $pdo->exec("ALTER TABLE user_notifications MODIFY COLUMN fcm_token TEXT NOT NULL");
    } catch (PDOException $e) {
        // Ignore if fails
    }
    
    $stmt = $pdo->prepare("INSERT INTO user_notifications (app_id, fcm_token, title, body, image_url, category, sent_status) VALUES (:app_id, :token, :title, :body, :image_url, :category, :status)");
    $stmt->execute([
        ':app_id' => $appId,
        ':token' => $fcmTokenVal,
        ':title' => $title,
        ':body' => $body,
        ':image_url' => $imageUrl,
        ':category' => $category,
        ':status' => $sentStatus
    ]);
    
    if ($sentStatus === 'FAILED') {
        return [
            'success' => false,
            'message' => $errorMessage,
            'response' => $sendResult
        ];
    }
    
    return [
        'success' => true, 
        'message' => $isRealSend ? 'Notification sent successfully via FCM.' : 'Notification sent successfully (simulated).',
        'payload' => $payload,
        'response' => $sendResult
    ];
}

/**
 * Resolves a customer's FCM token and dispatches a push notification to that user's device.
 */
function send_notification_to_user($appId, $title, $body, $data = [], $imageUrl = null, $category = 'Updates') {
    $pdo = get_db_connection();
    $token = null;
    
    // Look up in accounts table first
    try {
        $stmt = $pdo->prepare("SELECT fcm_token FROM accounts WHERE app_id = :app_id LIMIT 1");
        $stmt->execute([':app_id' => $appId]);
        $token = $stmt->fetchColumn();
    } catch (PDOException $e) {}
    
    // Look up in applications table if missing
    if (empty($token)) {
        try {
            $stmt = $pdo->prepare("SELECT fcm_token FROM applications WHERE app_id = :app_id LIMIT 1");
            $stmt->execute([':app_id' => $appId]);
            $token = $stmt->fetchColumn();
            
            if (empty($token)) {
                $stmt = $pdo->prepare("SELECT fmc_token FROM applications WHERE app_id = :app_id LIMIT 1");
                $stmt->execute([':app_id' => $appId]);
                $token = $stmt->fetchColumn();
            }
        } catch (PDOException $e) {}
    }
    
    if (empty($token)) {
        $token = 'NO_TOKEN_REGISTERED';
    }
    
    if (!is_array($data)) {
        $data = [];
    }
    $data['app_id'] = $appId;
    
    return send_fcm_notification($token, $title, $body, $data, $imageUrl, $category);
}

/**
 * Retrieves all unique FCM tokens registered in the applications table
 */
function get_all_fcm_tokens() {
    $pdo = get_db_connection();
    $stmt = $pdo->query("SELECT DISTINCT app_id, fcm_token, full_name FROM applications WHERE fcm_token IS NOT NULL AND fcm_token != ''");
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Read the saved Firebase Service Account JSON credentials from server storage
 */
function get_firebase_credentials() {
    $filePath = __DIR__ . '/config/firebase_service_account.json';
    if (!file_exists($filePath)) {
        return null;
    }
    $content = file_get_contents($filePath);
    return json_decode($content, true);
}

/**
 * Generates Google OAuth2 Access Token using pure PHP JWT signing (RS256)
 */
function get_google_access_token($serviceAccount) {
    if (empty($serviceAccount['private_key']) || empty($serviceAccount['client_email'])) {
        return null;
    }
    
    $privateKey = $serviceAccount['private_key'];
    
    // Header
    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    
    // Claims
    $now = time();
    $claims = json_encode([
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now
    ]);
    $base64UrlClaims = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($claims));
    
    $assertionInput = $base64UrlHeader . '.' . $base64UrlClaims;
    
    $signature = '';
    if (!openssl_sign($assertionInput, $signature, $privateKey, OPENSSL_ALGO_SHA256)) {
        return null;
    }
    
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    $jwt = $assertionInput . '.' . $base64UrlSignature;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        return null;
    }
    
    $resData = json_decode($response, true);
    return isset($resData['access_token']) ? $resData['access_token'] : null;
}

/**
 * Returns notifications for a specific application ID, optionally filtered by category
 */
function get_notifications_by_app_id($appId, $category = null) {
    $pdo = get_db_connection();
    if ($category) {
        $stmt = $pdo->prepare("SELECT * FROM user_notifications WHERE app_id = :app_id AND category = :category ORDER BY created_at DESC");
        $stmt->execute([
            ':app_id' => $appId,
            ':category' => $category
        ]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM user_notifications WHERE app_id = :app_id ORDER BY created_at DESC");
        $stmt->execute([
            ':app_id' => $appId
        ]);
    }
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Read the saved Bharat4u Payout credentials from server storage
 */
function get_payout_credentials() {
    $filePath = __DIR__ . '/config/bharat4u_credentials.json';
    if (!file_exists($filePath)) {
        return [
            'bharat_mid' => '',
            'bharat_key' => ''
        ];
    }
    $content = file_get_contents($filePath);
    return json_decode($content, true) ?: [
        'bharat_mid' => '',
        'bharat_key' => ''
    ];
}

/**
 * Save the Bharat4u Payout credentials to server config file
 */
function save_payout_credentials($mid, $key) {
    $dir = __DIR__ . '/config';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    $filePath = $dir . '/bharat4u_credentials.json';
    $data = [
        'bharat_mid' => trim($mid),
        'bharat_key' => trim($key)
    ];
    return file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT)) !== false;
}

/**
 * Retrieve all transactions marked as FAILED_HELD for admin review/process
 */
function get_failed_payouts() {
    $pdo = get_db_connection();
    $stmt = $pdo->query("
        SELECT t.*, sa.full_name as sender_name
        FROM transactions t
        LEFT JOIN applications sa ON t.sender_app_id = sa.app_id
        WHERE t.status = 'FAILED_HELD' AND t.type = 'BANK_TRANSFER'
        ORDER BY t.created_at DESC
    ");
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Initiates payout using Bharat4u Payout v4 API
 */
function initiate_bharat4u_payout($orderId, $accountNumber, $ifsc, $amount, $beneficiaryName = '') {
    $creds = get_payout_credentials();
    
    // Fallback to simulation mode if credentials are not configured
    if (empty($creds['bharat_mid']) || empty($creds['bharat_key'])) {
        return [
            'success' => true,
            'message' => 'Payout initiated in Simulation Mode',
            'status' => 'PENDING'
        ];
    }

    if (empty($beneficiaryName)) {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT recipient_name FROM transactions WHERE transaction_id = :order_id LIMIT 1");
            $stmt->execute([':order_id' => $orderId]);
            $beneficiaryName = $stmt->fetchColumn() ?: 'Beneficiary';
        } catch (Exception $e) {
            $beneficiaryName = 'Beneficiary';
        }
    }
    
    $payload = [
        'bharat_mid' => $creds['bharat_mid'],
        'bharat_key' => $creds['bharat_key'],
        'order_id' => $orderId,
        'beneficiary_name' => $beneficiaryName,
        'account_number' => $accountNumber,
        'ifsc' => $ifsc,
        'amount' => (string)$amount
    ];
    
    $ch = curl_init('https://api.bharat4upe.com/api/payout/v4/transfer');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Bharat4u V4 API returned HTTP code $httpCode: $response");
    }
    
    $resData = json_decode($response, true);
    if (!$resData || (isset($resData['status']) && $resData['status'] === false) || (isset($resData['success']) && $resData['success'] === false)) {
        $msg = isset($resData['msg']) ? $resData['msg'] : (isset($resData['message']) ? $resData['message'] : 'Unknown error');
        throw new Exception($msg);
    }
    
    return $resData;
}

/**
 * Checks payout status from Bharat4u Payout v3 API
 */
function check_bharat4u_payout_status($orderId) {
    $creds = get_payout_credentials();
    if (empty($creds['bharat_mid']) || empty($creds['bharat_key'])) {
        // Simulation fallback: return success status
        return [
            'status' => true,
            'msg' => 'Payout Successful',
            'data' => [
                'order_id' => $orderId,
                'provider_txn_id' => 'ARNPY' . time(),
                'utr' => 'SIMUTR' . mt_rand(100000, 999999),
                'amount' => '1.00',
                'status' => 'SUCCESS'
            ]
        ];
    }
    
    $payload = [
        'PM_MID' => $creds['bharat_mid'], // Postman parameters check
        'bharat_mid' => $creds['bharat_mid'],
        'bharat_key' => $creds['bharat_key'],
        'order_id' => $orderId
    ];
    
    $ch = curl_init('https://api.bharat4upe.com/api/payout/v3/status');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Status check failed. HTTP code $httpCode: $response");
    }
    
    $resData = json_decode($response, true);
    if (!$resData) {
        throw new Exception("Invalid JSON response from provider");
    }
    
    return $resData;
}

/**
 * Fetches user compliance document by app_id and type
 */
function get_user_compliance($appId, $type) {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("SELECT * FROM user_compliance WHERE app_id = :app_id AND type = :type LIMIT 1");
    $stmt->execute([
        ':app_id' => $appId,
        ':type' => $type
    ]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Saves or updates compliance details
 */
function save_user_compliance($appId, $type, $textContent, $imagePath, $pdfPath) {
    $pdo = get_db_connection();
    
    // Check if record exists
    $existing = get_user_compliance($appId, $type);
    if ($existing) {
        $stmt = $pdo->prepare("UPDATE user_compliance SET text_content = :text_content, image_path = :image_path, pdf_path = :pdf_path WHERE app_id = :app_id AND type = :type");
        return $stmt->execute([
            ':text_content' => $textContent,
            ':image_path' => $imagePath,
            ':pdf_path' => $pdfPath,
            ':app_id' => $appId,
            ':type' => $type
        ]);
    } else {
        $stmt = $pdo->prepare("INSERT INTO user_compliance (app_id, type, text_content, image_path, pdf_path) VALUES (:app_id, :type, :text_content, :image_path, :pdf_path)");
        return $stmt->execute([
            ':app_id' => $appId,
            ':type' => $type,
            ':text_content' => $textContent,
            ':image_path' => $imagePath,
            ':pdf_path' => $pdfPath
        ]);
    }
}

/**
 * Checks payout status from Bharat4u Payout v4 API
 */
function check_bharat4u_payout_status_v4($orderId) {
    $creds = get_payout_credentials();
    if (empty($creds['bharat_mid']) || empty($creds['bharat_key'])) {
        // Simulation fallback: return success status
        return [
            'status' => true,
            'data' => [
                'order_id' => $orderId,
                'amount' => '1.00',
                'txn_status' => 'SUCCESS',
                'utr' => 'SIMUTR' . mt_rand(100000, 999999)
            ]
        ];
    }
    
    $payload = [
        'bharat_mid' => $creds['bharat_mid'],
        'bharat_key' => $creds['bharat_key'],
        'order_id' => $orderId
    ];
    
    $ch = curl_init('https://api.bharat4upe.com/api/payout/v4/status');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        $cleanResponse = strip_tags($response);
        $cleanResponse = preg_replace('/\s+/', ' ', $cleanResponse);
        $cleanResponse = substr(trim($cleanResponse), 0, 100);
        throw new Exception("Status check V4 failed. HTTP code $httpCode: $cleanResponse");
    }
    
    $resData = json_decode($response, true);
    if (!$resData) {
        throw new Exception("Invalid JSON response from V4 provider: " . $response);
    }
    
    return $resData;
}

/**
 * Retrieve the last payout sync timestamp
 */
function get_last_sync_time() {
    $filePath = __DIR__ . '/config/last_payout_sync.json';
    if (!file_exists($filePath)) {
        return 0;
    }
    $content = file_get_contents($filePath);
    $data = json_decode($content, true);
    return isset($data['last_sync_time']) ? (int)$data['last_sync_time'] : 0;
}

/**
 * Update the last payout sync timestamp
 */
function update_last_sync_time() {
    $filePath = __DIR__ . '/config/last_payout_sync.json';
    $data = ['last_sync_time' => time()];
    file_put_contents($filePath, json_encode($data));
}

/**
 * Fetches all transactions for the administrator dashboard/list
 */
function get_all_transactions() {
    $pdo = get_db_connection();
    $stmt = $pdo->prepare("
        SELECT t.*, 
               sa.full_name as sender_name,
               ra.full_name as recipient_name
        FROM transactions t
        LEFT JOIN applications sa ON t.sender_app_id = sa.app_id
        LEFT JOIN accounts acc ON t.recipient_account = acc.account_number
        LEFT JOIN applications ra ON acc.app_id = ra.app_id
        ORDER BY t.created_at DESC
    ");
    $stmt->execute();
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Updates a transaction status and handles balance updates/refunds as necessary
 */
function update_transaction_status($txnId, $newStatus, $utrId = null, $remarks = null, $sendNotif = true) {
    $pdo = get_db_connection();
    
    // Fetch transaction
    $stmt = $pdo->prepare("SELECT * FROM transactions WHERE transaction_id = :txn_id LIMIT 1");
    $stmt->execute([':txn_id' => $txnId]);
    $txn = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$txn) {
        throw new Exception("Transaction not found.");
    }
    
    $oldStatus = $txn['status'];
    if ($oldStatus === $newStatus) {
        // If UTR is updated, update it even if status remains the same
        if (!empty($utrId) && $txn['utr_id'] !== $utrId) {
            $stmtUpdateUtr = $pdo->prepare("UPDATE transactions SET utr_id = :utr_id WHERE transaction_id = :txn_id");
            $stmtUpdateUtr->execute([':utr_id' => $utrId, ':txn_id' => $txnId]);
        }
        return true;
    }
    
    $pdo->beginTransaction();
    
    $statusDetails = $remarks ?: "Status updated manually";
    
    $stmtUpdate = $pdo->prepare("UPDATE transactions SET status = :status, utr_id = :utr_id, status_details = :status_details WHERE transaction_id = :txn_id");
    $stmtUpdate->execute([
        ':status' => $newStatus,
        ':utr_id' => !empty($utrId) ? $utrId : $txn['utr_id'],
        ':status_details' => $statusDetails,
        ':txn_id' => $txnId
    ]);
    
    // Payout (BANK_TRANSFER) Refund / Re-deduct Logic
    if ($txn['type'] === 'BANK_TRANSFER') {
        // Balance updates
        if ($newStatus === 'FAILED' && $oldStatus !== 'FAILED') {
            // Refund sender balance
            $stmtRefund = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :sender_app_id");
            $stmtRefund->execute([
                ':amount' => $txn['amount'],
                ':sender_app_id' => $txn['sender_app_id']
            ]);
        }
        elseif ($oldStatus === 'FAILED' && $newStatus !== 'FAILED') {
            // Verify if user has enough balance
            $sender = get_application_by_id($txn['sender_app_id']);
            if ($sender && (float)$sender['balance'] < (float)$txn['amount']) {
                $pdo->rollBack();
                throw new Exception("Cannot change status: Sender account has insufficient balance (" . number_format($sender['balance'], 2) . " INR) to re-deduct " . number_format($txn['amount'], 2) . " INR.");
            }
            
            // Re-deduct balance
            $stmtDeduct = $pdo->prepare("UPDATE applications SET balance = balance - :amount WHERE app_id = :sender_app_id");
            $stmtDeduct->execute([
                ':amount' => $txn['amount'],
                ':sender_app_id' => $txn['sender_app_id']
            ]);
        }

        // Push Notifications
        if ($sendNotif) {
            if ($newStatus === 'FAILED' && $oldStatus !== 'FAILED') {
                try {
                    $notifyTitle = "Payment Refunded";
                    $notifyBody = "Your payout transaction of " . number_format($txn['amount'], 2) . " INR has failed, and the amount has been refunded to your account balance.";
                    send_notification_to_user($txn['sender_app_id'], $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (Exception $e) {}
            }
            elseif ($newStatus === 'SUCCESS' && $oldStatus !== 'SUCCESS') {
                try {
                    $notifyTitle = "Payout Successful";
                    $notifyBody = "Your payout transfer of " . number_format($txn['amount'], 2) . " INR to account " . $txn['recipient_account'] . " has been completed. UTR: " . ($utrId ?: $txn['utr_id']);
                    send_notification_to_user($txn['sender_app_id'], $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (Exception $e) {}
            }
            elseif ($oldStatus === 'FAILED' && $newStatus === 'PENDING') {
                try {
                    $notifyTitle = "Account Debited";
                    $notifyBody = "Your account has been debited by " . number_format($txn['amount'], 2) . " INR for payout transfer. Ref: " . $txnId;
                    send_notification_to_user($txn['sender_app_id'], $notifyTitle, $notifyBody, [], null, 'Transactions');
                } catch (Exception $e) {}
            }
        }
    }
    // Deposit (DEPOSIT) Credit / Reverse-Deduct Logic
    elseif ($txn['type'] === 'DEPOSIT') {
        if ($newStatus === 'SUCCESS' && $oldStatus !== 'SUCCESS') {
            $account = get_account_by_number($txn['recipient_account']);
            if ($account) {
                $appId = $account['app_id'];
                // Credit user balance
                $stmtCredit = $pdo->prepare("UPDATE applications SET balance = balance + :amount WHERE app_id = :app_id");
                $stmtCredit->execute([
                    ':amount' => $txn['amount'],
                    ':app_id' => $appId
                ]);
                
                // Notify user of credit
                if ($sendNotif) {
                    try {
                        $notifyTitle = "Account Credited";
                        $notifyBody = "Your account has been credited by " . number_format($txn['amount'], 2) . " INR. UTR: " . ($utrId ?: $txn['utr_id']);
                        send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                    } catch (Exception $e) {
                        // Ignore
                    }
                }
            }
        }
        elseif ($oldStatus === 'SUCCESS' && ($newStatus === 'FAILED' || $newStatus === 'PENDING' || $newStatus === 'FAILED_HELD')) {
            $account = get_account_by_number($txn['recipient_account']);
            if ($account) {
                $appId = $account['app_id'];
                // Revert credit (deduct)
                $stmtDeduct = $pdo->prepare("UPDATE applications SET balance = balance - :amount WHERE app_id = :app_id");
                $stmtDeduct->execute([
                    ':amount' => $txn['amount'],
                    ':app_id' => $appId
                ]);
                
                // Notify user
                if ($sendNotif) {
                    try {
                        $notifyTitle = "Account Debited";
                        $notifyBody = "Your deposit of " . number_format($txn['amount'], 2) . " INR has been reversed. Ref: " . $txnId;
                        send_notification_to_user($appId, $notifyTitle, $notifyBody, [], null, 'Transactions');
                    } catch (Exception $e) {
                        // Ignore
                    }
                }
            }
        }
    }
    
    $pdo->commit();
    return true;
}

/**
 * Read the active payout provider from payout_settings.json
 */
function get_active_payout_provider() {
    $filePath = __DIR__ . '/config/payout_settings.json';
    if (!file_exists($filePath)) {
        return 'bharat4u';
    }
    $content = file_get_contents($filePath);
    $data = json_decode($content, true);
    return isset($data['active_provider']) ? trim($data['active_provider']) : 'bharat4u';
}

/**
 * Save the active payout provider to payout_settings.json
 */
function save_active_payout_provider($provider) {
    $dir = __DIR__ . '/config';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    $filePath = $dir . '/payout_settings.json';
    $data = [
        'active_provider' => trim($provider)
    ];
    return file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT)) !== false;
}

/**
 * Read the saved JioPay credentials from server storage
 */
function get_jiopay_credentials() {
    $filePath = __DIR__ . '/config/jiopay_credentials.json';
    if (!file_exists($filePath)) {
        return [
            'jiopay_mid' => '',
            'jiopay_key' => '',
            'entity_id' => '',
            'customer_id' => ''
        ];
    }
    $content = file_get_contents($filePath);
    return json_decode($content, true) ?: [
        'jiopay_mid' => '',
        'jiopay_key' => '',
        'entity_id' => '',
        'customer_id' => ''
    ];
}

/**
 * Save the JioPay credentials to server config file
 */
function save_jiopay_credentials($mid, $key, $entityId = '', $customerId = '') {
    $dir = __DIR__ . '/config';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    $filePath = $dir . '/jiopay_credentials.json';
    $data = [
        'jiopay_mid' => trim($mid),
        'jiopay_key' => trim($key),
        'entity_id' => trim($entityId),
        'customer_id' => trim($customerId)
    ];
    return file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT)) !== false;
}

/**
 * Initiates payout using JioPay API
 */
function initiate_jiopay_payout($orderId, $accountNumber, $ifsc, $amount, $beneficiaryName = '') {
    $creds = get_jiopay_credentials();
    
    // Fallback to simulation mode if credentials are not configured
    if (empty($creds['jiopay_mid']) || empty($creds['jiopay_key'])) {
        return [
            'success' => true,
            'message' => 'Payout initiated in Simulation Mode (JioPay)',
            'status' => 'PENDING'
        ];
    }

    if (empty($beneficiaryName)) {
        try {
            $pdo = get_db_connection();
            $stmt = $pdo->prepare("SELECT recipient_name FROM transactions WHERE transaction_id = :order_id LIMIT 1");
            $stmt->execute([':order_id' => $orderId]);
            $beneficiaryName = $stmt->fetchColumn() ?: 'Beneficiary';
        } catch (Exception $e) {
            $beneficiaryName = 'Beneficiary';
        }
    }
    
    $payload = [
        'bharat_mid' => $creds['jiopay_mid'],
        'bharat_key' => $creds['jiopay_key'],
        'entityId' => $creds['entity_id'],
        'customerId' => $creds['customer_id'],
        'order_id' => $orderId,
        'beneficiary_name' => $beneficiaryName,
        'account_number' => $accountNumber,
        'ifsc' => $ifsc,
        'amount' => (string)$amount
    ];
    
    $ch = curl_init('https://api.bharat4upe.com/api/payout/jiopay_route/transfer');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("JioPay API returned HTTP code $httpCode: $response");
    }
    
    $resData = json_decode($response, true);
    if (!$resData || (isset($resData['status']) && $resData['status'] === false) || (isset($resData['success']) && $resData['success'] === false)) {
        $msg = isset($resData['msg']) ? $resData['msg'] : (isset($resData['message']) ? $resData['message'] : 'Unknown error');
        throw new Exception($msg);
    }
    
    return $resData;
}

/**
 * Checks payout status from JioPay Payout API
 */
function check_jiopay_payout_status($orderId) {
    $creds = get_jiopay_credentials();
    if (empty($creds['jiopay_mid']) || empty($creds['jiopay_key'])) {
        // Simulation fallback: return success status
        return [
            'status' => true,
            'data' => [
                'order_id' => $orderId,
                'amount' => '1.00',
                'txn_status' => 'SUCCESS',
                'utr' => 'SIMUTR' . mt_rand(100000, 999999)
            ]
        ];
    }
    
    $payload = [
        'bharat_mid' => $creds['jiopay_mid'],
        'bharat_key' => $creds['jiopay_key'],
        'order_id' => $orderId
    ];
    
    $ch = curl_init('https://api.bharat4upe.com/api/payout/v4/status');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("JioPay Status check failed. HTTP code $httpCode: $response");
    }
    
    $resData = json_decode($response, true);
    if (!$resData) {
        throw new Exception("Invalid JSON response from JioPay provider");
    }
    
    return $resData;
}

/**
 * Read the front page maintenance mode status from system_settings database table
 */
function get_maintenance_mode() {
    try {
        $pdo = get_db_connection();
        $pdo->exec("CREATE TABLE IF NOT EXISTS system_settings (
            setting_key VARCHAR(50) PRIMARY KEY,
            setting_value TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        $stmt = $pdo->prepare("SELECT setting_value FROM system_settings WHERE setting_key = 'maintenance_mode' LIMIT 1");
        $stmt->execute();
        $val = $stmt->fetchColumn();
        if ($val === false) {
            // Seed if not exists
            $pdo->exec("INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES ('maintenance_mode', '0');");
            return 0;
        }
        return (int)$val;
    } catch (\Exception $e) {
        error_log("Failed to get maintenance mode from DB: " . $e->getMessage());
        // Fallback to checking the JSON file if DB query fails
        $filePath = __DIR__ . '/config/maintenance_settings.json';
        if (!file_exists($filePath)) {
            return 0; 
        }
        $content = file_get_contents($filePath);
        $data = json_decode($content, true);
        return isset($data['maintenance_mode']) ? (int)$data['maintenance_mode'] : 0;
    }
}

/**
 * Save the front page maintenance mode status to system_settings database table
 */
function save_maintenance_mode($enabled) {
    try {
        $pdo = get_db_connection();
        $pdo->exec("CREATE TABLE IF NOT EXISTS system_settings (
            setting_key VARCHAR(50) PRIMARY KEY,
            setting_value TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;");

        $stmt = $pdo->prepare("INSERT INTO system_settings (setting_key, setting_value) 
            VALUES ('maintenance_mode', :val) 
            ON DUPLICATE KEY UPDATE setting_value = :val2");
        $val = (string)(int)$enabled;
        $res = $stmt->execute([
            ':val' => $val,
            ':val2' => $val
        ]);

        // Also write to JSON file as local cache fallback
        $dir = __DIR__ . '/config';
        if (is_dir($dir) || @mkdir($dir, 0755, true)) {
            $filePath = $dir . '/maintenance_settings.json';
            $data = ['maintenance_mode' => (int)$enabled];
            @file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT));
        }

        return $res;
    } catch (\Exception $e) {
        error_log("Failed to save maintenance mode to DB: " . $e->getMessage());
        // Fallback to file write
        $dir = __DIR__ . '/config';
        if (!is_dir($dir)) {
            @mkdir($dir, 0755, true);
        }
        $filePath = $dir . '/maintenance_settings.json';
        $data = [
            'maintenance_mode' => (int)$enabled
        ];
        return @file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT)) !== false;
    }
}








