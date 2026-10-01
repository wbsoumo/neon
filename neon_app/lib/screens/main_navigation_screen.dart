import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import 'add_beneficiary_screen.dart';
import 'payment_processing_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel user;
  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late UserModel _user;
  List<TransactionModel> _transactions = [];
  bool _isLoadingTxn = true;

  // Selected Account Pill
  String _selectedAccountTier = "Main account";

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final list = await ApiService.getTransactions(_user.appId);
    if (mounted) {
      setState(() {
        _transactions = list;
        _isLoadingTxn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTransactionsTab(),
          _buildPaymentsTab(),
          _buildInvestTab(),
          _buildSpacesTab(),
          _buildStatisticsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.neonPink,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert_rounded),
              activeIcon: Icon(Icons.swap_vert_rounded, color: AppTheme.neonPink),
              label: "Transactions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.north_east_rounded),
              activeIcon: Icon(Icons.north_east_rounded, color: AppTheme.neonPink),
              label: "Payments",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              activeIcon: Icon(Icons.trending_up_rounded, color: AppTheme.neonPink),
              label: "Invest",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, color: AppTheme.neonPink),
              label: "Spaces",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_outline_rounded, color: AppTheme.neonPink),
              label: "Statistics",
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TRANSACTIONS / MAIN START (Screenshot #1 & #4)
  // ==========================================
  Widget _buildTransactionsTab() {
    final isBurgundyHeader = _selectedAccountTier == "Joint account";

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header Banner matching Screenshots #1 & #4
          SliverToBoxAdapter(
            child: Container(
              color: isBurgundyHeader ? AppTheme.neonBurgundy : AppTheme.neonPink,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Search icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Colors.white, size: 20),
                      ),
                      // Account Selector Switcher Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (val) => setState(() => _selectedAccountTier = val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: "Main account", child: Text("Main account (CHF 8'730.40)")),
                            const PopupMenuItem(value: "Personal account", child: Text("Personal account (CHF 3'500.00)")),
                            const PopupMenuItem(value: "Joint account", child: Text("Joint account (CHF 1'500.00)")),
                          ],
                          child: Row(
                            children: [
                              Text(
                                _selectedAccountTier,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      // QR scanner icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Balance & Currency Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        "Balance CHF ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedAccountTier == "Joint account" ? "1'500.00" : "8'730.40",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Cards Bar (Card, Deposit, Statistics)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeaderShortcut(Icons.credit_card_rounded, "Karte"),
                      _buildHeaderShortcut(Icons.add_rounded, "Einzahlen"),
                      _buildHeaderShortcut(Icons.bar_chart_rounded, "Statistiken"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Transactions Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "MARCH",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Transactions List
          if (_isLoadingTxn)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.neonPink),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final txn = _transactions[index];
                  final isCredit = txn.type == "CREDIT";
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isCredit ? Colors.green[50] : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              txn.recipientName.isNotEmpty ? txn.recipientName[0] : "N",
                              style: TextStyle(
                                color: isCredit ? AppTheme.successGreen : AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.recipientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                txn.date,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${isCredit ? '+' : '-'}${txn.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isCredit ? AppTheme.successGreen : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _transactions.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderShortcut(IconData icon, String label) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PAYMENTS / ZAHLUNGEN
  // ==========================================
  Widget _buildPaymentsTab() {
    final TextEditingController recipientController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Payments & Transfers", style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beneficiary Header Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.neonPink),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Add Beneficiary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Save new recipient account or IBAN", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddBeneficiaryScreen(user: _user)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Send Money Instantly",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: recipientController,
                    decoration: InputDecoration(
                      labelText: "Recipient Account Number / IBAN",
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount (CHF)",
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (recipientController.text.isEmpty || amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all transfer fields")),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        final res = await ApiService.sendP2P(
                          senderAppId: _user.appId,
                          recipientAccount: recipientController.text,
                          amount: amount,
                          mpin: "123456",
                        );
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentProcessingScreen(responseData: res),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Confirm Transfer", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: INVEST (Screenshot #3)
  // ==========================================
  Widget _buildInvestTab() {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Global Stocks (FTSE)", style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.star_outline_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Text
            const Text("Performance", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              children: const [
                Text("5.67 CHF", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                SizedBox(width: 8),
                Text("+0.81 CHF (+16.67%)", style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            // Performance Chart Card
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 4),
                        const FlSpot(2, 3.5),
                        const FlSpot(3, 5),
                        const FlSpot(4, 4.8),
                        const FlSpot(5, 5.67),
                      ],
                      isCurved: true,
                      color: AppTheme.successGreen,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time filters (1d, 1w, 1m, 1y, Max)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["1d", "1w", "1m", "1y", "Max"].map((label) {
                final isSelected = label == "1y";
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Buy asset banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Buy this asset long-term without fees via investment plan.",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("LEARN MORE", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: SPACES & CARDS (Screenshot #1 & #4)
  // ==========================================
  Widget _buildSpacesTab() {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Spaces & Cards", style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Savings Spaces", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildSpaceCard("Holidays", "2'400.00 CHF", Icons.flight_takeoff_rounded, Colors.orange[400]!)),
                const SizedBox(width: 12),
                Expanded(child: _buildSpaceCard("Taxes", "600.00 CHF", Icons.account_balance_rounded, Colors.brown[300]!)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonPink),
                  SizedBox(width: 8),
                  Text("Add new space", style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceCard(String name, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: STATISTICS (Screenshot #2)
  // ==========================================
  Widget _buildStatisticsTab() {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Statistics", style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Donut Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(color: AppTheme.neonCyan, value: 50, radius: 24, showTitle: false),
                          PieChartSectionData(color: AppTheme.successGreen, value: 20, radius: 24, showTitle: false),
                          PieChartSectionData(color: AppTheme.neonPink, value: 10, radius: 24, showTitle: false),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("CHF spent", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const Text("1'000.00", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const Text("This month", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
