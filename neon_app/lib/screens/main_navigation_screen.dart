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
  List<Map<String, dynamic>> _beneficiaries = [];
  bool _isLoadingTxn = true;
  String _selectedAccountTier = "Main account";
  final TextEditingController _paymentRecipientController = TextEditingController();
  final TextEditingController _paymentAmountController = TextEditingController();
  String _selectedBeneficiaryName = "";
  String _selectedBeneficiaryBank = "";

  // Payment Mode: "P2P" (Neon Wallet) or "P2B" (External Bank Payout)
  String _paymentMode = "P2P";

  // P2B Payout Controllers
  final TextEditingController _p2bNameController = TextEditingController();
  final TextEditingController _p2bAccController = TextEditingController();
  final TextEditingController _p2bIfscController = TextEditingController();
  final TextEditingController _p2bAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchData();
  }

  @override
  void dispose() {
    _paymentRecipientController.dispose();
    _paymentAmountController.dispose();
    _p2bNameController.dispose();
    _p2bAccController.dispose();
    _p2bIfscController.dispose();
    _p2bAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final liveUser = await ApiService.getUserDetails(_user.appId);
    final list = await ApiService.getTransactions(_user.appId);
    final benList = await ApiService.getBeneficiaries(_user.appId);
    if (mounted) {
      setState(() {
        if (liveUser != null) {
          _user = liveUser;
        }
        _transactions = list;
        _beneficiaries = benList;
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
          onTap: (index) {
            if (index == 1) {
              _showTransferTypePickerModal();
            } else {
              setState(() => _currentIndex = index);
            }
          },
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
                      // Logout / Session Control icon
                      GestureDetector(
                        onTap: () async {
                          await ApiService.clearUserSession();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                        ),
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
                        "Account Balance ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₹ ${_user.balance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "A/C: ${_user.accountNumber.isNotEmpty ? _user.accountNumber : 'CH8900008730'} • IFSC: NEON0001",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Cards Bar (Card, Deposit, Statistics)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeaderShortcut(Icons.send_rounded, "Transfer"),
                      _buildHeaderShortcut(Icons.qr_code_2_rounded, "Scan UPI"),
                      _buildHeaderShortcut(Icons.account_balance_outlined, "Passbook"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Promotional Loan Banners Section
          SliverToBoxAdapter(
            child: Container(
              height: 140,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: PageView(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/loan1.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/loan2.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
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

  // Transfer Type Choice Modal Bottom Sheet
  void _showTransferTypePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Choose Transfer Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                "Select how you would like to send money",
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Option 1: Neon Wallet Transfer
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 1;
                    _paymentMode = "P2P";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neonPink.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.neonPink, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    "Neon Wallet",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonPink.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("ZERO FEE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.neonPink)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text("Instant transfer to another Neon account using 11-digit A/C number.", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Option 2: External Bank Transfer
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 1;
                    _paymentMode = "P2B";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neonBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: AppTheme.neonBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    "Other Bank",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("REAL BANK", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.neonBlue)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text("Direct IMPS / NEFT transfer to any external bank account / IBAN.", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // MPIN Verification Bottom Sheet Modal
  void _showMpinVerificationModal({
    required String recipientAccount,
    required String recipientName,
    required double amount,
    required String mode,
    String ifscCode = "",
  }) {
    final TextEditingController mpinController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    mode == "P2P" ? "Verify Neon Wallet Transfer" : "Verify Bank Transfer",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Enter your 6-digit MPIN to authorize transfer",
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Transfer Details Summary Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipientName.isNotEmpty ? recipientName : "Recipient",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text("A/C: $recipientAccount", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              if (ifscCode.isNotEmpty)
                                Text("IFSC: $ifscCode", style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹ ${amount.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: mode == "P2P" ? AppTheme.neonPink : AppTheme.neonBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: mpinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "******",
                      hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: mode == "P2P" ? AppTheme.neonPink : AppTheme.neonBlue, width: 2),
                      ),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final mpin = mpinController.text.trim();
                              if (mpin.isEmpty) {
                                setModalState(() => errorMessage = "Please enter your MPIN");
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });

                              final Map<String, dynamic> res;
                              if (mode == "P2P") {
                                res = await ApiService.sendP2P(
                                  senderAppId: _user.appId,
                                  recipientAccount: recipientAccount,
                                  amount: amount,
                                  mpin: mpin,
                                );
                              } else {
                                res = await ApiService.sendPayout(
                                  senderAppId: _user.appId,
                                  beneficiaryName: recipientName.isNotEmpty ? recipientName : "Beneficiary",
                                  beneficiaryAccount: recipientAccount,
                                  ifscCode: ifscCode.isNotEmpty ? ifscCode : "SBIN0001234",
                                  amount: amount,
                                  mpin: mpin,
                                );
                              }

                              setModalState(() => isSubmitting = false);

                              if (mounted) {
                                if (res['success'] == true || res['status'] == 'success' || res['status'] == 'PENDING') {
                                  Navigator.pop(context); // Close bottom sheet
                                  _fetchData(); // Refresh user balance & transactions
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentProcessingScreen(responseData: res),
                                    ),
                                  );
                                } else {
                                  setModalState(() {
                                    errorMessage = res['message'] ?? "Transfer failed. Please try again.";
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == "P2P" ? AppTheme.neonPink : AppTheme.neonBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("Verify & Authorize", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 2: PAYMENTS / ZAHLUNGEN
  // ==========================================
  Widget _buildPaymentsTab() {
    // Filter beneficiaries based on active payment mode
    final filteredBeneficiaries = _beneficiaries.where((b) {
      final type = (b['type'] ?? '').toString().toUpperCase();
      if (_paymentMode == "P2P") {
        return type == 'SELF_BANK';
      } else {
        return type == 'OTHER_BANK';
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          _paymentMode == "P2P" ? "Neon Wallet Transfer" : "Other Bank Transfer",
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Transfer Mode Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMode = "P2P"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _paymentMode == "P2P" ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _paymentMode == "P2P" ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, size: 18, color: _paymentMode == "P2P" ? AppTheme.neonPink : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              "Neon Wallet",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _paymentMode == "P2P" ? AppTheme.neonPink : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMode = "P2B"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _paymentMode == "P2B" ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _paymentMode == "P2B" ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_rounded, size: 18, color: _paymentMode == "P2B" ? AppTheme.neonBlue : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              "Other Bank",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _paymentMode == "P2B" ? AppTheme.neonBlue : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Beneficiary Header Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.neonPink, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Add Beneficiary", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                        SizedBox(height: 2),
                        Text("Save new recipient account or IBAN", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddBeneficiaryScreen(user: _user)),
                      );
                      if (updated == true) {
                        _fetchData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text("Add", style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Saved Beneficiaries Quick Bar (Filtered by Payment Mode)
            if (filteredBeneficiaries.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentMode == "P2P" ? "Neon Beneficiaries" : "Bank Beneficiaries",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text("${filteredBeneficiaries.length} Saved", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 82,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredBeneficiaries.length,
                  itemBuilder: (context, idx) {
                    final b = filteredBeneficiaries[idx];
                    final name = b['beneficiary_name'] ?? b['nickname'] ?? 'Recipient';
                    final acc = b['beneficiary_account_number'] ?? '';
                    final ifsc = b['ifsc_code'] ?? '';
                    final bankName = b['bank_name'] ?? b['nickname'] ?? (b['type'] == 'SELF_BANK' ? 'Neon Finance' : 'Bank Account');
                    final statusStr = (b['status'] ?? 'APPROVED').toString().toUpperCase();
                    final isApproved = statusStr == 'APPROVED' || statusStr == 'DONE';

                    return GestureDetector(
                      onTap: () {
                        if (!isApproved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Beneficiary approval is pending. Transfers will be enabled once approved."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          if (_paymentMode == "P2P") {
                            _paymentRecipientController.text = acc;
                          } else {
                            _p2bNameController.text = name;
                            _p2bAccController.text = acc;
                            _p2bIfscController.text = ifsc;
                          }
                          _selectedBeneficiaryName = name;
                          _selectedBeneficiaryBank = bankName;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Selected $name ($bankName)")),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.white : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isApproved 
                                ? (_paymentMode == "P2P" ? AppTheme.neonPink.withValues(alpha: 0.25) : AppTheme.neonBlue.withValues(alpha: 0.25))
                                : Colors.grey[300]!,
                          ),
                          boxShadow: isApproved ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)] : [],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isApproved 
                                  ? (_paymentMode == "P2P" ? AppTheme.neonPink.withValues(alpha: 0.15) : AppTheme.neonBlue.withValues(alpha: 0.15))
                                  : Colors.grey[300],
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                style: TextStyle(
                                  color: isApproved ? (_paymentMode == "P2P" ? AppTheme.neonPink : AppTheme.neonBlue) : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isApproved ? AppTheme.textPrimary : AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isApproved ? AppTheme.successGreen.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isApproved ? "APPROVED" : "PENDING",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isApproved ? AppTheme.successGreen : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(bankName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                Text(acc, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Transfer Form Section
            Text(
              _paymentMode == "P2P" ? "Send Money (Neon Wallet)" : "Send Money (Other Bank)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 14),

            if (_paymentMode == "P2P") ...[
              // MODE 1: P2P NEON WALLET TRANSFER FORM
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedBeneficiaryName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neonPink.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_circle_rounded, color: AppTheme.neonPink, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recipient: $_selectedBeneficiaryName",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                  Text("Neon Account: ${_paymentRecipientController.text}", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBeneficiaryName = "";
                                  _selectedBeneficiaryBank = "";
                                  _paymentRecipientController.clear();
                                });
                              },
                              child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _paymentRecipientController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Neon 11-Digit Account Number *",
                          labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "e.g. 38351908737",
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.neonPink, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _paymentAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Transfer Amount (₹ / CHF) *",
                          labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "0.00",
                          prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.neonPink, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Available Balance:", style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                          Text(
                            "₹ ${_user.balance.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final recipientAcc = _paymentRecipientController.text.trim();
                          final amountText = _paymentAmountController.text.trim();

                          if (recipientAcc.isEmpty || amountText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter recipient account and transfer amount.")),
                            );
                            return;
                          }
                          final amount = double.tryParse(amountText) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid transfer amount.")),
                            );
                            return;
                          }

                          if (_user.balance < amount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Insufficient account balance! Available: ₹ ${_user.balance.toStringAsFixed(2)}, Requested: ₹ ${amount.toStringAsFixed(2)}",
                                ),
                                backgroundColor: AppTheme.dangerRed,
                              ),
                            );
                            return;
                          }

                          _showMpinVerificationModal(
                            recipientAccount: recipientAcc,
                            recipientName: _selectedBeneficiaryName,
                            amount: amount,
                            mode: "P2P",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text("Confirm Wallet Transfer", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // MODE 2: P2B OTHER BANK PAYOUT FORM
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _p2bNameController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Beneficiary Full Name *",
                          labelStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "e.g. Rahul Sharma",
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.neonBlue, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _p2bAccController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Bank Account Number / IBAN *",
                          labelStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "e.g. 38351908737",
                          prefixIcon: Icon(Icons.account_balance_rounded, color: AppTheme.neonBlue, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _p2bIfscController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "IFSC / SWIFT Code *",
                          labelStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "e.g. SBIN0001234",
                          prefixIcon: Icon(Icons.business_rounded, color: AppTheme.neonBlue, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.2),
                      ),
                      child: TextField(
                        controller: _p2bAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Transfer Amount (₹ / CHF) *",
                          labelStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          hintText: "0.00",
                          prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.neonBlue, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Available Balance:", style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                          Text(
                            "₹ ${_user.balance.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = _p2bNameController.text.trim();
                          final acc = _p2bAccController.text.trim();
                          final ifsc = _p2bIfscController.text.trim();
                          final amountText = _p2bAmountController.text.trim();

                          if (name.isEmpty || acc.isEmpty || ifsc.isEmpty || amountText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all required payout fields.")),
                            );
                            return;
                          }
                          final amount = double.tryParse(amountText) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid transfer amount.")),
                            );
                            return;
                          }

                          if (_user.balance < amount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Insufficient account balance! Available: ₹ ${_user.balance.toStringAsFixed(2)}, Requested: ₹ ${amount.toStringAsFixed(2)}",
                                ),
                                backgroundColor: AppTheme.dangerRed,
                              ),
                            );
                            return;
                          }

                          _showMpinVerificationModal(
                            recipientAccount: acc,
                            recipientName: name,
                            amount: amount,
                            mode: "P2B",
                            ifscCode: ifsc,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text("Confirm Bank Payout", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
