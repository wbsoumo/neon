<?php
/**
 * Neon Finance Onboarding - Open Account Page
 * Premium, state-of-the-art multi-step onboarding application
 */

require_once "api/db_helper.php";

$ip = get_client_ip();
if (is_rate_limited($ip, 5, 10)) {
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
    "CURRENT" => "Everyday Current Account",
    "SAVINGS" => "High-Yield Savings Account",
    "JOINT" => "Joint Account for Duos",
    "INVEST" => "Stocks & ETFs Investment Account",
    "VEHICLE" => "Vehicle Financing Account",
    "HOME" => "Home & Property Account"
];

$accountTitle = isset($accountTitles[$type]) ? $accountTitles[$type] : "Neon Digital Account";
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Open <?= htmlspecialchars($accountTitle) ?> - Neon Finance</title>
    
    <!-- Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="icon" type="image/png" href="favicon.png">

    <style>
        :root {
            --neon-pink: #ff0054;
            --neon-pink-hover: #e0004a;
            --neon-cyan: #1fa9b2;
            --neon-teal: #179096;
            --neon-dark: #0f172a;
            --neon-card-bg: rgba(255, 255, 255, 0.95);
            --neon-border: #e2e8f0;
            --text-primary: #1e293b;
            --text-secondary: #64748b;
            --radius-lg: 20px;
            --radius-md: 14px;
            --radius-sm: 8px;
            --shadow-glow: 0 20px 40px -15px rgba(255, 0, 84, 0.15);
            --shadow-card: 0 10px 30px rgba(0, 0, 0, 0.06);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: "Outfit", "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #edf2f7 50%, #e2e8f0 100%);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            line-height: 1.5;
        }

        /* Header Navigation Bar */
        .neon-header {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-bottom: 1px solid rgba(226, 232, 240, 0.8);
            position: sticky;
            top: 0;
            z-index: 1000;
            padding: 16px 32px;
        }
        .header-content {
            max-width: 1100px;
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
            font-weight: 800;
            color: var(--neon-pink);
            letter-spacing: -0.02em;
        }
        .back-link {
            color: var(--text-secondary);
            text-decoration: none;
            font-weight: 600;
            font-size: 0.95rem;
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

        /* Main Container */
        .onboard-wrapper {
            max-width: 880px;
            margin: 40px auto;
            padding: 0 20px 60px;
            width: 100%;
        }

        /* Card Frame */
        .onboard-card {
            background: var(--neon-card-bg);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-card), var(--shadow-glow);
            border: 1px solid rgba(255, 255, 255, 0.6);
            overflow: hidden;
            transition: all 0.3s ease;
        }

        .card-header-banner {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            padding: 32px;
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
            width: 300px;
            height: 300px;
            background: radial-gradient(circle, rgba(255, 0, 84, 0.25) 0%, transparent 70%);
            pointer-events: none;
        }
        .header-title-group h1 {
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 6px;
            color: #ffffff;
        }
        .header-title-group p {
            color: #94a3b8;
            font-size: 0.9rem;
        }
        .type-badge {
            background: linear-gradient(135deg, var(--neon-pink) 0%, #e0004a 100%);
            color: white;
            font-weight: 700;
            font-size: 0.85rem;
            padding: 8px 16px;
            border-radius: 30px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            box-shadow: 0 4px 12px rgba(255, 0, 84, 0.3);
        }

        /* Step Progress Bar */
        .stepper-container {
            padding: 24px 32px;
            background: #f8fafc;
            border-bottom: 1px solid var(--neon-border);
        }
        .stepper-bar {
            display: flex;
            justify-content: space-between;
            position: relative;
        }
        .stepper-bar::before {
            content: "";
            position: absolute;
            top: 18px;
            left: 0;
            right: 0;
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
            flex: 1;
        }
        .step-circle {
            width: 38px;
            height: 38px;
            border-radius: 50%;
            background: white;
            border: 3px solid #cbd5e1;
            color: #64748b;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 0.95rem;
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
            font-size: 0.8rem;
            font-weight: 600;
            color: #94a3b8;
            margin-top: 8px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .step-node.active .step-title {
            color: var(--neon-pink);
        }
        .step-node.completed .step-title {
            color: var(--neon-cyan);
        }

        /* Form Body */
        .card-body {
            padding: 36px 32px;
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
            font-size: 1.2rem;
            font-weight: 700;
            margin-bottom: 24px;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .section-heading i {
            color: var(--neon-pink);
        }

        /* Form Controls */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
        }
        .form-group.full-width {
            grid-column: span 2;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .form-group label {
            font-size: 0.88rem;
            font-weight: 600;
            color: #334155;
        }
        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }
        .input-wrapper i {
            position: absolute;
            left: 14px;
            color: #94a3b8;
            font-size: 1rem;
            pointer-events: none;
        }
        .form-control {
            width: 100%;
            padding: 12px 16px 12px 42px;
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
            box-shadow: 0 0 0 3px rgba(255, 0, 84, 0.12);
        }
        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%2394a3b8'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 14px center;
            background-size: 16px;
        }

        /* Type Selector Cards */
        .account-type-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }
        .type-card {
            border: 2px solid var(--neon-border);
            border-radius: var(--radius-md);
            padding: 18px;
            cursor: pointer;
            transition: all 0.2s;
            background: white;
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .type-card:hover {
            border-color: #f472b6;
            transform: translateY(-2px);
        }
        .type-card.selected {
            border-color: var(--neon-pink);
            background: rgba(255, 0, 84, 0.03);
            box-shadow: 0 4px 14px rgba(255, 0, 84, 0.1);
        }
        .type-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: rgba(255, 0, 84, 0.1);
            color: var(--neon-pink);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
            flex-shrink: 0;
        }
        .type-card.selected .type-icon {
            background: var(--neon-pink);
            color: white;
        }
        .type-info h4 {
            font-size: 0.95rem;
            font-weight: 700;
        }
        .type-info p {
            font-size: 0.8rem;
            color: var(--text-secondary);
        }

        /* Upload Dropzones */
        .upload-card {
            border: 2px dashed #cbd5e1;
            border-radius: var(--radius-md);
            padding: 24px;
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
            font-size: 2rem;
            color: var(--neon-cyan);
            margin-bottom: 8px;
        }
        .upload-title {
            font-size: 0.9rem;
            font-weight: 700;
            color: var(--text-primary);
        }
        .upload-sub {
            font-size: 0.78rem;
            color: var(--text-secondary);
            margin-top: 4px;
        }
        .upload-preview {
            max-height: 120px;
            width: auto;
            border-radius: var(--radius-sm);
            margin-top: 10px;
            display: none;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }

        /* Canvas Signature Pad */
        .sig-pad-wrapper {
            border: 1px solid var(--neon-border);
            border-radius: var(--radius-sm);
            background: white;
            position: relative;
        }
        canvas#sigCanvas {
            width: 100%;
            height: 140px;
            border-radius: var(--radius-sm);
            cursor: crosshair;
            touch-action: none;
        }
        .clear-sig-btn {
            position: absolute;
            top: 8px;
            right: 8px;
            background: #f1f5f9;
            border: none;
            padding: 4px 10px;
            font-size: 0.75rem;
            font-weight: 600;
            border-radius: 4px;
            cursor: pointer;
            color: #64748b;
        }
        .clear-sig-btn:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        /* Buttons Footer */
        .card-footer-nav {
            padding: 24px 32px 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-top: 1px solid var(--neon-border);
            background: #ffffff;
        }
        .btn {
            padding: 12px 28px;
            border-radius: 30px;
            font-size: 0.95rem;
            font-weight: 700;
            font-family: inherit;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border: none;
        }
        .btn-secondary {
            background: #f1f5f9;
            color: #475569;
        }
        .btn-secondary:hover {
            background: #e2e8f0;
            color: #0f172a;
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

        /* Success Modal Overlay */
        .success-overlay {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(8px);
            z-index: 2000;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .success-modal {
            background: white;
            border-radius: 24px;
            max-width: 500px;
            width: 100%;
            padding: 40px 32px;
            text-align: center;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            animation: modalPop 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        @keyframes modalPop {
            from { opacity: 0; transform: scale(0.9); }
            to { opacity: 1; transform: scale(1); }
        }
        .success-badge-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, var(--neon-cyan) 0%, var(--neon-teal) 100%);
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2.2rem;
            margin: 0 auto 20px;
            box-shadow: 0 10px 25px rgba(31, 169, 178, 0.4);
        }
        .app-ref-box {
            background: #f8fafc;
            border: 1px dashed var(--neon-cyan);
            padding: 12px 20px;
            border-radius: var(--radius-sm);
            margin: 20px 0;
            font-size: 1.1rem;
            font-weight: 800;
            color: var(--neon-cyan);
            letter-spacing: 0.05em;
        }

        @media (max-width: 640px) {
            .form-grid, .account-type-grid {
                grid-template-columns: 1fr;
            }
            .form-group.full-width {
                grid-column: span 1;
            }
            .card-header-banner {
                flex-direction: column;
                align-items: flex-start;
                gap: 12px;
            }
            .stepper-container {
                padding: 16px;
            }
            .step-title {
                display: none;
            }
        }
    </style>
</head>
<body>

    <!-- Header Navigation -->
    <header class="neon-header">
        <div class="header-content">
            <a href="index.php" class="brand-logo">
                <img src="logo.png" alt="Neon Logo" onerror="this.src='assets/7PzcYdFs3fE3HNk64pDrpdmsSOk.svg';">
                <span class="brand-name">neon</span>
            </a>
            <a href="index.php" class="back-link">
                <i class="fa-solid fa-arrow-left"></i>
                <span>Back to Home</span>
            </a>
        </div>
    </header>

    <!-- Form Container Wrapper -->
    <div class="onboard-wrapper">
        <div class="onboard-card">
            
            <!-- Banner Header -->
            <div class="card-header-banner">
                <div class="header-title-group">
                    <h1>Open Your Neon Account</h1>
                    <p>Digital, zero hidden fees, 100% Swiss security</p>
                </div>
                <div class="type-badge" id="accountBadgeText"><?= htmlspecialchars($accountTitle) ?></div>
            </div>

            <!-- Stepper Progress Bar -->
            <div class="stepper-container">
                <div class="stepper-bar">
                    <div class="step-node active" id="node1">
                        <div class="step-circle">1</div>
                        <span class="step-title">Account & Info</span>
                    </div>
                    <div class="step-node" id="node2">
                        <div class="step-circle">2</div>
                        <span class="step-title">Address & ID</span>
                    </div>
                    <div class="step-node" id="node3">
                        <div class="step-circle">3</div>
                        <span class="step-title">KYC Uploads</span>
                    </div>
                    <div class="step-node" id="node4">
                        <div class="step-circle">4</div>
                        <span class="step-title">Signature & Review</span>
                    </div>
                </div>
            </div>

            <!-- Form Form Wrapper -->
            <form id="neonOnboardForm">
                <input type="hidden" name="account_type" id="inputAccountType" value="<?= htmlspecialchars($type) ?>">

                <div class="card-body">
                    
                    <!-- STEP 1: ACCOUNT & PERSONAL INFO -->
                    <div class="form-section active" id="section1">
                        <div class="section-heading">
                            <i class="fa-solid fa-user-gear"></i>
                            <span>Select Account & Personal Details</span>
                        </div>

                        <div class="account-type-grid">
                            <div class="type-card <?= $type==='CURRENT'?'selected':'' ?>" onclick="selectType('CURRENT', 'Everyday Current Account', this)">
                                <div class="type-icon"><i class="fa-solid fa-wallet"></i></div>
                                <div class="type-info">
                                    <h4>Everyday Current</h4>
                                    <p>Zero monthly fees, free Debit Mastercard</p>
                                </div>
                            </div>
                            <div class="type-card <?= $type==='SAVINGS'?'selected':'' ?>" onclick="selectType('SAVINGS', 'High-Yield Savings Account', this)">
                                <div class="type-icon"><i class="fa-solid fa-piggy-bank"></i></div>
                                <div class="type-info">
                                    <h4>Neon Savings</h4>
                                    <p>Earn high interest on your savings</p>
                                </div>
                            </div>
                            <div class="type-card <?= $type==='JOINT'?'selected':'' ?>" onclick="selectType('JOINT', 'Joint Account for Duos', this)">
                                <div class="type-icon"><i class="fa-solid fa-people-hold"></i></div>
                                <div class="type-info">
                                    <h4>Joint Duo Account</h4>
                                    <p>Shared finances under one roof</p>
                                </div>
                            </div>
                            <div class="type-card <?= $type==='INVEST'?'selected':'' ?>" onclick="selectType('INVEST', 'Stocks & ETFs Investment Account', this)">
                                <div class="type-icon"><i class="fa-solid fa-chart-line"></i></div>
                                <div class="type-info">
                                    <h4>Neon Invest</h4>
                                    <p>Invest in global stocks & ETFs</p>
                                </div>
                            </div>
                        </div>

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="full_name">Full Legal Name *</label>
                                <div class="input-wrapper">
                                    <i class="fa-regular fa-user"></i>
                                    <input type="text" id="full_name" name="full_name" class="form-control" placeholder="e.g. Marc Muster" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address *</label>
                                <div class="input-wrapper">
                                    <i class="fa-regular fa-envelope"></i>
                                    <input type="email" id="email" name="email" class="form-control" placeholder="name@domain.com" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="phone">Mobile Phone *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-mobile-screen"></i>
                                    <input type="tel" id="phone" name="phone" class="form-control" placeholder="+41 79 123 45 67" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="dob">Date of Birth *</label>
                                <div class="input-wrapper">
                                    <i class="fa-regular fa-calendar"></i>
                                    <input type="date" id="dob" name="dob" class="form-control" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="gender">Gender *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-venus-mars"></i>
                                    <select id="gender" name="gender" class="form-control" required>
                                        <option value="">Select Gender</option>
                                        <option value="Male">Male</option>
                                        <option value="Female">Female</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="initial_deposit">Initial Deposit Amount (CHF) *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-coins"></i>
                                    <input type="number" id="initial_deposit" name="initial_deposit" class="form-control" placeholder="100.00" value="100" min="10" required>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 2: ADDRESS & IDENTIFICATION -->
                    <div class="form-section" id="section2">
                        <div class="section-heading">
                            <i class="fa-solid fa-location-dot"></i>
                            <span>Address & Identification Document</span>
                        </div>

                        <div class="form-grid">
                            <div class="form-group full-width">
                                <label for="address">Residential Address *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-house"></i>
                                    <input type="text" id="address" name="address" class="form-control" placeholder="Street, House No, Postal Code, City" required>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="nationality">Country / Nationality *</label>
                                <div class="input-wrapper">
                                    <i class="fa-solid fa-globe"></i>
                                    <select id="nationality" name="nationality" class="form-control" onchange="onCountryChange(this.value)" required>
                                        <option value="Switzerland" selected>Switzerland 🇨🇭</option>
                                        <option value="India">India 🇮🇳</option>
                                        <option value="United States">United States 🇺🇸</option>
                                        <option value="United Kingdom">United Kingdom 🇬🇧</option>
                                        <option value="Germany">Germany 🇩🇪</option>
                                        <option value="France">France 🇫🇷</option>
                                        <option value="United Arab Emirates">United Arab Emirates 🇦🇪</option>
                                        <option value="Singapore">Singapore 🇸🇬</option>
                                        <option value="Canada">Canada 🇨🇦</option>
                                        <option value="Australia">Australia 🇦🇺</option>
                                        <option value="Japan">Japan 🇯🇵</option>
                                        <option value="Other">Other Country</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="national_id" id="lbl_national_id">National ID / Passport Number *</label>
                                <div class="input-wrapper">
                                    <i class="fa-regular fa-id-card"></i>
                                    <input type="text" id="national_id" name="national_id" class="form-control" placeholder="e.g. S12345678" required>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 3: KYC UPLOADS -->
                    <div class="form-section" id="section3">
                        <div class="section-heading">
                            <i class="fa-solid fa-cloud-arrow-up"></i>
                            <span>Verification Documents (Selfie & Documents)</span>
                        </div>

                        <div class="form-grid">
                            <div class="form-group">
                                <label>Live Selfie / Portrait Photo *</label>
                                <div class="upload-card" onclick="triggerFileInput('filePortrait')">
                                    <i class="fa-solid fa-camera upload-icon"></i>
                                    <div class="upload-title">Take Selfie or Upload Photo</div>
                                    <div class="upload-sub">Clear facial photo in good lighting</div>
                                    <img id="prevPortrait" class="upload-preview" alt="Portrait Preview">
                                </div>
                                <input type="file" id="filePortrait" accept="image/*" style="display:none" onchange="handleFile(this, 'portrait_data', 'prevPortrait')">
                                <input type="hidden" name="portrait_data" id="portrait_data" required>
                            </div>

                            <div class="form-group">
                                <label id="lbl_doc_id_title">National ID / Passport Document *</label>
                                <div class="upload-card" onclick="triggerFileInput('fileIdDoc')">
                                    <i class="fa-solid fa-passport upload-icon"></i>
                                    <div class="upload-title" id="lbl_doc_id_head">Upload Passport / ID Card</div>
                                    <div class="upload-sub" id="lbl_doc_id_sub">Front side image of ID card</div>
                                    <img id="prevIdDoc" class="upload-preview" alt="ID Preview">
                                </div>
                                <input type="file" id="fileIdDoc" accept="image/*" style="display:none" onchange="handleFile(this, 'doc_pan_data', 'prevIdDoc')">
                                <input type="hidden" name="doc_pan_data" id="doc_pan_data" required>
                            </div>

                            <div class="form-group full-width">
                                <label>Proof of Address (Utility Bill / Bank Statement) *</label>
                                <div class="upload-card" onclick="triggerFileInput('fileAddressDoc')">
                                    <i class="fa-solid fa-file-invoice upload-icon"></i>
                                    <div class="upload-title">Upload Proof of Address</div>
                                    <div class="upload-sub">Recent document (less than 3 months old)</div>
                                    <img id="prevAddressDoc" class="upload-preview" alt="Address Proof Preview">
                                </div>
                                <input type="file" id="fileAddressDoc" accept="image/*" style="display:none" onchange="handleFile(this, 'doc_aadhaar_data', 'prevAddressDoc')">
                                <input type="hidden" name="doc_aadhaar_data" id="doc_aadhaar_data" required>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 4: SIGNATURE & CONSENT -->
                    <div class="form-section" id="section4">
                        <div class="section-heading">
                            <i class="fa-solid fa-file-signature"></i>
                            <span>Digital Signature & Final Review</span>
                        </div>

                        <div class="form-group full-width" style="margin-bottom: 24px;">
                            <label>Draw Digital Signature *</label>
                            <div class="sig-pad-wrapper">
                                <button type="button" class="clear-sig-btn" onclick="clearSignature()"><i class="fa-solid fa-rotate-left"></i> Clear</button>
                                <canvas id="sigCanvas"></canvas>
                            </div>
                            <input type="hidden" name="signature_data" id="signature_data" required>
                        </div>

                        <div style="background: #f8fafc; padding: 20px; border-radius: var(--radius-sm); border: 1px solid var(--neon-border);">
                            <label style="display: flex; gap: 12px; align-items: flex-start; cursor: pointer;">
                                <input type="checkbox" id="termsCheck" required style="margin-top: 4px; accent-color: var(--neon-pink); width: 18px; height: 18px;">
                                <span style="font-size: 0.88rem; color: #475569;">
                                    I confirm that the details provided are accurate and complete. I agree to the <a href="#" style="color: var(--neon-pink); text-decoration: underline;">Neon Terms of Service</a> and Privacy Policy.
                                </span>
                            </label>
                        </div>
                    </div>

                </div>

                <!-- Footer Navigation Buttons -->
                <div class="card-footer-nav">
                    <button type="button" class="btn btn-secondary" id="btnPrev" style="visibility: hidden;" onclick="changeStep(-1)">
                        <i class="fa-solid fa-arrow-left"></i> Previous
                    </button>
                    <button type="button" class="btn btn-primary" id="btnNext" onclick="changeStep(1)">
                        <span>Next Step</span> <i class="fa-solid fa-arrow-right"></i>
                    </button>
                </div>

            </form>

        </div>
    </div>

    <!-- Success Modal -->
    <div class="success-overlay" id="successModal">
        <div class="success-modal">
            <div class="success-badge-icon">
                <i class="fa-solid fa-check"></i>
            </div>
            <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--text-primary); margin-bottom: 8px;">Application Submitted!</h2>
            <p style="color: var(--text-secondary); font-size: 0.95rem;">Welcome to <strong>Neon Finance</strong>. Your digital onboarding application has been successfully received.</p>
            
            <div class="app-ref-box" id="modalAppId">FR-000000</div>
            
            <p style="font-size: 0.85rem; color: #64748b; margin-bottom: 24px;">Our verification team will review your KYC documents within 72 hrs. You can download the <strong>Neon Finance Mobile App</strong> to sign in once approved.</p>
            
            <a href="index.php" class="btn btn-primary" style="width: 100%; justify-content: center;">Done & Return Home</a>
        </div>
    </div>

    <!-- JavaScript Handling -->
    <script>
        let currentStep = 1;

        function selectType(typeName, title, cardElem) {
            document.getElementById('inputAccountType').value = typeName;
            document.getElementById('accountBadgeText').innerText = title;
            document.querySelectorAll('.type-card').forEach(c => c.classList.remove('selected'));
            cardElem.classList.add('selected');
        }

        function changeStep(delta) {
            if (delta === 1) {
                if (!validateCurrentStep()) return;
                if (currentStep === 4) {
                    submitForm();
                    return;
                }
            }

            currentStep += delta;
            if (currentStep < 1) currentStep = 1;
            if (currentStep > 4) currentStep = 4;

            // Update UI Sections
            document.querySelectorAll('.form-section').forEach((s, idx) => {
                s.classList.toggle('active', idx === (currentStep - 1));
            });

            // Update Stepper Nodes
            for (let i = 1; i <= 4; i++) {
                const node = document.getElementById(`node${i}`);
                if (node) {
                    if (i < currentStep) {
                        node.className = 'step-node completed';
                    } else if (i === currentStep) {
                        node.className = 'step-node active';
                    } else {
                        node.className = 'step-node';
                    }
                }
            }

            // Ensure canvas has correct width when entering Step 4
            if (currentStep === 4) {
                setTimeout(resizeCanvas, 60);
            }

            // Update Footer Buttons
            document.getElementById('btnPrev').style.visibility = (currentStep === 1) ? 'hidden' : 'visible';
            const btnNext = document.getElementById('btnNext');
            if (currentStep === 4) {
                btnNext.innerHTML = `<span>Submit Application</span> <i class="fa-solid fa-paper-plane"></i>`;
            } else {
                btnNext.innerHTML = `<span>Next Step</span> <i class="fa-solid fa-arrow-right"></i>`;
            }
        }

        function onCountryChange(country) {
            const lbl = document.getElementById('lbl_national_id');
            const input = document.getElementById('national_id');
            const docTitle = document.getElementById('lbl_doc_id_title');
            const docHead = document.getElementById('lbl_doc_id_head');
            const docSub = document.getElementById('lbl_doc_id_sub');

            if (country === 'India') {
                if (lbl) lbl.innerText = 'Aadhaar Card Number / National ID *';
                if (input) input.placeholder = 'e.g. 1234 5678 9012';
                if (docTitle) docTitle.innerText = 'Aadhaar Card / Government ID *';
                if (docHead) docHead.innerText = 'Upload Aadhaar Card / ID';
                if (docSub) docSub.innerText = 'Front side image of Aadhaar Card or National ID';
            } else {
                if (lbl) lbl.innerText = 'National ID / Passport Number *';
                if (input) input.placeholder = 'e.g. S12345678';
                if (docTitle) docTitle.innerText = 'National ID / Passport Document *';
                if (docHead) docHead.innerText = 'Upload Passport / ID Card';
                if (docSub) docSub.innerText = 'Front side image of Passport or Government ID';
            }
        }

        function validateCurrentStep() {
            const currentSection = document.getElementById(`section${currentStep}`);
            if (!currentSection) return true;

            // Dedicated validation for Step 4
            if (currentStep === 4) {
                const sig = document.getElementById('signature_data')?.value;
                if (!sig || sig.trim() === '') {
                    alert('Please draw your digital signature on the signature pad.');
                    return false;
                }
                const terms = document.getElementById('termsCheck');
                if (!terms || !terms.checked) {
                    alert('Please accept the Terms of Service to proceed.');
                    return false;
                }
                return true;
            }

            const inputs = currentSection.querySelectorAll('input[required], select[required]');
            for (let input of inputs) {
                if (input.type === 'hidden') {
                    if (!input.value || input.value.trim() === '') {
                        if (input.id === 'portrait_data') {
                            alert('Please capture or upload your Live Selfie / Portrait Photo.');
                        } else if (input.id === 'doc_pan_data') {
                            const country = document.getElementById('nationality')?.value;
                            alert(country === 'India' ? 'Please upload your Aadhaar Card / ID Document.' : 'Please upload your National ID / Passport Document.');
                        } else if (input.id === 'doc_aadhaar_data') {
                            alert('Please upload your Proof of Address.');
                        } else {
                            alert('Please complete all required fields in this step.');
                        }
                        return false;
                    }
                    continue;
                }

                if (input.type === 'checkbox') {
                    if (!input.checked) {
                        alert('Please check the required agreement box.');
                        return false;
                    }
                    continue;
                }

                if (!input.value || input.value.trim() === '') {
                    try { input.focus(); } catch (e) {}
                    let label = '';
                    if (input.id) {
                        const associatedLabel = document.querySelector(`label[for="${input.id}"]`);
                        if (associatedLabel) {
                            label = associatedLabel.innerText.replace('*', '').trim();
                        }
                    }
                    if (!label && input.labels && input.labels.length > 0) {
                        label = input.labels[0].innerText.replace('*', '').trim();
                    }
                    if (!label) {
                        label = input.getAttribute('placeholder') || input.name || 'Required field';
                    }
                    alert('Please complete the required field: ' + label);
                    return false;
                }
            }
            return true;
        }

        function triggerFileInput(id) {
            document.getElementById(id).click();
        }

        function handleFile(fileInput, targetHiddenId, previewImgId) {
            const file = fileInput.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById(targetHiddenId).value = e.target.result;
                    const prev = document.getElementById(previewImgId);
                    prev.src = e.target.result;
                    prev.style.display = 'inline-block';
                };
                reader.readAsDataURL(file);
            }
        }

        // Canvas Signature Pad Logic
        const canvas = document.getElementById('sigCanvas');
        const ctx = canvas.getContext('2d');
        let drawing = false;

        function resizeCanvas() {
            const parentWidth = canvas.parentElement ? canvas.parentElement.clientWidth : 0;
            const targetWidth = parentWidth > 50 ? parentWidth : (window.innerWidth > 600 ? 580 : 320);

            // Preserve canvas content across resize if already drawn
            const prevData = canvas.toDataURL();
            const hadDrawing = document.getElementById('signature_data').value !== '';

            canvas.width = targetWidth;
            canvas.height = 140;
            ctx.lineWidth = 2.5;
            ctx.lineCap = 'round';
            ctx.strokeStyle = '#0f172a';

            if (hadDrawing) {
                const img = new Image();
                img.onload = function() {
                    ctx.drawImage(img, 0, 0);
                };
                img.src = prevData;
            }
        }
        window.addEventListener('resize', resizeCanvas);
        // Initial setup
        resizeCanvas();

        function getPos(e) {
            const rect = canvas.getBoundingClientRect();
            const clientX = e.touches ? e.touches[0].clientX : e.clientX;
            const clientY = e.touches ? e.touches[0].clientY : e.clientY;
            return { x: clientX - rect.left, y: clientY - rect.top };
        }

        canvas.addEventListener('mousedown', (e) => { drawing = true; ctx.beginPath(); const pos = getPos(e); ctx.moveTo(pos.x, pos.y); });
        canvas.addEventListener('mousemove', (e) => { if (!drawing) return; const pos = getPos(e); ctx.lineTo(pos.x, pos.y); ctx.stroke(); updateSigInput(); });
        canvas.addEventListener('mouseup', () => drawing = false);
        canvas.addEventListener('touchstart', (e) => { e.preventDefault(); drawing = true; ctx.beginPath(); const pos = getPos(e); ctx.moveTo(pos.x, pos.y); }, { passive: false });
        canvas.addEventListener('touchmove', (e) => { e.preventDefault(); if (!drawing) return; const pos = getPos(e); ctx.lineTo(pos.x, pos.y); ctx.stroke(); updateSigInput(); }, { passive: false });
        canvas.addEventListener('touchend', () => drawing = false);

        function updateSigInput() {
            document.getElementById('signature_data').value = canvas.toDataURL('image/png');
        }

        function clearSignature() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            document.getElementById('signature_data').value = '';
        }

        // AJAX Form Submission
        function submitForm() {
            const terms = document.getElementById('termsCheck');
            if (!terms || !terms.checked) {
                alert('Please accept the Terms of Service to proceed.');
                return;
            }
            const sig = document.getElementById('signature_data')?.value;
            if (!sig || sig.trim() === '') {
                alert('Please draw your digital signature before submitting.');
                return;
            }

            const btnNext = document.getElementById('btnNext');
            if (btnNext) {
                btnNext.disabled = true;
                btnNext.innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> Submitting...`;
            }

            const form = document.getElementById('neonOnboardForm');
            const formData = new FormData(form);

            // Ensure national_id maps to aadhaar_number for backend compatibility
            const nationalId = document.getElementById('national_id')?.value;
            if (nationalId && !formData.get('aadhaar_number')) {
                formData.append('aadhaar_number', nationalId);
            }

            fetch('api/submit.php', {
                method: 'POST',
                body: formData
            })
            .then(async res => {
                const text = await res.text();
                try {
                    return JSON.parse(text);
                } catch (e) {
                    console.error('Non-JSON response from server:', text);
                    throw new Error('Server returned unexpected output: ' + text.substring(0, 100));
                }
            })
            .then(data => {
                if (data.success || data.app_id) {
                    const appId = data.app_id || 'FR-' + Math.floor(100000 + Math.random() * 900000);
                    document.getElementById('modalAppId').innerText = appId;
                    document.getElementById('successModal').style.display = 'flex';
                } else {
                    alert(data.message || 'Submission failed. Please check form details.');
                    if (btnNext) {
                        btnNext.disabled = false;
                        btnNext.innerHTML = `<span>Submit Application</span> <i class="fa-solid fa-paper-plane"></i>`;
                    }
                }
            })
            .catch(err => {
                console.error('Submission error:', err);
                alert('Submission could not be completed: ' + err.message);
                if (btnNext) {
                    btnNext.disabled = false;
                    btnNext.innerHTML = `<span>Submit Application</span> <i class="fa-solid fa-paper-plane"></i>`;
                }
            });
        }
    </script>
</body>
</html>
