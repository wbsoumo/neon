<?php
/**
 * Neon Bank Onboarding - Premium International Account Opening Flow
 * Multi-Step Architecture: Nationality -> Residency -> Terms -> Personal -> Contact -> Address -> Employment -> Financial -> Tax -> ID Verification -> Documents -> Nominee -> Review -> Submit
 */

require_once "api/db_helper.php";

$ip = get_client_ip();
if (is_rate_limited($ip, 10, 10)) {
    header("Location: choose-account.php");
    exit;
}

$rawType = isset($_GET["type"]) ? strtolower(trim($_GET["type"])) : "current";
$typeMap = [
    "current" => "CURRENT",
    "everyday" => "CURRENT",
    "savings" => "SAVINGS",
    "joint" => "JOINT",
    "invest" => "INVEST",
    "vehicle" => "VEHICLE",
    "home" => "HOME"
];

$type = isset($typeMap[$rawType]) ? $typeMap[$rawType] : "CURRENT";

$accountTitles = [
    "CURRENT" => "Everyday International Current Account",
    "SAVINGS" => "High-Yield Swiss Franc Savings Account",
    "JOINT" => "Joint Account for International Duos",
    "INVEST" => "Global Equities & ETFs Investment Account",
    "VEHICLE" => "Vehicle Financing Account",
    "HOME" => "Home & Property Account"
];

$accountTitle = isset($accountTitles[$type]) ? $accountTitles[$type] : "Neon Bank Account";
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Open <?= htmlspecialchars($accountTitle) ?> - Neon Bank</title>
    
    <!-- Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="icon" type="image/webp" href="logo.webp">

    <style>
        :root {
            --neon-pink: #ff0054;
            --neon-pink-hover: #e0004a;
            --neon-cyan: #1fa9b2;
            --neon-teal: #179096;
            --neon-dark: #0f172a;
            --neon-card-bg: rgba(255, 255, 255, 0.98);
            --neon-border: #e2e8f0;
            --text-primary: #0f172a;
            --text-secondary: #64748b;
            --radius-lg: 24px;
            --radius-md: 16px;
            --radius-sm: 10px;
            --shadow-glow: 0 20px 40px -15px rgba(255, 0, 84, 0.15);
            --shadow-card: 0 16px 36px rgba(15, 23, 42, 0.06);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: "Outfit", "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 50%, #e2e8f0 100%);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            line-height: 1.5;
        }

        /* Header Navigation Bar */
        .neon-header {
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-bottom: 1px solid rgba(226, 232, 240, 0.8);
            position: sticky;
            top: 0;
            z-index: 1000;
            padding: 16px 32px;
        }
        .header-content {
            max-width: 1160px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .brand-logo {
            display: flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
        }
        .brand-logo img {
            height: 38px;
            width: auto;
            object-fit: contain;
        }
        .brand-name {
            font-size: 1.4rem;
            font-weight: 900;
            color: var(--neon-dark);
            letter-spacing: -0.02em;
        }
        .brand-name span {
            color: var(--neon-pink);
        }
        .back-link {
            color: var(--text-secondary);
            text-decoration: none;
            font-weight: 600;
            font-size: 0.9rem;
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 16px;
            border-radius: var(--radius-sm);
            transition: all 0.2s;
            background: rgba(241, 245, 249, 0.8);
        }
        .back-link:hover {
            color: var(--neon-pink);
            background: rgba(255, 0, 84, 0.08);
        }

        /* Main Wrapper */
        .onboard-wrapper {
            max-width: 960px;
            margin: 32px auto;
            padding: 0 20px 60px;
            width: 100%;
        }

        /* Card Container */
        .onboard-card {
            background: var(--neon-card-bg);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-card), var(--shadow-glow);
            border: 1px solid rgba(255, 255, 255, 0.8);
            overflow: hidden;
        }

        .card-header-banner {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            padding: 32px 40px;
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: relative;
            overflow: hidden;
        }
        .card-header-banner::after {
            content: "";
            position: absolute;
            top: -50%;
            right: -10%;
            width: 320px;
            height: 320px;
            background: radial-gradient(circle, rgba(255, 0, 84, 0.25) 0%, transparent 70%);
            pointer-events: none;
        }
        .header-title-group h1 {
            font-size: 1.6rem;
            font-weight: 800;
            margin-bottom: 6px;
            color: #ffffff;
        }
        .header-title-group p {
            color: #94a3b8;
            font-size: 0.92rem;
        }
        .type-badge {
            background: linear-gradient(135deg, var(--neon-pink) 0%, #e0004a 100%);
            color: white;
            font-weight: 700;
            font-size: 0.82rem;
            padding: 8px 18px;
            border-radius: 30px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            box-shadow: 0 4px 12px rgba(255, 0, 84, 0.3);
        }

        /* Desktop & Mobile Persistent Stepper */
        .stepper-container {
            padding: 20px 32px;
            background: #f8fafc;
            border-bottom: 1px solid var(--neon-border);
            overflow-x: auto;
        }
        .stepper-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            min-width: 680px;
            position: relative;
        }
        .stepper-bar::before {
            content: "";
            position: absolute;
            top: 18px;
            left: 20px;
            right: 20px;
            height: 3px;
            background: #e2e8f0;
            z-index: 1;
        }
        .step-node {
            position: relative;
            z-index: 2;
            display: flex;
            flex-direction: column;
            align-items: center;
            cursor: pointer;
        }
        .step-circle {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: white;
            border: 2px solid #cbd5e1;
            color: #64748b;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 0.85rem;
            transition: all 0.3s;
        }
        .step-node.active .step-circle {
            background: var(--neon-pink);
            border-color: #ffb3c6;
            color: white;
            box-shadow: 0 0 0 4px rgba(255, 0, 84, 0.15);
        }
        .step-node.completed .step-circle {
            background: var(--neon-cyan);
            border-color: var(--neon-cyan);
            color: white;
        }
        .step-title {
            font-size: 0.75rem;
            font-weight: 700;
            color: #94a3b8;
            margin-top: 6px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
            white-space: nowrap;
        }
        .step-node.active .step-title { color: var(--neon-pink); }
        .step-node.completed .step-title { color: var(--neon-cyan); }

        /* Mobile Progress Counter Indicator */
        .mobile-step-indicator {
            display: none;
            padding: 12px 24px;
            background: #f1f5f9;
            border-bottom: 1px solid var(--neon-border);
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--text-secondary);
            text-align: center;
        }

        /* Form Body */
        .card-body {
            padding: 40px;
        }
        .form-section {
            display: none;
            animation: fadeIn 0.3s ease;
        }
        .form-section.active {
            display: block;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .section-heading {
            font-size: 1.3rem;
            font-weight: 800;
            margin-bottom: 8px;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .section-heading i {
            color: var(--neon-pink);
        }
        .section-subheading {
            font-size: 0.92rem;
            color: var(--text-secondary);
            margin-bottom: 28px;
        }

        /* Form Controls Grid */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 22px;
        }
        .form-group.full-width {
            grid-column: span 2;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .form-group label {
            font-size: 0.88rem;
            font-weight: 700;
            color: #334155;
        }
        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }
        .input-wrapper i {
            position: absolute;
            left: 16px;
            color: #94a3b8;
            font-size: 1rem;
            pointer-events: none;
        }
        .form-control {
            width: 100%;
            padding: 14px 16px 14px 44px;
            border: 1.5px solid var(--neon-border);
            border-radius: var(--radius-sm);
            font-size: 0.95rem;
            font-family: inherit;
            color: var(--text-primary);
            background: white;
            transition: all 0.2s;
        }
        .form-control:focus {
            outline: none;
            border-color: var(--neon-pink);
            box-shadow: 0 0 0 4px rgba(255, 0, 84, 0.12);
        }
        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%2394a3b8'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 14px center;
            background-size: 16px;
        }

        /* Country Selector Search Box */
        .country-select-box {
            border: 1.5px solid var(--neon-border);
            border-radius: var(--radius-sm);
            padding: 12px 16px;
            background: white;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .country-select-box:hover { border-color: var(--neon-pink); }
        .selected-flag { font-size: 1.3rem; margin-right: 10px; }

        /* Document Dropzones */
        .upload-card {
            border: 2px dashed #cbd5e1;
            border-radius: var(--radius-md);
            padding: 28px;
            text-align: center;
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.2s;
            position: relative;
        }
        .upload-card:hover {
            border-color: var(--neon-pink);
            background: rgba(255, 0, 84, 0.02);
        }
        .upload-icon {
            font-size: 2.2rem;
            color: var(--neon-cyan);
            margin-bottom: 10px;
        }
        .upload-title {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--text-primary);
        }
        .upload-sub {
            font-size: 0.8rem;
            color: var(--text-secondary);
            margin-top: 4px;
        }
        .upload-preview {
            max-height: 140px;
            width: auto;
            border-radius: var(--radius-sm);
            margin-top: 14px;
            display: none;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        /* Signature Canvas Pad */
        .sig-pad-wrapper {
            border: 1.5px solid var(--neon-border);
            border-radius: var(--radius-sm);
            background: white;
            position: relative;
            overflow: hidden;
        }
        canvas#sigCanvas {
            width: 100%;
            height: 160px;
            cursor: crosshair;
            display: block;
        }
        .sig-actions {
            position: absolute;
            bottom: 10px;
            right: 12px;
            display: flex;
            gap: 8px;
        }

        /* Policy Terms Box */
        .terms-box {
            background: #f8fafc;
            border: 1px solid var(--neon-border);
            border-radius: var(--radius-md);
            padding: 24px;
            max-height: 280px;
            overflow-y: auto;
            font-size: 0.88rem;
            color: #475569;
            line-height: 1.6;
            margin-bottom: 20px;
        }
        .terms-box h4 {
            font-size: 1rem;
            color: var(--text-primary);
            margin: 16px 0 6px;
        }
        .terms-box h4:first-child { margin-top: 0; }

        /* Card Action Buttons */
        .card-footer {
            padding: 24px 40px;
            background: #f8fafc;
            border-top: 1px solid var(--neon-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 14px 28px;
            font-size: 0.95rem;
            font-weight: 700;
            border-radius: var(--radius-sm);
            cursor: pointer;
            border: none;
            transition: all 0.2s;
            text-decoration: none;
        }
        .btn-primary {
            background: linear-gradient(135deg, var(--neon-pink) 0%, #e0004a 100%);
            color: white;
            box-shadow: 0 4px 14px rgba(255, 0, 84, 0.3);
        }
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px rgba(255, 0, 84, 0.4);
        }
        .btn-secondary {
            background: #e2e8f0;
            color: #475569;
        }
        .btn-secondary:hover {
            background: #cbd5e1;
            color: #1e293b;
        }
        .btn-outline {
            background: transparent;
            border: 1.5px solid var(--neon-border);
            color: var(--text-primary);
        }
        .btn-outline:hover {
            border-color: var(--neon-pink);
            color: var(--neon-pink);
        }

        /* Review Summary Cards */
        .review-card {
            background: white;
            border: 1px solid var(--neon-border);
            border-radius: var(--radius-md);
            padding: 20px;
            margin-bottom: 16px;
        }
        .review-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #f1f5f9;
            padding-bottom: 12px;
            margin-bottom: 14px;
        }
        .review-header h4 { font-size: 1rem; font-weight: 800; }
        .edit-link {
            color: var(--neon-pink);
            font-size: 0.85rem;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
        }

        /* Country Search Modal */
        .modal-backdrop {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(6px);
            z-index: 2000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-backdrop.active { display: flex; }
        .country-modal {
            background: white;
            border-radius: var(--radius-lg);
            width: 100%;
            max-width: 520px;
            max-height: 80vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        }
        .modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--neon-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .modal-body {
            padding: 16px 24px;
            overflow-y: auto;
        }
        .country-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 12px 16px;
            border-radius: var(--radius-sm);
            cursor: pointer;
            transition: all 0.15s;
        }
        .country-item:hover { background: #f1f5f9; }

        @media (max-width: 768px) {
            .card-header-banner { padding: 24px; flex-direction: column; align-items: flex-start; gap: 12px; }
            .card-body { padding: 24px 20px; }
            .card-footer { padding: 20px; }
            .form-grid { grid-template-columns: 1fr; }
            .form-group.full-width { grid-column: span 1; }
            .stepper-container { display: none; }
            .mobile-step-indicator { display: block; }
        }
    </style>
</head>
<body>

    <!-- Header Navigation -->
    <header class="neon-header">
        <div class="header-content">
            <a href="index.php" class="brand-logo">
                <img src="logo.webp" alt="Neon Bank Logo">
                <span class="brand-name">NEON <span>BANK</span></span>
            </a>
            <a href="choose-account.php" class="back-link">
                <i class="fa-solid fa-arrow-left"></i> Account Types
            </a>
        </div>
    </header>

    <!-- Main Content Container -->
    <div class="onboard-wrapper">
        <div class="onboard-card">
            
            <!-- Banner -->
            <div class="card-header-banner">
                <div class="header-title-group">
                    <h1>International Banking Onboarding</h1>
                    <p>Swiss & Global Digital Banking Application</p>
                </div>
                <div class="type-badge"><?= htmlspecialchars($accountTitle) ?></div>
            </div>

            <!-- Desktop Horizontal Stepper Bar (10 Steps) -->
            <div class="stepper-container">
                <div class="stepper-bar">
                    <div class="step-node active" data-step="0">
                        <div class="step-circle">1</div>
                        <div class="step-title">Welcome</div>
                    </div>
                    <div class="step-node" data-step="1">
                        <div class="step-circle">2</div>
                        <div class="step-title">Nationality</div>
                    </div>
                    <div class="step-node" data-step="2">
                        <div class="step-circle">3</div>
                        <div class="step-title">Terms</div>
                    </div>
                    <div class="step-node" data-step="3">
                        <div class="step-circle">4</div>
                        <div class="step-title">Personal</div>
                    </div>
                    <div class="step-node" data-step="4">
                        <div class="step-circle">5</div>
                        <div class="step-title">Contact</div>
                    </div>
                    <div class="step-node" data-step="5">
                        <div class="step-circle">6</div>
                        <div class="step-title">Financial</div>
                    </div>
                    <div class="step-node" data-step="6">
                        <div class="step-circle">7</div>
                        <div class="step-title">Tax & ID</div>
                    </div>
                    <div class="step-node" data-step="7">
                        <div class="step-circle">8</div>
                        <div class="step-title">Documents</div>
                    </div>
                    <div class="step-node" data-step="8">
                        <div class="step-circle">9</div>
                        <div class="step-title">Nominee</div>
                    </div>
                    <div class="step-node" data-step="9">
                        <div class="step-circle">10</div>
                        <div class="step-title">Review</div>
                    </div>
                </div>
            </div>

            <!-- Mobile Compact Step Indicator -->
            <div class="mobile-step-indicator" id="mobileStepLabel">
                Step 1 of 10 • Welcome to Neon Bank
            </div>

            <!-- Form Body -->
            <div class="card-body">
                <form id="onboardingForm" onsubmit="return false;">
                    <input type="hidden" name="account_type" value="<?= htmlspecialchars($type) ?>">

                    <!-- STEP 0: LANDING WELCOME PAGE -->
                    <div class="form-section active" data-section="0">
                        <div class="section-heading">
                            <i class="fa-solid fa-earth-americas"></i> Open Your Neon Bank Account
                        </div>
                        <p class="section-subheading">International banking designed around your global lifestyle. Secure, transparent, and multi-currency enabled.</p>
                        
                        <div style="background: white; border: 1.5px solid var(--neon-border); border-radius: var(--radius-md); padding: 28px; margin-bottom: 24px;">
                            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; text-align: center;">
                                <div>
                                    <i class="fa-solid fa-shield-halved" style="font-size: 2rem; color: var(--neon-pink); margin-bottom: 10px;"></i>
                                    <h4 style="font-size: 0.95rem; font-weight: 800; margin-bottom: 4px;">Secure Onboarding</h4>
                                    <p style="font-size: 0.8rem; color: var(--text-secondary);">Bank-grade data encryption and secure file validation</p>
                                </div>
                                <div>
                                    <i class="fa-solid fa-globe" style="font-size: 2rem; color: var(--neon-cyan); margin-bottom: 10px;"></i>
                                    <h4 style="font-size: 0.95rem; font-weight: 800; margin-bottom: 4px;">Multi-Country Support</h4>
                                    <p style="font-size: 0.8rem; color: var(--text-secondary);">Customized KYC onboarding rules tailored to your jurisdiction</p>
                                </div>
                                <div>
                                    <i class="fa-solid fa-id-card" style="font-size: 2rem; color: var(--neon-pink); margin-bottom: 10px;"></i>
                                    <h4 style="font-size: 0.95rem; font-weight: 800; margin-bottom: 4px;">Digital Verification</h4>
                                    <p style="font-size: 0.8rem; color: var(--text-secondary);">Fast digital document upload & verification process</p>
                                </div>
                            </div>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-secondary); line-height: 1.5; background: rgba(255, 0, 84, 0.04); padding: 16px 20px; border-radius: var(--radius-sm); border-left: 4px solid var(--neon-pink);">
                            <i class="fa-solid fa-info-circle" style="color: var(--neon-pink); margin-right: 6px;"></i>
                            <strong>Note:</strong> Exact onboarding requirements and documentation depend on your nationality, country of tax residence, selected account product, and applicable regulatory frameworks.
                        </p>
                    </div>

                    <!-- STEP 1: NATIONALITY FIRST -->
                    <div class="form-section" data-section="1">
                        <div class="section-heading">
                            <i class="fa-solid fa-passport"></i> What is your nationality?
                        </div>
                        <p class="section-subheading">Select your primary citizenship to customize your country-specific KYC compliance requirements.</p>
                        
                        <div class="form-grid">
                            <div class="form-group full-width">
                                <label>Primary Citizenship / Passport Country *</label>
                                <div class="country-select-box" onclick="openCountryModal('nationality')">
                                    <div style="display: flex; align-items: center;">
                                        <span class="selected-flag" id="nationalityFlag">🇨🇭</span>
                                        <span id="nationalityName" style="font-weight: 700;">Switzerland</span>
                                    </div>
                                    <i class="fa-solid fa-chevron-down" style="color: var(--text-secondary);"></i>
                                </div>
                                <input type="hidden" name="nationality" id="inputNationality" value="Switzerland">
                            </div>

                            <div class="form-group full-width">
                                <label>Country of Current Residence *</label>
                                <div class="country-select-box" onclick="openCountryModal('residency')">
                                    <div style="display: flex; align-items: center;">
                                        <span class="selected-flag" id="residencyFlag">🇨🇭</span>
                                        <span id="residencyName" style="font-weight: 700;">Switzerland</span>
                                    </div>
                                    <i class="fa-solid fa-chevron-down" style="color: var(--text-secondary);"></i>
                                </div>
                                <input type="hidden" name="residency_country" id="inputResidency" value="Switzerland">
                            </div>
                        </div>

                        <!-- Dynamic Jurisdiction Box -->
                        <div id="jurisdictionNotice" style="margin-top: 24px; padding: 18px 20px; background: white; border: 1.5px solid var(--neon-border); border-radius: var(--radius-md); display: flex; align-items: center; gap: 14px;">
                            <i class="fa-solid fa-scale-balanced" style="font-size: 1.5rem; color: var(--neon-pink);"></i>
                            <div>
                                <h4 style="font-size: 0.95rem; font-weight: 800;" id="jurisdictionTitle">Switzerland / International Onboarding Engine Active</h4>
                                <p style="font-size: 0.82rem; color: var(--text-secondary);" id="jurisdictionDesc">Standard Swiss digital verification & FATCA / CRS tax compliance rules applied.</p>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 2: TERMS & POLICY CONSENT -->
                    <div class="form-section" data-section="2">
                        <div class="section-heading">
                            <i class="fa-solid fa-file-contract"></i> Terms, Privacy & Regulatory Policies
                        </div>
                        <p class="section-subheading">Please review and accept our international banking service agreements before continuing.</p>

                        <div class="terms-box">
                            <h4>1. Account Opening & Banking Services Agreement</h4>
                            <p>By proceeding with this account application, you confirm your request to open an international digital multi-currency account governed by standard international banking procedures. You agree that all transactions and financial operations are subject to account verification and security authentication.</p>

                            <h4>2. Privacy Policy & Identity Verification Notice</h4>
                            <p>Neon Bank collects personal details, identity credentials, contact identifiers, financial parameters, and biometric signature files solely for regulatory identity verification, Anti-Money Laundering (AML), and Customer Due Diligence (CDD) purposes.</p>

                            <h4>3. Electronic Communication & Disclosure Consent</h4>
                            <p>You consent to receive all account statements, transaction notifications, regulatory disclosures, legal updates, and electronic communications digitally via email or verified push notification channels.</p>

                            <h4>4. International Tax Declarations (FATCA / CRS)</h4>
                            <p>You warrant that all tax residency declarations and Identification Numbers (TINs) submitted during onboarding are truthful, complete, and accurate.</p>
                        </div>

                        <div style="background: white; border: 1.5px solid var(--neon-border); border-radius: var(--radius-sm); padding: 16px 20px;">
                            <label style="display: flex; align-items: flex-start; gap: 12px; cursor: pointer; font-size: 0.9rem; font-weight: 700; color: var(--text-primary);">
                                <input type="checkbox" id="consentCheckbox" style="margin-top: 3px; width: 18px; height: 18px; accent-color: var(--neon-pink);">
                                <span>I have read, understood, and actively agree to the Terms of Service, Privacy Policy, and Regulatory Verification Notices.</span>
                            </label>
                        </div>
                    </div>

                    <!-- STEP 3: PERSONAL INFORMATION -->
                    <div class="form-section" data-section="3">
                        <div class="section-heading">
                            <i class="fa-solid fa-user-gear"></i> Personal Details
                        </div>
                        <p class="section-subheading">Enter your official name as shown on your legal identity documents or passport.</p>

                        <div class="form-grid">
                            <div class="form-group full-width">
                                <label>Full Legal Name (First, Middle, Last) *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-user"></i>
                                    <input type="text" name="full_name" class="form-control" placeholder="e.g. Alexander Weber" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Date of Birth *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-calendar"></i>
                                    <input type="date" name="dob" class="form-control" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Gender *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-venus-mars"></i>
                                    <select name="gender" class="form-control" required>
                                        <option value="Male">Male</option>
                                        <option value="Female">Female</option>
                                        <option value="Other">Other / Prefer not to say</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 4: CONTACT & ADDRESS -->
                    <div class="form-section" data-section="4">
                        <div class="section-heading">
                            <i class="fa-solid fa-address-book"></i> Contact & Residential Address
                        </div>
                        <p class="section-subheading">Provide your verified contact details and principal residential location.</p>

                        <div class="form-grid">
                            <div class="form-group">
                                <label>Mobile Phone Number (with Country Code) *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-mobile-screen"></i>
                                    <input type="text" name="phone" class="form-control" placeholder="+41 79 123 45 67 or +91 9876543210" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Email Address *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-envelope"></i>
                                    <input type="email" name="email" class="form-control" placeholder="name@example.com" required>
                                </div>
                            </div>

                            <div class="form-group full-width">
                                <label>Residential Address Line *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-location-dot"></i>
                                    <input type="text" name="address" class="form-control" placeholder="Street address, building / apartment number, city, postal code" required>
                                </div>
                            </div>

                            <div class="form-group full-width">
                                <label>Account Password (for mobile app & online banking sign in) *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-key"></i>
                                    <input type="password" name="password" class="form-control" placeholder="Minimum 6 characters" required>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 5: EMPLOYMENT & FINANCIAL PROFILE -->
                    <div class="form-section" data-section="5">
                        <div class="section-heading">
                            <i class="fa-solid fa-briefcase"></i> Employment & Financial Profile
                        </div>
                        <p class="section-subheading">Helps us customize transaction limits and international banking features.</p>

                        <div class="form-grid">
                            <div class="form-group">
                                <label>Employment Status *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-user-tie"></i>
                                    <select name="employment_status" class="form-control">
                                        <option value="Employed">Employed / Salaried</option>
                                        <option value="Self-Employed">Self-Employed / Business Owner</option>
                                        <option value="Retired">Retired</option>
                                        <option value="Student">Student</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Employer / Business Name</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-building"></i>
                                    <input type="text" name="employer_name" class="form-control" placeholder="e.g. UBS AG or Self">
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Annual Income Range *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-coins"></i>
                                    <select name="income_range" class="form-control">
                                        <option value="Under CHF 50,000">Under CHF 50,000 / $55,000</option>
                                        <option value="CHF 50,000 - 100,000">CHF 50,000 – 100,000</option>
                                        <option value="CHF 100,000 - 250,000">CHF 100,000 – 250,000</option>
                                        <option value="Above CHF 250,000">Above CHF 250,000+</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Primary Source of Funds *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-wallet"></i>
                                    <select name="source_of_funds" class="form-control">
                                        <option value="Salary / Employment Income">Salary / Employment Income</option>
                                        <option value="Business Profits">Business Profits</option>
                                        <option value="Investment / Capital Gains">Investment / Capital Gains</option>
                                        <option value="Inheritance / Savings">Inheritance / Savings</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group full-width">
                                <label>Primary Account Purpose *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-bullseye"></i>
                                    <select name="account_purpose" class="form-control">
                                        <option value="Personal Everyday Banking">Personal Everyday Banking</option>
                                        <option value="International Money Transfer & Forex">International Money Transfer & Forex</option>
                                        <option value="Savings & High-Yield Interest">Savings & High-Yield Interest</option>
                                        <option value="Global Stock & ETF Investments">Global Stock & ETF Investments</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 6: TAX RESIDENCY & JURISDICTION ID -->
                    <div class="form-section" data-section="6">
                        <div class="section-heading">
                            <i class="fa-solid fa-landmark"></i> Tax Residency & Identity Document No.
                        </div>
                        <p class="section-subheading" id="taxDesc">Specify your tax jurisdiction and primary identity document number.</p>

                        <div class="form-grid">
                            <div class="form-group">
                                <label>Country of Tax Residence *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-flag"></i>
                                    <input type="text" name="tax_residency" id="inputTaxResidency" class="form-control" value="Switzerland" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label id="labelTaxId">Tax ID / Social Security / AHV Number *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-hashtag"></i>
                                    <input type="text" name="tax_id_no" id="inputTaxIdNo" class="form-control" placeholder="e.g. 756.1234.5678.90 or PAN / SSN" required>
                                </div>
                            </div>

                            <div class="form-group full-width">
                                <label id="labelNationalId">Primary Identity / Passport Number *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-id-card"></i>
                                    <input type="text" name="national_id" id="inputNationalId" class="form-control" placeholder="e.g. Passport number or National ID" required>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 7: SECURE DOCUMENT COLLECTION -->
                    <div class="form-section" data-section="7">
                        <div class="section-heading">
                            <i class="fa-solid fa-cloud-arrow-up"></i> Document Collection & Verification
                        </div>
                        <p class="section-subheading" id="docSubheading">Upload clear photo copies of your identity document and proof of address.</p>

                        <div class="form-grid">
                            <!-- Document 1: Front / Identity -->
                            <div class="form-group">
                                <label id="labelDocPan">Identity Document (Passport / Front Copy) *</label>
                                <div class="upload-card" onclick="document.getElementById('filePan').click()">
                                    <div class="upload-icon"><i class="fa-solid fa-file-image"></i></div>
                                    <div class="upload-title">Click to Upload Document</div>
                                    <div class="upload-sub">JPG, PNG or PDF (Max 5MB)</div>
                                    <img id="previewPan" class="upload-preview" alt="Preview">
                                </div>
                                <input type="file" id="filePan" accept="image/*,.pdf" style="display:none;" onchange="handleFileUpload(this, 'previewPan', 'doc_pan_data')">
                                <input type="hidden" name="doc_pan_data" id="doc_pan_data">
                            </div>

                            <!-- Document 2: Back / Address -->
                            <div class="form-group">
                                <label id="labelDocAadhaar">Address Proof / Second Identity Copy *</label>
                                <div class="upload-card" onclick="document.getElementById('fileAadhaar').click()">
                                    <div class="upload-icon"><i class="fa-solid fa-file-invoice"></i></div>
                                    <div class="upload-title">Click to Upload Document</div>
                                    <div class="upload-sub">Utility bill, bank statement or ID back</div>
                                    <img id="previewAadhaar" class="upload-preview" alt="Preview">
                                </div>
                                <input type="file" id="fileAadhaar" accept="image/*,.pdf" style="display:none;" onchange="handleFileUpload(this, 'previewAadhaar', 'doc_aadhaar_data')">
                                <input type="hidden" name="doc_aadhaar_data" id="doc_aadhaar_data">
                            </div>

                            <!-- Portrait / Selfie Capture -->
                            <div class="form-group">
                                <label>Live Portrait / Selfie Photo *</label>
                                <div class="upload-card" onclick="document.getElementById('filePortrait').click()">
                                    <div class="upload-icon"><i class="fa-solid fa-camera"></i></div>
                                    <div class="upload-title">Take / Upload Face Photo</div>
                                    <div class="upload-sub">Ensure good lighting</div>
                                    <img id="previewPortrait" class="upload-preview" alt="Preview">
                                </div>
                                <input type="file" id="filePortrait" accept="image/*" style="display:none;" onchange="handleFileUpload(this, 'previewPortrait', 'portrait_data')">
                                <input type="hidden" name="portrait_data" id="portrait_data">
                            </div>

                            <!-- Authorized Digital Signature -->
                            <div class="form-group">
                                <label>Authorized Signature *</label>
                                <div class="sig-pad-wrapper">
                                    <canvas id="sigCanvas"></canvas>
                                    <div class="sig-actions">
                                        <button type="button" class="btn btn-secondary" style="padding: 4px 10px; font-size: 0.75rem;" onclick="clearSignature()">Clear</button>
                                    </div>
                                </div>
                                <input type="hidden" name="signature_data" id="signature_data">
                            </div>
                        </div>
                    </div>

                    <!-- STEP 8: OPTIONAL NOMINEE -->
                    <div class="form-section" data-section="8">
                        <div class="section-heading">
                            <i class="fa-solid fa-users"></i> Nominee / Beneficiary Details
                        </div>
                        <p class="section-subheading">Designate a legal nominee for your account (Optional - can also be added later in settings).</p>

                        <div class="form-grid">
                            <div class="form-group">
                                <label>Nominee Full Name</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-user"></i>
                                    <input type="text" name="nominee_name" class="form-control" placeholder="e.g. Sophia Weber">
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Relationship</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-heart"></i>
                                    <input type="text" name="nominee_relation" class="form-control" placeholder="e.g. Spouse / Son / Parent">
                                </div>
                            </div>

                            <div class="form-group full-width">
                                <label>Nominee Contact Phone Number</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-phone"></i>
                                    <input type="text" name="nominee_phone" class="form-control" placeholder="+41 79 123 45 67">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 9: REVIEW & SUBMIT APPLICATION -->
                    <div class="form-section" data-section="9">
                        <div class="section-heading">
                            <i class="fa-solid fa-clipboard-check"></i> Review & Submit Application
                        </div>
                        <p class="section-subheading">Double check your entered information before submitting for instant digital review.</p>

                        <div class="review-card">
                            <div class="review-header">
                                <h4>1. Nationality & Jurisdiction</h4>
                                <span class="edit-link" onclick="goToStep(1)">Edit</span>
                            </div>
                            <p style="font-size: 0.9rem;"><strong>Nationality:</strong> <span id="revNationality">Switzerland</span></p>
                            <p style="font-size: 0.9rem;"><strong>Country of Residence:</strong> <span id="revResidency">Switzerland</span></p>
                        </div>

                        <div class="review-card">
                            <div class="review-header">
                                <h4>2. Personal & Contact Details</h4>
                                <span class="edit-link" onclick="goToStep(3)">Edit</span>
                            </div>
                            <p style="font-size: 0.9rem;"><strong>Full Name:</strong> <span id="revFullName">-</span></p>
                            <p style="font-size: 0.9rem;"><strong>Email:</strong> <span id="revEmail">-</span></p>
                            <p style="font-size: 0.9rem;"><strong>Phone:</strong> <span id="revPhone">-</span></p>
                            <p style="font-size: 0.9rem;"><strong>Address:</strong> <span id="revAddress">-</span></p>
                        </div>

                        <div class="review-card">
                            <div class="review-header">
                                <h4>3. Documents & Compliance</h4>
                                <span class="edit-link" onclick="goToStep(7)">Edit</span>
                            </div>
                            <p style="font-size: 0.9rem;"><strong>Identity ID Number:</strong> <span id="revTaxId">-</span></p>
                            <p style="font-size: 0.9rem;"><strong>Documents Attached:</strong> <span style="color: var(--neon-cyan); font-weight: 700;">Identity Copy, Proof of Address, Portrait & Signature ✓</span></p>
                        </div>

                        <div style="background: rgba(255, 0, 84, 0.04); border: 1.5px solid var(--neon-pink); border-radius: var(--radius-md); padding: 20px; margin-top: 24px;">
                            <label style="display: flex; align-items: flex-start; gap: 12px; cursor: pointer; font-size: 0.9rem; font-weight: 700; color: var(--text-primary);">
                                <input type="checkbox" id="finalDeclarationCheckbox" style="margin-top: 3px; width: 18px; height: 18px; accent-color: var(--neon-pink);">
                                <span>Final Declaration: I solemnly declare that the information supplied above is complete, accurate, and correct.</span>
                            </label>
                        </div>
                    </div>

                    <!-- SUCCESS STATE SCREEN (STEP 10) -->
                    <div class="form-section" data-section="10">
                        <div style="text-align: center; padding: 40px 20px;">
                            <div style="width: 80px; height: 80px; background: rgba(31, 169, 178, 0.12); color: var(--neon-cyan); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2.5rem; margin: 0 auto 20px;">
                                <i class="fa-solid fa-check"></i>
                            </div>
                            <h2 style="font-size: 1.8rem; font-weight: 900; margin-bottom: 8px;">Application Submitted Successfully!</h2>
                            <p style="color: var(--text-secondary); font-size: 1rem; max-width: 500px; margin: 0 auto 24px;">Your digital account application has been received and logged in our system under Review Status.</p>
                            
                            <div style="background: #f8fafc; border: 1.5px solid var(--neon-border); border-radius: var(--radius-md); padding: 24px; max-width: 420px; margin: 0 auto 32px;">
                                <div style="font-size: 0.82rem; color: var(--text-secondary); text-transform: uppercase; font-weight: 700; letter-spacing: 0.05em;">Your Application Reference ID</div>
                                <div id="submittedAppId" style="font-size: 1.8rem; font-weight: 900; color: var(--neon-pink); letter-spacing: 2px; margin: 8px 0;">FR-XXXXXX</div>
                                <div style="font-size: 0.85rem; color: var(--neon-cyan); font-weight: 700;"><i class="fa-solid fa-clock"></i> Status: Under Review</div>
                            </div>

                            <div style="display: flex; gap: 16px; justify-content: center;">
                                <a href="index.php" class="btn btn-outline">Return to Homepage</a>
                                <a href="choose-account.php" class="btn btn-primary">Open Another Account</a>
                            </div>
                        </div>
                    </div>

                </form>
            </div>

            <!-- Card Footer Controls -->
            <div class="card-footer" id="cardFooter">
                <button type="button" class="btn btn-secondary" id="btnPrev" onclick="navigateStep(-1)" style="display:none;">
                    <i class="fa-solid fa-arrow-left"></i> Back
                </button>
                <div></div>
                <button type="button" class="btn btn-primary" id="btnNext" onclick="navigateStep(1)">
                    Start Application <i class="fa-solid fa-arrow-right"></i>
                </button>
            </div>

        </div>
    </div>

    <!-- Country Search Modal -->
    <div class="modal-backdrop" id="countryModalBackdrop">
        <div class="country-modal">
            <div class="modal-header">
                <h3 style="font-size: 1.1rem; font-weight: 800;">Select Country</h3>
                <button type="button" onclick="closeCountryModal()" style="background:none; border:none; font-size: 1.2rem; cursor:pointer;"><i class="fa-solid fa-xmark"></i></button>
            </div>
            <div style="padding: 12px 24px; border-bottom: 1px solid var(--neon-border);">
                <input type="text" id="countrySearchInput" class="form-control" placeholder="Search country or code..." style="padding-left: 16px;" onkeyup="filterCountries()">
            </div>
            <div class="modal-body" id="countryList">
                <!-- Country Options Populated via JS -->
            </div>
        </div>
    </div>

    <script>
        const countries = [
            { code: "CH", name: "Switzerland", flag: "🇨🇭", kyc: "Swiss Digital / FATCA / CRS" },
            { code: "IN", name: "India", flag: "🇮🇳", kyc: "PAN & Aadhaar / NRI Rules" },
            { code: "AE", name: "United Arab Emirates", flag: "🇦🇪", kyc: "Emirates ID & Passport" },
            { code: "SG", name: "Singapore", flag: "🇸🇬", kyc: "Singpass / Passport NRIC" },
            { code: "US", name: "United States", flag: "🇺🇸", kyc: "SSN / ITIN / FATCA W-9" },
            { code: "GB", name: "United Kingdom", flag: "🇬🇧", kyc: "UK Passport / National Insurance" },
            { code: "CA", name: "Canada", flag: "🇨🇦", kyc: "SIN / Canadian Passport" },
            { code: "AU", name: "Australia", flag: "🇦🇺", kyc: "TFN / Australian ID" },
            { code: "DE", name: "Germany", flag: "🇩🇪", kyc: "EU ID / Steuer-ID" },
            { code: "FR", name: "France", flag: "🇫🇷", kyc: "EU Passport / Tax ID" }
        ];

        let activeStep = 0;
        let activeCountryTarget = 'nationality';
        let sigCanvas, sigCtx, isDrawing = false;

        document.addEventListener("DOMContentLoaded", () => {
            initSignaturePad();
            populateCountries();
        });

        function navigateStep(direction) {
            if (direction === 1) {
                if (!validateCurrentStep()) return;
            }

            activeStep += direction;
            if (activeStep < 0) activeStep = 0;
            if (activeStep > 9) activeStep = 9;

            updateStepUI();
        }

        function goToStep(step) {
            activeStep = step;
            updateStepUI();
        }

        function updateStepUI() {
            const sections = document.querySelectorAll(".form-section");
            sections.forEach((sec, idx) => {
                sec.classList.toggle("active", idx === activeStep);
            });

            // Stepper nodes update
            const nodes = document.querySelectorAll(".step-node");
            nodes.forEach((node, idx) => {
                node.classList.remove("active", "completed");
                if (idx === activeStep) node.classList.add("active");
                if (idx < activeStep) node.classList.add("completed");
            });

            // Footer controls
            const btnPrev = document.getElementById("btnPrev");
            const btnNext = document.getElementById("btnNext");
            const footer = document.getElementById("cardFooter");

            if (activeStep === 10) {
                footer.style.display = "none";
                return;
            } else {
                footer.style.display = "flex";
            }

            btnPrev.style.display = activeStep === 0 ? "none" : "inline-flex";

            if (activeStep === 0) {
                btnNext.innerHTML = 'Start Application <i class="fa-solid fa-arrow-right"></i>';
            } else if (activeStep === 9) {
                btnNext.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Submit Application';
            } else {
                btnNext.innerHTML = 'Continue <i class="fa-solid fa-arrow-right"></i>';
            }

            // Update mobile header
            const stepTitles = ["Welcome", "Nationality", "Terms", "Personal", "Contact", "Financial", "Tax & ID", "Documents", "Nominee", "Review"];
            document.getElementById("mobileStepLabel").innerText = `Step ${activeStep + 1} of 10 • ${stepTitles[activeStep] || ''}`;

            if (activeStep === 9) {
                updateReviewData();
            }
        }

        function validateCurrentStep() {
            if (activeStep === 2) {
                const consent = document.getElementById("consentCheckbox").checked;
                if (!consent) {
                    alert("Please accept the Terms & Policies before proceeding.");
                    return false;
                }
            }

            if (activeStep === 9) {
                const finalDec = document.getElementById("finalDeclarationCheckbox").checked;
                if (!finalDec) {
                    alert("Please check the final declaration box before submitting.");
                    return false;
                }
                submitForm();
                return false;
            }

            return true;
        }

        function updateReviewData() {
            const form = document.getElementById("onboardingForm");
            document.getElementById("revNationality").innerText = document.getElementById("nationalityName").innerText;
            document.getElementById("revResidency").innerText = document.getElementById("residencyName").innerText;
            document.getElementById("revFullName").innerText = form.full_name.value || '-';
            document.getElementById("revEmail").innerText = form.email.value || '-';
            document.getElementById("revPhone").innerText = form.phone.value || '-';
            document.getElementById("revAddress").innerText = form.address.value || '-';
            document.getElementById("revTaxId").innerText = form.national_id.value || form.tax_id_no.value || '-';
        }

        // Country Search Modal Handling
        function openCountryModal(target) {
            activeCountryTarget = target;
            document.getElementById("countryModalBackdrop").classList.add("active");
        }
        function closeCountryModal() {
            document.getElementById("countryModalBackdrop").classList.remove("active");
        }
        function populateCountries() {
            const list = document.getElementById("countryList");
            list.innerHTML = countries.map(c => `
                <div class="country-item" onclick="selectCountry('${c.name}', '${c.flag}', '${c.kyc}')">
                    <span style="font-size: 1.5rem;">${c.flag}</span>
                    <div style="flex:1;">
                        <div style="font-weight: 700; font-size: 0.95rem;">${c.name}</div>
                        <div style="font-size: 0.78rem; color: var(--text-secondary);">${c.kyc}</div>
                    </div>
                </div>
            `).join('');
        }
        function selectCountry(name, flag, kyc) {
            if (activeCountryTarget === 'nationality') {
                document.getElementById("nationalityName").innerText = name;
                document.getElementById("nationalityFlag").innerText = flag;
                document.getElementById("inputNationality").value = name;
            } else {
                document.getElementById("residencyName").innerText = name;
                document.getElementById("residencyFlag").innerText = flag;
                document.getElementById("inputResidency").value = name;
            }

            // Update Dynamic KYC Labels
            if (name === "India") {
                document.getElementById("jurisdictionTitle").innerText = "India Onboarding Rules Active";
                document.getElementById("jurisdictionDesc").innerText = "PAN & Aadhaar mandatory KYC verification rules applied.";
                document.getElementById("labelTaxId").innerText = "PAN Card Number *";
                document.getElementById("inputTaxIdNo").placeholder = "e.g. ABCDE1234F";
                document.getElementById("labelNationalId").innerText = "Aadhaar Card Number *";
                document.getElementById("inputNationalId").placeholder = "12-digit Aadhaar Number";
                document.getElementById("labelDocPan").innerText = "PAN Card Image Copy *";
                document.getElementById("labelDocAadhaar").innerText = "Aadhaar Card Image Copy *";
            } else {
                document.getElementById("jurisdictionTitle").innerText = `${name} / International Onboarding Engine Active`;
                document.getElementById("jurisdictionDesc").innerText = "Standard Passport / National ID & Tax Identification compliance rules applied.";
                document.getElementById("labelTaxId").innerText = "Tax ID / Social Security / AHV Number *";
                document.getElementById("inputTaxIdNo").placeholder = "Tax Identification Number";
                document.getElementById("labelNationalId").innerText = "Passport / National Identity Card Number *";
                document.getElementById("inputNationalId").placeholder = "Passport or Identity Card No.";
                document.getElementById("labelDocPan").innerText = "Passport / Identity Card Front *";
                document.getElementById("labelDocAadhaar").innerText = "Proof of Address / Document Back *";
            }

            closeCountryModal();
        }

        // File Base64 Upload Handling
        function handleFileUpload(input, previewId, hiddenInputId) {
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById(hiddenInputId).value = e.target.result;
                    const prev = document.getElementById(previewId);
                    prev.src = e.target.result;
                    prev.style.display = "block";
                };
                reader.readAsDataURL(input.files[0]);
            }
        }

        // Signature Canvas
        function initSignaturePad() {
            sigCanvas = document.getElementById("sigCanvas");
            if (!sigCanvas) return;
            sigCanvas.width = sigCanvas.offsetWidth;
            sigCanvas.height = sigCanvas.offsetHeight;
            sigCtx = sigCanvas.getContext("2d");
            sigCtx.strokeStyle = "#0f172a";
            sigCtx.lineWidth = 2.5;
            sigCtx.lineCap = "round";

            const startDraw = (e) => { isDrawing = true; sigCtx.beginPath(); draw(e); };
            const stopDraw = () => { isDrawing = false; saveSignature(); };
            const draw = (e) => {
                if (!isDrawing) return;
                const rect = sigCanvas.getBoundingClientRect();
                const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
                const y = (e.touches ? e.touches[0].clientY : e.clientY) - rect.top;
                sigCtx.lineTo(x, y);
                sigCtx.stroke();
            };

            sigCanvas.addEventListener("mousedown", startDraw);
            sigCanvas.addEventListener("mouseup", stopDraw);
            sigCanvas.addEventListener("mousemove", draw);
            sigCanvas.addEventListener("touchstart", startDraw);
            sigCanvas.addEventListener("touchend", stopDraw);
            sigCanvas.addEventListener("touchmove", draw);
        }

        function clearSignature() {
            if (sigCtx && sigCanvas) {
                sigCtx.clearRect(0, 0, sigCanvas.width, sigCanvas.height);
                document.getElementById("signature_data").value = "";
            }
        }

        function saveSignature() {
            if (sigCanvas) {
                document.getElementById("signature_data").value = sigCanvas.toDataURL("image/png");
            }
        }

        // Submit Form via AJAX
        async function submitForm() {
            const btnNext = document.getElementById("btnNext");
            btnNext.disabled = true;
            btnNext.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Submitting Application...';

            const form = document.getElementById("onboardingForm");
            const formData = new FormData(form);

            // Populate fallback fields for backward database compatibility
            if (!formData.get('aadhaar_number')) {
                formData.set('aadhaar_number', formData.get('national_id') || 'NA');
            }

            try {
                const response = await fetch('api/register.php', {
                    method: 'POST',
                    body: formData
                });
                const res = await response.json();

                if (res.success) {
                    document.getElementById("submittedAppId").innerText = res.app_id;
                    activeStep = 10;
                    updateStepUI();
                } else {
                    alert(res.message || "Failed to submit application. Please try again.");
                    btnNext.disabled = false;
                    btnNext.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Submit Application';
                }
            } catch (err) {
                alert("An error occurred during submission: " + err.message);
                btnNext.disabled = false;
                btnNext.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Submit Application';
            }
        }
    </script>
</body>
</html>
