import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ForeignAssetsScreen extends StatelessWidget {
  const ForeignAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Foreign Assets & Global Markets", style: TextStyle(fontWeight: FontWeight.w800)),
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
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
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
                        child: const Icon(Icons.public_rounded, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("GLOBAL MARKETS", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Cross-Border Investments",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Direct access to US, European, Asian markets & offshore funds.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("SUPPORTED MARKETS & EXCHANGES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            _buildMarketTile("🇺🇸 United States (NYSE / NASDAQ)", "Apple, Microsoft, Tesla, Amazon", "USD \$ 32,450.00"),
            _buildMarketTile("🇪🇺 Europe (Euronext / DAX)", "LVMH, SAP, ASML, Siemens", "EUR € 18,200.00"),
            _buildMarketTile("🇬🇧 United Kingdom (LSE)", "AstraZeneca, HSBC, Shell, Unilever", "GBP £ 14,100.00"),
            _buildMarketTile("🇮🇳 India (NSE / BSE)", "Reliance, TCS, HDFC Bank, Infosys", "INR ₹ 8,40,000.00"),
            _buildMarketTile("🇸🇬 Singapore (SGX)", "DBS, Singtel, CapitaLand", "SGD S\$ 12,000.00"),

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
                    const SnackBar(content: Text("Redirecting to International Market Terminal.")),
                  );
                },
                child: const Text("Trade International Assets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTile(String title, String subtitle, String val) {
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
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonPink)),
        ],
      ),
    );
  }
}
