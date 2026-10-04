<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
/**
 * Neon Bank - Premium International Account Selection Page
 * Rebuilt with modern Swiss banking aesthetics, dynamic multi-currency highlights, and glassmorphic cards.
 */

require_once 'api/db_helper.php';

$ip = get_client_ip();
$isLimited = is_rate_limited($ip, 5, 10);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Choose Account Type - Neon Bank Switzerland</title>
    
    <!-- Modern Typography & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="icon" type="image/webp" href="logo.webp">
    
    <style>
        :root {
            --neon-pink: #ff0054;
            --neon-pink-hover: #d90047;
            --neon-purple: #7000ff;
            --neon-dark: #0b0f19;
            --neon-card-bg: #ffffff;
            --neon-border: #e2e8f0;
            --text-primary: #0f172a;
            --text-muted: #64748b;
            --gradient-primary: linear-gradient(135deg, #ff0054 0%, #7000ff 100%);
            --gradient-subtle: linear-gradient(135deg, rgba(255, 0, 84, 0.05) 0%, rgba(112, 0, 255, 0.05) 100%);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: #f8fafc;
            color: var(--text-primary);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            -webkit-font-smoothing: antialiased;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Header Navigation */
        .neon-header {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--neon-border);
            position: sticky;
            top: 0;
            z-index: 100;
            padding: 16px 0;
        }

        .header-container {
            max-width: 1140px;
            margin: 0 auto;
            padding: 0 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
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

        .brand-badge {
            background: rgba(255, 0, 84, 0.08);
            color: var(--neon-pink);
            font-size: 0.72rem;
            font-weight: 800;
            letter-spacing: 0.8px;
            padding: 4px 10px;
            border-radius: 20px;
            text-transform: uppercase;
            border: 1px solid rgba(255, 0, 84, 0.2);
        }

        .header-link {
            color: var(--text-muted);
            text-decoration: none;
            font-size: 0.9rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: color 0.2s;
        }

        .header-link:hover {
            color: var(--neon-pink);
        }

        /* Main Selection Layout */
        .main-wrapper {
            flex: 1;
            max-width: 1140px;
            margin: 0 auto;
            padding: 50px 24px 80px;
            width: 100%;
        }

        .hero-section {
            text-align: center;
            max-width: 720px;
            margin: 0 auto 50px;
        }

        .hero-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #ffffff;
            border: 1px solid var(--neon-border);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
            padding: 6px 16px;
            border-radius: 30px;
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 20px;
        }

        .hero-title {
            font-family: 'Outfit', sans-serif;
            font-size: 2.75rem;
            font-weight: 800;
            color: var(--text-primary);
            line-height: 1.15;
            letter-spacing: -0.03em;
            margin-bottom: 16px;
        }

        .hero-title span {
            background: var(--gradient-primary);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero-subtitle {
            font-size: 1.1rem;
            color: var(--text-muted);
            line-height: 1.6;
        }

        /* Account Cards Grid */
        .cards-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 28px;
            margin-bottom: 40px;
        }

        @media (max-width: 992px) {
            .cards-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 640px) {
            .cards-grid {
                grid-template-columns: 1fr;
            }
            .hero-title {
                font-size: 2.1rem;
            }
        }

        .account-card {
            background: var(--neon-card-bg);
            border: 1px solid var(--neon-border);
            border-radius: 24px;
            padding: 32px 28px;
            text-decoration: none;
            color: var(--text-primary);
            display: flex;
            flex-direction: column;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
            box-shadow: 0 4px 20px rgba(15, 23, 42, 0.03);
        }

        .account-card:hover {
            transform: translateY(-6px);
            border-color: rgba(255, 0, 84, 0.3);
            box-shadow: 0 20px 40px rgba(255, 0, 84, 0.08);
        }

        .card-popular-tag {
            position: absolute;
            top: -12px;
            right: 24px;
            background: var(--gradient-primary);
            color: #ffffff;
            font-size: 0.7rem;
            font-weight: 800;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            padding: 4px 12px;
            border-radius: 20px;
            box-shadow: 0 4px 12px rgba(255, 0, 84, 0.3);
        }

        .card-icon-wrapper {
            width: 56px;
            height: 56px;
            border-radius: 18px;
            background: var(--gradient-subtle);
            color: var(--neon-pink);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            margin-bottom: 22px;
            transition: transform 0.3s;
        }

        .account-card:hover .card-icon-wrapper {
            transform: scale(1.08) rotate(-3deg);
            background: var(--gradient-primary);
            color: #ffffff;
        }

        .card-heading {
            font-family: 'Outfit', sans-serif;
            font-size: 1.4rem;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--text-primary);
        }

        .card-description {
            font-size: 0.92rem;
            color: var(--text-muted);
            line-height: 1.55;
            margin-bottom: 24px;
            flex-grow: 1;
        }

        .card-features {
            list-style: none;
            margin-bottom: 28px;
        }

        .card-features li {
            font-size: 0.85rem;
            color: #475569;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
        }

        .card-features li i {
            color: #10b981;
            font-size: 0.8rem;
        }

        .card-action-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            background: #f1f5f9;
            color: var(--text-primary);
            padding: 12px 20px;
            border-radius: 14px;
            font-weight: 700;
            font-size: 0.9rem;
            transition: all 0.25s;
        }

        .account-card:hover .card-action-btn {
            background: var(--neon-pink);
            color: #ffffff;
            box-shadow: 0 8px 20px rgba(255, 0, 84, 0.25);
        }

        /* Rate Limit Throttle Block Screen */
        .block-card {
            max-width: 560px;
            margin: 60px auto;
            background: #ffffff;
            border-radius: 24px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 20px 50px rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.2);
            border-top: 6px solid #ef4444;
        }

        .block-icon {
            width: 70px;
            height: 70px;
            background: #fef2f2;
            color: #ef4444;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.8rem;
            margin: 0 auto 20px;
        }

        .block-title {
            font-family: 'Outfit', sans-serif;
            font-size: 1.6rem;
            font-weight: 800;
            color: #1e293b;
            margin-bottom: 12px;
        }

        .block-desc {
            color: #64748b;
            font-size: 0.95rem;
            line-height: 1.6;
            margin-bottom: 24px;
        }

        .btn-retry {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #f1f5f9;
            color: #334155;
            padding: 10px 24px;
            border-radius: 12px;
            font-weight: 700;
            text-decoration: none;
            transition: all 0.2s;
        }

        .btn-retry:hover {
            background: #e2e8f0;
        }

        /* Footer */
        .neon-footer {
            background: #ffffff;
            border-top: 1px solid var(--neon-border);
            padding: 24px 0;
            text-align: center;
            font-size: 0.85rem;
            color: var(--text-muted);
        }
    </style>
</head>
<body>

    <!-- Neon Header -->
    <header class="neon-header">
        <div class="header-container">
            <a href="index.php" class="brand-logo">
                <img src="logo.webp" alt="Neon Bank Logo">
                <span class="brand-badge">SWITZERLAND</span>
            </a>
            <a href="index.php" class="header-link">
                <i class="fa-solid fa-arrow-left"></i> Return to Main Portal
            </a>
        </div>
    </header>

    <main class="main-wrapper">
        <?php if ($isLimited): ?>
            <!-- Security Throttling Screen -->
            <div class="block-card">
                <div class="block-icon">
                    <i class="fa-solid fa-shield-halved"></i>
                </div>
                <h2 class="block-title">Security Protection Active</h2>
                <p class="block-desc">
                    Your connection has been temporarily rate-limited. We detected high-frequency network requests from your IP address (<strong><?= htmlspecialchars($ip) ?></strong>).
                </p>
                <p style="font-size: 0.85rem; color: #94a3b8; margin-bottom: 24px;">
                    Please wait 10 seconds before attempting to choose an account type.
                </p>
                <a href="choose-account.php" class="btn-retry">
                    <i class="fa-solid fa-rotate-right"></i> Try Again
                </a>
            </div>
        <?php else: ?>
            <!-- Main Account Selection Grid -->
            <div class="hero-section">
                <div class="hero-pill">
                    <span>🇨🇭</span> Swiss Multi-Currency Banking
                </div>
                <h1 class="hero-title">
                    Choose Your <span>Neon Account</span>
                </h1>
                <p class="hero-subtitle">
                    Select an account structure tailored for seamless international transfers, multi-currency spending, and global wealth management.
                </p>
            </div>

            <div class="cards-grid">
                <!-- 1. Everyday Current Account -->
                <a href="open-account.php?type=current" class="account-card">
                    <div class="card-popular-tag">MOST POPULAR</div>
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-wallet"></i>
                    </div>
                    <h3 class="card-heading">Everyday Current Account</h3>
                    <p class="card-description">
                        Essential Swiss account for international transfers, SWIFT/IBAN transactions, and zero-fee currency exchange.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> Free Swiss IBAN & SWIFT</li>
                        <li><i class="fa-solid fa-check"></i> 9+ Global Currencies (CHF, EUR, USD)</li>
                        <li><i class="fa-solid fa-check"></i> Virtual & Physical Neon Mastercard</li>
                    </ul>
                    <div class="card-action-btn">
                        Open Current Account <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>

                <!-- 2. High-Yield Savings Account -->
                <a href="open-account.php?type=savings" class="account-card">
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-piggy-bank"></i>
                    </div>
                    <h3 class="card-heading">Swiss Franc Savings</h3>
                    <p class="card-description">
                        Grow your capital in Swiss Francs (CHF) with high-yielding interest, automated savings spaces, and zero lock-in periods.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> Up to 2.45% APY on CHF</li>
                        <li><i class="fa-solid fa-check"></i> Automated Spaces Savings</li>
                        <li><i class="fa-solid fa-check"></i> Instant Liquidity & Withdrawals</li>
                    </ul>
                    <div class="card-action-btn">
                        Open Savings Account <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>

                <!-- 3. Global Equities & Investment -->
                <a href="open-account.php?type=invest" class="account-card">
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-chart-line"></i>
                    </div>
                    <h3 class="card-heading">Global Investments & ETFs</h3>
                    <p class="card-description">
                        Trade global stocks, Swiss blue-chips, and international ETFs directly from your Neon banking portal.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> Access to SIX Swiss Exchange</li>
                        <li><i class="fa-solid fa-check"></i> Low 0.15% Brokerage Commissions</li>
                        <li><i class="fa-solid fa-check"></i> Real-time Market Analytics</li>
                    </ul>
                    <div class="card-action-btn">
                        Start Investing <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>

                <!-- 4. Joint International Account -->
                <a href="open-account.php?type=joint" class="account-card">
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-users"></i>
                    </div>
                    <h3 class="card-heading">Joint Duo Account</h3>
                    <p class="card-description">
                        Share finances seamlessly with a partner or family member with dual cards and unified sub-account reporting.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> Dual Metal Neon Cards</li>
                        <li><i class="fa-solid fa-check"></i> Real-time Expense Tracking</li>
                        <li><i class="fa-solid fa-check"></i> Co-owner Authorization</li>
                    </ul>
                    <div class="card-action-btn">
                        Apply Joint Account <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>

                <!-- 5. Vehicle Financing -->
                <a href="open-account.php?type=vehicle" class="account-card">
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-car"></i>
                    </div>
                    <h3 class="card-heading">Vehicle Financing</h3>
                    <p class="card-description">
                        Flexible loan approvals for automobile acquisitions with low fixed interest rates and custom tenure options.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> 100% On-road Financing</li>
                        <li><i class="fa-solid fa-check"></i> Instant Pre-approval in 2 Mins</li>
                        <li><i class="fa-solid fa-check"></i> Flexible Repayment Plans</li>
                    </ul>
                    <div class="card-action-btn">
                        Apply Vehicle Credit <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>

                <!-- 6. Home & Property Account -->
                <a href="open-account.php?type=home" class="account-card">
                    <div class="card-icon-wrapper">
                        <i class="fa-solid fa-house-chimney"></i>
                    </div>
                    <h3 class="card-heading">Home & Property Credit</h3>
                    <p class="card-description">
                        Mortgage solutions and loans against property with dedicated Swiss banking relationship advisors.
                    </p>
                    <ul class="card-features">
                        <li><i class="fa-solid fa-check"></i> High Loan Value Limits</li>
                        <li><i class="fa-solid fa-check"></i> Dedicated Banking Manager</li>
                        <li><i class="fa-solid fa-check"></i> Zero Early Payoff Penalties</li>
                    </ul>
                    <div class="card-action-btn">
                        Apply Mortgage/LAP <i class="fa-solid fa-arrow-right"></i>
                    </div>
                </a>
            </div>
        <?php endif; ?>
    </main>

    <footer class="neon-footer">
        <p>&copy; <?= date('Y') ?> Neon Bank (Switzerland) Ltd. All rights reserved.</p>
    </footer>

</body>
</html>
