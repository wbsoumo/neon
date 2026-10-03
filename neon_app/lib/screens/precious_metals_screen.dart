import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PreciousMetalsScreen extends StatelessWidget {
  const PreciousMetalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Precious Metals & Swiss Gold Vaults", style: TextStyle(fontWeight: FontWeight.w800)),
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
                  colors: [Color(0xFFF57F17), Color(0xFFFFB300)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
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
                        child: const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("999.9 FINE GOLD", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Zurich Allocated Vault Gold",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Physically backed gold & silver stored in ultra-secure Zurich vaults.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("LIVE METAL PRICES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            _buildMetalTile("🟡 Physical Gold (XAU)", "CHF 76.85 / gram", "≈ ₹ 7,320 / gram", "+18.4% 1Y Return"),
            _buildMetalTile("⚪ Physical Silver (XAG)", "CHF 0.94 / gram", "≈ ₹ 89.60 / gram", "+22.1% 1Y Return"),
            _buildMetalTile("⚪ Platinum (XPT)", "CHF 31.20 / gram", "≈ ₹ 2,975 / gram", "+9.2% 1Y Return"),

            const SizedBox(height: 24),

            const Text("SWISS CUSTODY GUARANTEE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
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
                  Text("🏆 100% Allocated Ownership", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text("Every gram purchased is assigned a unique serial number held in high-security Zurich vaults.", style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
                  Divider(height: 20),
                  Text("🚚 Physical Delivery Available", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text("Option to request physical Swiss bullion delivery or instant cash liquidation at mid-market rates.", style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
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
                    const SnackBar(content: Text("Metal order terminal initiated.")),
                  );
                },
                child: const Text("Buy Physical Swiss Gold", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalTile(String metal, String chfPrice, String inrPrice, String returnStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metal, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.darkNavy)),
              const SizedBox(height: 3),
              Text(chfPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonPink)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(inrPrice, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                child: Text(returnStr, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
