import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TravelFinanceScreen extends StatelessWidget {
  const TravelFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Travel Finance & Zero FX Card", style: TextStyle(fontWeight: FontWeight.w800)),
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
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
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
                        child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("ZERO FX MARKUP", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Global Expat Travel Card",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Spend in 150+ countries at wholesale interbank exchange rates.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("VIP TRAVEL PRIVILEGES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            _buildPrivilegeTile(Icons.credit_card_rounded, "Zero FX Markup Worldwide", "No hidden 3.5% foreign currency transaction fee on overseas purchases."),
            _buildPrivilegeTile(Icons.airline_seat_recline_extra_rounded, "Complimentary Airport Lounge Pass", "Access 1,300+ Priority Pass airport lounges globally."),
            _buildPrivilegeTile(Icons.security_rounded, "Comprehensive Travel Insurance", "Up to USD \$1,000,000 medical coverage & emergency repatriation."),
            _buildPrivilegeTile(Icons.atm_rounded, "Free Global ATM Withdrawals", "Withdraw cash free of charge at international ATMs up to CHF 1,000/mo."),

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
                    const SnackBar(content: Text("Neon Swiss Metal Travel Card request received.")),
                  );
                },
                child: const Text("Order Swiss Travel Metal Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegeTile(IconData icon, String title, String desc) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple[800], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.darkNavy)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
