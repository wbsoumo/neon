<?php
/**
 * Deccan Finance - Bank Statement PDF Generator API
 * Scope: Authenticated Customer Session
 */

header('Content-Type: application/json');
require_once 'db_helper.php';
require_once dirname(__DIR__) . '/vendor/autoload.php';

// Get request parameters (POST/JSON/GET)
$data = $_POST;
if (empty($data)) {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true) ?: [];
}

// 1. Resolve session ID if passed explicitly
$passedSessionId = null;
if (!empty($data['session_id'])) {
    $passedSessionId = trim($data['session_id']);
} elseif (!empty($_GET['session_id'])) {
    $passedSessionId = trim($_GET['session_id']);
}

// Check headers for X-Session-ID or Authorization bearer
$headers = function_exists('getallheaders') ? getallheaders() : [];
if (empty($passedSessionId)) {
    if (!empty($headers['X-Session-ID'])) {
        $passedSessionId = trim($headers['X-Session-ID']);
    } elseif (!empty($headers['x-session-id'])) {
        $passedSessionId = trim($headers['x-session-id']);
    } elseif (!empty($_SERVER['HTTP_X_SESSION_ID'])) {
        $passedSessionId = trim($_SERVER['HTTP_X_SESSION_ID']);
    } elseif (!empty($headers['Authorization'])) {
        $auth = trim($headers['Authorization']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    } elseif (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = trim($_SERVER['HTTP_AUTHORIZATION']);
        if (stripos($auth, 'Bearer ') === 0) {
            $passedSessionId = substr($auth, 7);
        }
    }
}

// If explicit session ID is provided, load it
if (!empty($passedSessionId)) {
    session_id($passedSessionId);
}

// Start PHP session
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Check if customer or admin is logged in
$isAdmin = (!empty($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true);
$isCustomer = (!empty($_SESSION['customer_logged_in']) && $_SESSION['customer_logged_in'] === true);

if (!$isAdmin && !$isCustomer) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized. Please log in first.'
    ]);
    exit;
}

// Resolve appId
$appId = '';
if ($isAdmin) {
    $appId = isset($data['app_id']) ? trim($data['app_id']) : (isset($_GET['app_id']) ? trim($_GET['app_id']) : '');
    if (empty($appId)) {
        // Fallback to first user if not provided
        $pdo = get_db_connection();
        $appId = $pdo->query("SELECT app_id FROM applications LIMIT 1")->fetchColumn();
    }
} else {
    $appId = $_SESSION['customer_app_id'];
}

if (empty($appId)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Application ID is required.'
    ]);
    exit;
}

try {
    // 1. Fetch user profile and account details
    $user = get_application_by_id($appId);
    $account = get_account_by_app_id($appId);
    
    if (!$user || !$account) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User or account details not found.'
        ]);
        exit;
    }
    
    // 2. Fetch transactions and compute running balance ledger
    $txns = get_transactions_by_app_id($appId);
    
    // Sort transactions chronologically (oldest first)
    $txns = array_reverse($txns);
    
    // Build ledger array
    $ledger = [];
    $runningBalance = (float)$user['initial_deposit'];
    
    // Initial balance forward entry
    $ledger[] = [
        'date' => date('d M y', strtotime($user['created_at'])),
        'val_date' => date('d M y', strtotime($user['created_at'])),
        'description' => 'BALANCE FORWARD (INITIAL DEPOSIT)',
        'deposit' => number_format((float)$user['initial_deposit'], 2),
        'withdrawal' => '-',
        'balance' => number_format($runningBalance, 2)
    ];
    
    foreach ($txns as $t) {
        $amount = (float)$t['amount'];
        $isCredit = ($t['flow_type'] === 'CREDIT');
        
        if ($isCredit) {
            $runningBalance += $amount;
            $depositStr = number_format($amount, 2);
            $withdrawalStr = '-';
        } else {
            $runningBalance -= $amount;
            $depositStr = '-';
            $withdrawalStr = number_format($amount, 2);
        }
        
        // Build descriptive string based on transfer details
        $desc = '';
        if ($t['type'] === 'P2P') {
            if ($isCredit) {
                $desc = 'UPI CREDIT FROM ' . ($t['sender_name'] ?: 'Acc Holder') . ' (' . $t['sender_app_id'] . ')';
            } else {
                $desc = 'UPI DEBIT TO ACC ' . $t['recipient_account'] . ' (' . ($t['recipient_name'] ?: 'Acc Holder') . ')';
            }
        } elseif ($t['type'] === 'BANK_TRANSFER' || $t['type'] === 'PAYOUT') {
            $desc = 'BANK PAYOUT TO ' . ($t['recipient_name'] ?: 'Beneficiary') . ' ACC ' . $t['recipient_account'];
            if (!empty($t['ifsc_code'])) {
                $desc .= ' IFSC ' . $t['ifsc_code'];
            }
        } else {
            $desc = 'TXN ' . $t['type'] . ' - ' . $t['transaction_id'];
        }
        
        if (!empty($t['remarks'])) {
            $desc .= ' - ' . $t['remarks'];
        }
        
        if (!empty($t['utr_id'])) {
            $desc .= ' UTR: ' . $t['utr_id'];
        }
        
        $ledger[] = [
            'date' => date('d M y', strtotime($t['created_at'])),
            'val_date' => date('d M y', strtotime($t['created_at'])),
            'description' => $desc,
            'deposit' => $depositStr,
            'withdrawal' => $withdrawalStr,
            'balance' => number_format($runningBalance, 2)
        ];
    }
    
    // 3. Setup PDF Generation using FPDF
    class PDF extends \Fpdf\Fpdf {
        // Page footer
        function Footer() {
            // Position at 1.5 cm from bottom
            $this->SetY(-15);
            $this->SetFont('Arial', 'I', 8);
            $this->SetTextColor(120, 120, 120);
            
            // Draw line above footer
            $this->Line(10, $this->GetY() - 2, 200, $this->GetY() - 2);
            
            // Page number & copyright
            $this->Cell(0, 10, 'Page ' . $this->PageNo() . ' of {nb}', 0, 0, 'L');
            $this->Cell(0, 10, 'Deccan Finance Limited - Registered CIN: U65910TN1978PLC007633', 0, 0, 'R');
        }
    }
    
    // Instantiate PDF (A4 Portrait, Unit is mm)
    $pdf = new PDF('P', 'mm', 'A4');
    $pdf->AliasNbPages();
    $pdf->SetMargins(10, 15, 10);
    $pdf->AddPage();
    
    // Colors Definition (Deccan Finance Theme: Navy & Gold)
    $navyR = 3;   $navyG = 31;  $navyB = 115;  // #031f73
    $goldR = 254; $goldG = 203; $goldB = 0;    // #fecb00
    
    // Header Section (Branded)
    // Left: Bank Title and Contact Address
    $pdf->SetFont('Arial', 'B', 18);
    $pdf->SetTextColor($navyR, $navyG, $navyB);
    $pdf->Cell(120, 8, 'DECCAN FINANCE', 0, 1, 'L');
    
    $pdf->SetFont('Arial', 'B', 8);
    $pdf->SetTextColor(80, 80, 80);
    $pdf->Cell(120, 4, 'REGISTERED OFFICE:', 0, 1, 'L');
    $pdf->SetFont('Arial', '', 8);
    $pdf->Cell(120, 4, 'No. 20, 3rd Floor, Pycrofts Garden Road, Nungambakkam,', 0, 1, 'L');
    $pdf->Cell(120, 4, 'Chennai - 600006, Tamil Nadu, India.', 0, 1, 'L');
    $pdf->Cell(120, 4, 'IFSC: DECC0007633 | Phone: +91 44 2827 2534', 0, 1, 'L');
    
    // Right: Logo image (placed in top-right)
    $logoPath = dirname(__DIR__) . '/assets/img/logo.png';
    if (file_exists($logoPath)) {
        // Position logo image (X: 155, Y: 15, Width: 45)
        $pdf->Image($logoPath, 155, 15, 45, 15);
    }
    
    $pdf->Ln(8);
    
    // Draw thick colored header divider line
    $pdf->SetDrawColor($navyR, $navyG, $navyB);
    $pdf->SetLineWidth(0.8);
    $pdf->Line(10, $pdf->GetY(), 200, $pdf->GetY());
    $pdf->Ln(4);
    
    // Title
    $pdf->SetFont('Arial', 'B', 14);
    $pdf->SetTextColor($navyR, $navyG, $navyB);
    $pdf->Cell(0, 8, 'ACCOUNT STATEMENT', 0, 1, 'C');
    $pdf->Ln(2);
    
    // Profile Box & Branch Details Grid
    $startY = $pdf->GetY();
    
    // Left Block: Customer Details
    $pdf->SetY($startY);
    $pdf->SetFont('Arial', 'B', 9);
    $pdf->SetTextColor(80, 80, 80);
    $pdf->Cell(95, 5, 'CUSTOMER DETAILS', 0, 1, 'L');
    
    $pdf->SetFont('Arial', 'B', 10);
    $pdf->SetTextColor(0, 0, 0);
    $pdf->Cell(95, 5, strtoupper($user['full_name']), 0, 1, 'L');
    
    $pdf->SetFont('Arial', '', 9);
    $pdf->MultiCell(95, 4, $user['address'], 0, 'L');
    $pdf->Cell(95, 4, 'Phone: ' . $user['phone'], 0, 1, 'L');
    $pdf->Cell(95, 4, 'Email: ' . $user['email'], 0, 1, 'L');
    
    $endLeftY = $pdf->GetY();
    
    // Right Block: Account Details Table
    $pdf->SetY($startY);
    $pdf->SetX(115);
    $pdf->SetFont('Arial', 'B', 9);
    $pdf->SetTextColor(80, 80, 80);
    $pdf->Cell(75, 5, 'STATEMENT SUMMARY', 0, 1, 'L');
    
    $summaryData = [
        'BRANCH' => 'Chennai Nungambakkam',
        'STATEMENT DATE' => date('d M Y'),
        'CURRENCY' => 'INR',
        'ACCOUNT TYPE' => $user['account_type'] . ' ACCOUNT',
        'ACCOUNT NO.' => $account['account_number'],
        'NOMINEE REGISTERED' => 'Yes'
    ];
    
    $pdf->SetFont('Arial', '', 9);
    $pdf->SetTextColor(0, 0, 0);
    foreach ($summaryData as $label => $val) {
        $pdf->SetX(115);
        $pdf->SetFont('Arial', 'B', 8.5);
        $pdf->Cell(38, 4.5, $label, 0, 0, 'L');
        $pdf->SetFont('Arial', '', 8.5);
        $pdf->Cell(37, 4.5, ': ' . $val, 0, 1, 'L');
    }
    
    $endRightY = $pdf->GetY();
    
    // Align bottom margin of summary cards
    $maxY = max($endLeftY, $endRightY);
    $pdf->SetY($maxY + 6);
    
    // Transaction Details Header
    $pdf->SetFont('Arial', 'B', 10);
    $pdf->SetTextColor($navyR, $navyG, $navyB);
    $pdf->Cell(0, 6, 'TRANSACTION LEDGER', 0, 1, 'L');
    $pdf->Ln(2);
    
    // Table Headers
    $pdf->SetFont('Arial', 'B', 8.5);
    $pdf->SetTextColor(255, 255, 255);
    $pdf->SetFillColor($navyR, $navyG, $navyB);
    
    // Columns: Date (20), Value Date (20), Description (75), Deposit (25), Withdrawal (25), Balance (25) -> Total = 190
    $pdf->Cell(18, 7, 'Date', 1, 0, 'C', true);
    $pdf->Cell(18, 7, 'Value Date', 1, 0, 'C', true);
    $pdf->Cell(79, 7, 'Description', 1, 0, 'L', true);
    $pdf->Cell(25, 7, 'Deposit', 1, 0, 'R', true);
    $pdf->Cell(25, 7, 'Withdrawal', 1, 0, 'R', true);
    $pdf->Cell(25, 7, 'Balance', 1, 1, 'R', true);
    
    // Table Rows
    $pdf->SetFont('Arial', '', 8);
    $pdf->SetTextColor(0, 0, 0);
    
    $fill = false;
    foreach ($ledger as $row) {
        // Calculate dynamic height needed for Description MultiCell
        // Width of description is 79
        // Measure string width
        $strWidth = $pdf->GetStringWidth($row['description']);
        $lines = ceil($strWidth / 78.0);
        if ($lines < 1) $lines = 1;
        $rowHeight = 5 * $lines;
        
        // Page break check (Page limit is 270mm height)
        if ($pdf->GetY() + $rowHeight > 275) {
            $pdf->AddPage();
            // Re-render Table Headers on new page
            $pdf->SetFont('Arial', 'B', 8.5);
            $pdf->SetTextColor(255, 255, 255);
            $pdf->SetFillColor($navyR, $navyG, $navyB);
            
            $pdf->Cell(18, 7, 'Date', 1, 0, 'C', true);
            $pdf->Cell(18, 7, 'Value Date', 1, 0, 'C', true);
            $pdf->Cell(79, 7, 'Description', 1, 0, 'L', true);
            $pdf->Cell(25, 7, 'Deposit', 1, 0, 'R', true);
            $pdf->Cell(25, 7, 'Withdrawal', 1, 0, 'R', true);
            $pdf->Cell(25, 7, 'Balance', 1, 1, 'R', true);
            
            $pdf->SetFont('Arial', '', 8);
            $pdf->SetTextColor(0, 0, 0);
        }
        
        $x = $pdf->GetX();
        $y = $pdf->GetY();
        
        // Draw alternate background colors
        $fillColor = $fill ? 245 : 255;
        $pdf->SetFillColor($fillColor, $fillColor, $fillColor);
        
        // Render Date (X, Y)
        $pdf->Cell(18, $rowHeight, $row['date'], 1, 0, 'C', true);
        
        // Render Value Date
        $pdf->Cell(18, $rowHeight, $row['val_date'], 1, 0, 'C', true);
        
        // Render Description as MultiCell (requires saving coordinates)
        $descX = $pdf->GetX();
        $descY = $pdf->GetY();
        $pdf->MultiCell(79, 5, $row['description'], 1, 'L', true);
        
        // Restore X & Y next to the MultiCell
        $pdf->SetXY($descX + 79, $descY);
        
        // Render Deposit
        $pdf->Cell(25, $rowHeight, $row['deposit'], 1, 0, 'R', true);
        
        // Render Withdrawal
        $pdf->Cell(25, $rowHeight, $row['withdrawal'], 1, 0, 'R', true);
        
        // Render Balance
        $pdf->Cell(25, $rowHeight, $row['balance'], 1, 1, 'R', true);
        
        $fill = !$fill;
    }
    
    $pdf->Ln(6);
    
    // Insurance & Regulations Note
    $pdf->SetFont('Arial', 'I', 8.5);
    $pdf->SetTextColor(80, 80, 80);
    $pdf->MultiCell(0, 4.5, "Bank deposits are covered under the insurance scheme offered by DICGC up to an aggregate value of Rs 5 lakh per depositor. Please register the Nomination details for your Savings/Deposit accounts if not done, by contacting our branch. Report irregularities in your statement within 30 days from statement date or 21 days from date of transaction for domestic debit card transactions.", 1, 'L');
    
    // 4. Save PDF to server
    $statementsDir = dirname(__DIR__) . '/uploads/statements';
    if (!is_dir($statementsDir)) {
        mkdir($statementsDir, 0777, true);
    }
    
    $filename = 'statement_' . $appId . '_' . date('Ymd_His') . '.pdf';
    $savePath = $statementsDir . '/' . $filename;
    
    // Save file
    $pdf->Output('F', $savePath);
    
    // Clean up temporary uploads to prevent storage leak
    // Keep only the most recent statement per user if needed, but saving all is standard.
    
    // 5. Output / Download Handling
    if (isset($_GET['download']) && $_GET['download'] == '1') {
        // Stream direct download to browser
        header('Content-Description: File Transfer');
        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($savePath));
        readfile($savePath);
        exit;
    }
    
    // Get protocol and host for absolute download URL
    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http');
    $host = $_SERVER['HTTP_HOST'];
    $downloadUrl = $protocol . '://' . $host . '/uploads/statements/' . $filename;
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Statement generated and saved successfully.',
        'filename' => $filename,
        'pdf_path' => 'uploads/statements/' . $filename,
        'download_url' => $downloadUrl
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred during statement generation: ' . $e->getMessage()
    ]);
}
