import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwissLoansScreen extends StatelessWidget {
  const SwissLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Swiss Credit & Expat Mortgages", style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("RATES FROM 2.4% APR", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Swiss Credit Lines & Mortgages",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Flexible international financing for property, investments & liquidity.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("AVAILABLE FINANCING PRODUCTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            _buildLoanTile("Swiss Expat Home Mortgage", "Low fixed interest rates for residential property in Switzerland, EU, or India.", "2.4% Fixed APR", "Up to CHF 2,500,000"),
            _buildLoanTile("Lombard Investment Line", "Secured credit line against your Swiss custody equity & gold portfolio.", "1.9% Variable APR", "Up to 75% LTV"),
            _buildLoanTile("International Business Credit", "Cross-border working capital line for Swiss & global enterprise accounts.", "3.1% Variable APR", "Up to CHF 5,000,000"),

            const SizedBox(height: 24),

            const Text("ELIGIBILITY & ADVANTAGES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("✔️ Zero Foreign Currency Conversion Penalty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text("Repay in CHF, EUR, USD, or INR directly from your multi-currency balance.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Divider(height: 20),
                  Text("⚡ Fast 24-Hour Digital Approval", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text("Paperless application process verified against live account assets.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Loan pre-qualification check launched.")),
                  );
                },
                child: const Text("Apply for Swiss Credit Line", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTile(String title, String desc, String rate, String limit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.darkNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
                child: Text(rate, style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
          const SizedBox(height: 8),
          Text("Limit: $limit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.neonPink)),
        ],
      ),
    );
  }
}
