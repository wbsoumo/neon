import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlobalInvestmentsScreen extends StatelessWidget {
  const GlobalInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Global Investments & Swiss Portfolios", style: TextStyle(fontWeight: FontWeight.w800)),
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
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
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
                        child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("+14.8% YTD", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Swiss Custody Portfolios",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Institutional-grade global market access with Swiss investor protection.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("PORTFOLIO STRATEGIES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            _buildStrategyCard("SMI 20 Swiss Equities", "Top 20 Swiss Blue Chips (Nestlé, Roche, Novartis)", "CHF 12,450.00", "+12.4%", Colors.green),
            _buildStrategyCard("Global Tech Basket ETF", "Apple, Microsoft, NVIDIA, ASML & TSMC", "CHF 8,920.00", "+24.8%", Colors.green),
            _buildStrategyCard("Swiss Dividend Aristocrats", "High-yield dividend paying Zurich stocks", "CHF 6,300.00", "+8.2%", Colors.green),
            _buildStrategyCard("ESG Global Green Bond Fund", "AAA Rated Green Infrastructure Bonds", "CHF 4,100.00", "+5.4%", Colors.blue),

            const SizedBox(height: 24),

            const Text("INVESTMENT FEATURES & FAQS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
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
                  Text("🔒 Swiss Banking Deposit Guarantee", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text("All investment accounts operate under SIX Swiss Exchange custody regulations with segregated asset holding.", style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                  Divider(height: 24),
                  Text("📊 Tax-Efficient Dividend Reinvestment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text("Automatic reinvestment option with zero withholding tax penalty for registered non-resident accounts.", style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
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
                    const SnackBar(content: Text("Portfolio allocation updated successfully.")),
                  );
                },
                child: const Text("Explore Investment Funds", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(String title, String desc, String nav, String returnStr, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.darkNavy)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(nav, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(returnStr, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
