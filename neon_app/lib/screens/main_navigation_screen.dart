import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/market_data_service.dart';
import '../models/space_model.dart';
import 'add_beneficiary_screen.dart';
import 'payment_processing_screen.dart';
import 'passbook_screen.dart';
import 'stock_details_screen.dart';
import 'space_details_screen.dart';
import 'banking_profile_center_screen.dart';
import 'send_money_screen.dart';
import 'forex_exchange_screen.dart';
import 'global_investments_screen.dart';
import 'foreign_assets_screen.dart';
import 'swiss_loans_screen.dart';
import 'travel_finance_screen.dart';
import 'precious_metals_screen.dart';

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

  // Payment Mode: "P2P" (Neon Bank) or "P2B" (External Bank Payout)
  String _paymentMode = "P2P";

  // P2B Payout Controllers
  final TextEditingController _p2bNameController = TextEditingController();
  final TextEditingController _p2bAccController = TextEditingController();
  final TextEditingController _p2bIfscController = TextEditingController();
  final TextEditingController _p2bAmountController = TextEditingController();

  // Live Exchange Rate & Stock Chart State
  double _inrToChfRate = 0.0105;
  String _selectedStockPeriod = "1y";
  List<double> _stockSpots = [0.932, 0.935, 0.941, 0.938, 0.945, 0.949, 0.952];
  bool _isLoadingStockData = false;

  // Investment Dashboard State
  List<StockItemModel> _allStocks = [];
  List<String> _watchlistSymbols = [];
  String _stockSearchQuery = '';
  String _selectedStockCategory = 'All';
  final TextEditingController _stockSearchController = TextEditingController();

  // Account Header Currency Switcher
  String _selectedHeaderCurrency = 'CHF';
  final Map<String, String> _currencyFlags = {
    'CHF': '🇨🇭',
    'INR': '🇮🇳',
    'AED': '🇦🇪',
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'SGD': '🇸🇬',
    'CAD': '🇨🇦',
    'AUD': '🇦🇺',
  };

  // Transaction Feed Search & Category Filter
  String _txnSearchQuery = '';
  String _txnCategoryFilter = 'All';
  final TextEditingController _txnSearchController = TextEditingController();

  // Recent Neon Bank Recipients (Local Storage)
  List<Map<String, dynamic>> _recentNeonRecipients = [];

  // Spaces State
  List<SpaceModel> _spaces = [];
  bool _isLoadingSpaces = true;
  double _mainBalanceChf = 0.0;
  double _mainBalanceInr = 0.0;

  // MPIN Setup Prompt State
  bool _hasShownMpinPopup = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _initDataAndCheckMpin();
    _fetchExchangeRatesAndStockData();
    _fetchSpaces();
    _fetchRecentNeonRecipients();
  }

  Future<void> _initDataAndCheckMpin() async {
    await _fetchData();
    if (mounted) {
      _checkMpinStatusAndPrompt();
    }
  }

  Future<void> _fetchRecentNeonRecipients() async {
    final list = await ApiService.getRecentNeonRecipients();
    if (mounted) {
      setState(() => _recentNeonRecipients = list);
    }
  }

  Future<void> _fetchSpaces() async {
    setState(() => _isLoadingSpaces = true);
    final res = await ApiService.fetchSpaces(_user.appId, sessionId: _user.sessionId);
    if (mounted) {
      if (res['success'] == true && res['spaces'] != null) {
        final List list = res['spaces'];
        setState(() {
          _spaces = list.map((x) => SpaceModel.fromJson(x)).toList();
          _mainBalanceChf = (res['main_balance_chf'] as num?)?.toDouble() ?? (_user.balance * _inrToChfRate);
          _mainBalanceInr = (res['main_balance_inr'] as num?)?.toDouble() ?? _user.balance;
          _isLoadingSpaces = false;
        });
      } else {
        setState(() {
          _mainBalanceChf = _user.balance * _inrToChfRate;
          _mainBalanceInr = _user.balance;
          _isLoadingSpaces = false;
        });
      }
    }
  }

  Future<void> _fetchExchangeRatesAndStockData() async {
    final rate = await ApiService.getInrToChfRate();
    final spots = await ApiService.getStockHistoryData(_selectedStockPeriod);
    final watchlist = await MarketDataService.getWatchlistSymbols();
    final initialStocks = MarketDataService.getInitialStocks();
    final updatedStocks = await MarketDataService.fetchUpdatedStockQuotes(initialStocks);

    if (mounted) {
      setState(() {
        _inrToChfRate = rate;
        _stockSpots = spots;
        _allStocks = updatedStocks;
        _watchlistSymbols = watchlist;
        _isLoadingStockData = false;
      });
    }
  }

  Future<void> _toggleWatchlist(String symbol) async {
    await MarketDataService.toggleWatchlistSymbol(symbol);
    final updated = await MarketDataService.getWatchlistSymbols();
    if (mounted) {
      setState(() => _watchlistSymbols = updated);
    }
  }

  Future<void> _onPeriodChanged(String period) async {
    setState(() {
      _selectedStockPeriod = period;
      _isLoadingStockData = true;
    });
    final spots = await ApiService.getStockHistoryData(period);
    if (mounted) {
      setState(() {
        _stockSpots = spots;
        _isLoadingStockData = false;
      });
    }
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
          _buildProfileTab(),
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
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppTheme.neonPink),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  double _getConvertedHeaderBalance() {
    final chfVal = _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate);
    switch (_selectedHeaderCurrency) {
      case 'CHF': return chfVal;
      case 'INR': return _user.balance;
      case 'USD': return chfVal * 1.145;
      case 'EUR': return chfVal * 1.042;
      case 'AED': return chfVal * 4.205;
      case 'GBP': return chfVal * 0.892;
      case 'SGD': return chfVal * 1.541;
      case 'CAD': return chfVal * 1.562;
      case 'AUD': return chfVal * 1.724;
      default: return chfVal;
    }
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AED': return 'AED ';
      case 'SGD': return 'S\$';
      case 'CAD': return 'CA\$';
      case 'AUD': return 'A\$';
      case 'CHF': return 'CHF ';
      default: return '$code ';
    }
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((t) {
      final q = _txnSearchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          t.recipientName.toLowerCase().contains(q) ||
          t.amount.toString().contains(q);

      if (!matchesQuery) return false;

      if (_txnCategoryFilter == 'Incoming') {
        return t.isCredit;
      } else if (_txnCategoryFilter == 'Outgoing') {
        return !t.isCredit;
      } else if (_txnCategoryFilter == 'Pending') {
        return t.status.toUpperCase() == 'PENDING';
      }
      return true;
    }).toList();
  }

  void _showReceiveMoneyModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.neonPink.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.neonPink, size: 36),
            ),
            const SizedBox(height: 12),
            const Text("Receive Money & IBAN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text("Share your Swiss IBAN or QR code to receive international funds instantly.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Swiss IBAN", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(_user.accountNumber.isNotEmpty ? _user.accountNumber : 'CH8900008730', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("SWIFT / BIC", style: TextStyle(color: Colors.grey, fontSize: 12)), const Text("UBSWCHZH80A", style: TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Account Holder", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(_user.fullName, style: const TextStyle(fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TRANSACTIONS / MAIN DASHBOARD
  // ==========================================
  Widget _buildTransactionsTab() {
    final isBurgundyHeader = _selectedAccountTier == "Joint account";
    final displayedBalance = _getConvertedHeaderBalance();
    final symbol = _getCurrencySymbol(_selectedHeaderCurrency);
    final flag = _currencyFlags[_selectedHeaderCurrency] ?? '🇨🇭';

    final filteredTxns = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header Banner
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
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                      // Account Selector Switcher Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (val) => setState(() => _selectedAccountTier = val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: "Main account", child: Text("Main account (CHF 7'850.42)")),
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
                      // Logout icon
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Account Balance Header with Interactive Currency Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Main Account Balance",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                              child: Text(
                                "$symbol${displayedBalance.toStringAsFixed(2)}",
                                key: ValueKey(_selectedHeaderCurrency),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Interactive Currency Selector Pill
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (code) {
                            setState(() => _selectedHeaderCurrency = code);
                          },
                          itemBuilder: (ctx) => _currencyFlags.keys.map((code) {
                            return PopupMenuItem(
                              value: code,
                              child: Row(
                                children: [
                                  Text(_currencyFlags[code]!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(_selectedHeaderCurrency, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                const Icon(Icons.arrow_drop_down, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedHeaderCurrency == 'CHF'
                        ? "≈ ₹ ${_user.balance.toStringAsFixed(2)} INR • IBAN: ${_user.accountNumber.isNotEmpty ? _user.accountNumber : 'CH8900008730'} • 1 CHF = ₹ ${(_inrToChfRate > 0 ? (1 / _inrToChfRate) : 95.238).toStringAsFixed(2)}"
                        : "≈ CHF ${(_mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate)).toStringAsFixed(2)} • Live FX conversion rate applied",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Enhanced Quick Action Shortcut Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showTransferTypePickerModal,
                          child: _buildHeaderShortcut(Icons.send_rounded, "Transfer"),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PassbookScreen(
                                  accountNumber: _user.accountNumber,
                                  balance: _user.balance,
                                  transactions: _transactions,
                                ),
                              ),
                            );
                          },
                          child: _buildHeaderShortcut(Icons.account_balance_outlined, "Passbook"),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForexExchangeScreen(
                                  baseBalanceChf: _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate),
                                ),
                              ),
                            );
                          },
                          child: _buildHeaderShortcut(Icons.currency_exchange_rounded, "Exchange"),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _showNeonAccountVerificationModal(),
                          child: _buildHeaderShortcut(Icons.speed_rounded, "Send Money"),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: _showReceiveMoneyModal,
                          child: _buildHeaderShortcut(Icons.qr_code_2_rounded, "Receive"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Transactions Section Header & Search/Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TRANSACTIONS FEED",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        "${filteredTxns.length} Activity Items",
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search input
                  TextField(
                    controller: _txnSearchController,
                    decoration: InputDecoration(
                      hintText: "Search transactions by recipient or amount...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                      suffixIcon: _txnSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _txnSearchController.clear();
                                setState(() => _txnSearchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => setState(() => _txnSearchQuery = val),
                  ),

                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Incoming', 'Outgoing', 'Pending'].map((filter) {
                        final isSelected = _txnCategoryFilter == filter;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: AppTheme.neonPink,
                            onSelected: (val) => setState(() => _txnCategoryFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
          else if (filteredTxns.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("No matching transactions found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final txn = filteredTxns[index];
                  final isCredit = txn.isCredit;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentProcessingScreen(
                            responseData: {
                              'transaction_id': txn.transactionId,
                              'utr_id': txn.utrId,
                              'recipient_name': txn.recipientName,
                              'recipient_account': txn.recipientAccount,
                              'amount': txn.amount,
                              'status': txn.status,
                              'created_at': txn.date,
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCredit ? Colors.green[50] : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                              color: isCredit ? AppTheme.successGreen : AppTheme.neonPink,
                              size: 20,
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${txn.date} • ${isCredit ? 'Credit Received' : 'Bank Transfer'}",
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isCredit ? AppTheme.successGreen : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: txn.status.toUpperCase() == 'COMPLETED'
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  txn.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: txn.status.toUpperCase() == 'COMPLETED'
                                        ? Colors.green
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredTxns.length,
              ),
            ),

          // International Finance Services (Compact 3-Column Grid)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "INTERNATIONAL FINANCE SERVICES",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    "Swiss Banking Portal",
                    style: TextStyle(
                      color: AppTheme.neonPink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3-Column Cards Grid (3 per row)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _buildGridServiceCard(
                    icon: Icons.trending_up_rounded,
                    title: "Global\nInvestments",
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalInvestmentsScreen()));
                    },
                  ),
                  _buildGridServiceCard(
                    icon: Icons.public_rounded,
                    title: "Foreign\nAssets",
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForeignAssetsScreen()));
                    },
                  ),
                  _buildGridServiceCard(
                    icon: Icons.currency_exchange_rounded,
                    title: "Forex\nExchange",
                    color: const Color(0xFF00838F),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForexExchangeScreen(
                            baseBalanceChf: _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildGridServiceCard(
                    icon: Icons.account_balance_outlined,
                    title: "Swiss\nLoans",
                    color: const Color(0xFFE65100),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SwissLoansScreen()));
                    },
                  ),
                  _buildGridServiceCard(
                    icon: Icons.flight_takeoff_rounded,
                    title: "Travel\nFinance",
                    color: const Color(0xFF7B1FA2),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelFinanceScreen()));
                    },
                  ),
                  _buildGridServiceCard(
                    icon: Icons.monetization_on_outlined,
                    title: "Precious\nMetals",
                    color: const Color(0xFFF57F17),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PreciousMetalsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildGridServiceCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.darkNavy),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceServiceCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                                    "Neon Bank",
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
                    mode == "P2P" ? "Verify Neon Bank Transfer" : "Verify Bank Transfer",
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

  void _showNeonAccountVerificationModal({String prefilledAccount = '', String prefilledName = ''}) {
    final accCtrl = TextEditingController(text: prefilledAccount);
    bool isVerifying = false;
    bool isVerified = false;
    String verifiedName = prefilledName;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Verify Neon Bank Account",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!isVerified) ...[
                  const Text(
                    "Enter the recipient's Neon Bank Account Number to verify before transferring.",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Neon Bank Account Number",
                      hintText: "e.g. 1001004821",
                      prefixIcon: const Icon(Icons.account_balance_outlined, color: AppTheme.neonPink),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (val) {
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final accNum = accCtrl.text.trim();
                              if (accNum.isEmpty) {
                                setModalState(() => errorMessage = "Please enter an account number.");
                                return;
                              }

                              setModalState(() {
                                isVerifying = true;
                                errorMessage = null;
                              });

                              final res = await ApiService.getUserByAccount(accNum);
                              setModalState(() => isVerifying = false);

                              if (res['success'] == true && res['user'] != null) {
                                setModalState(() {
                                  isVerified = true;
                                  verifiedName = res['user']['full_name'] ?? 'Neon Customer';
                                });
                              } else {
                                setModalState(() {
                                  errorMessage = res['message'] ?? "Account not found. Please check the account number and try again.";
                                });
                              }
                            },
                      child: isVerifying
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("Verify Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Account Verified ✓",
                          style: TextStyle(color: AppTheme.successGreen, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          verifiedName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Neon Bank",
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Account ••••${accCtrl.text.trim().length > 4 ? accCtrl.text.trim().substring(accCtrl.text.trim().length - 4) : accCtrl.text.trim()}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendMoneyScreen(
                              user: _user,
                              beneficiary: {
                                'beneficiary_name': verifiedName,
                                'beneficiary_account_number': accCtrl.text.trim(),
                                'bank_name': 'Neon Bank',
                                'country': 'Switzerland',
                                'currency': 'CHF',
                                'flag': '🇨🇭',
                              },
                              mode: 'P2P',
                            ),
                          ),
                        ).then((_) => _fetchRecentNeonRecipients());
                      },
                      child: const Text("Continue to Send Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 2: PAYMENTS / ZAHLUNGEN
  // ==========================================
  Widget _buildPaymentsTab() {
    final filteredBeneficiaries = _beneficiaries.where((b) {
      final type = (b['type'] ?? '').toString().toUpperCase();
      return type == 'OTHER_BANK';
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          _paymentMode == "P2P" ? "Neon Bank Transfer" : "Other Bank Transfer",
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
            // Segmented Transfer Mode Switcher: Neon Bank vs Other Banks
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
                            Icon(Icons.account_balance_rounded, size: 18, color: _paymentMode == "P2P" ? AppTheme.neonPink : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              "Neon Bank",
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
                            Icon(Icons.public_rounded, size: 18, color: _paymentMode == "P2B" ? AppTheme.neonBlue : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              "Other Banks",
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

            if (_paymentMode == "P2P") ...[
              // Primary Action: Send Money CTA Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonPink, AppTheme.neonBurgundy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.neonPink.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Neon Bank Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                            Text("Instant zero-fee transfer", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Transfer money instantly using the recipient's Neon Bank Account Number.",
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.neonPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => _showNeonAccountVerificationModal(),
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.neonPink),
                        label: const Text("Send Money", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Neon Bank Recipients (Local Storage Only)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Recipients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  Text("${_recentNeonRecipients.length} Recent", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              _recentNeonRecipients.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history_rounded, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No recent Neon Bank recipients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("Recipients from your successful Neon Bank transfers will appear here for fast access.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentNeonRecipients.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final r = _recentNeonRecipients[idx];
                        final name = r['name'] ?? 'Recipient';
                        final masked = r['maskedAccount'] ?? '••••';
                        final accountNumber = r['accountNumber'] ?? '';

                        return InkWell(
                          onTap: () {
                            _showNeonAccountVerificationModal(
                              prefilledAccount: accountNumber,
                              prefilledName: name,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.neonPink.withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'R',
                                    style: const TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text("Neon Bank • Account $masked", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                                  onPressed: () async {
                                    await ApiService.removeRecentNeonRecipient(accountNumber);
                                    _fetchRecentNeonRecipients();
                                  },
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ] else ...[
              // Option B: Other Banks Flow
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
                          Text("Add New Beneficiary", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                          SizedBox(height: 2),
                          Text("Save recipient account or IBAN details", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Bank Beneficiary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  Text("${filteredBeneficiaries.length} Saved", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              filteredBeneficiaries.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 44, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No external bank beneficiaries saved", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("Tap 'Add' above to register a trusted transfer account.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBeneficiaries.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final b = filteredBeneficiaries[idx];
                        final name = b['beneficiary_name'] ?? b['nickname'] ?? 'Recipient';
                        final acc = b['beneficiary_account_number'] ?? '';
                        final bankName = b['bank_name'] ?? b['nickname'] ?? 'State Bank of India';
                        final statusStr = (b['status'] ?? 'APPROVED').toString().toUpperCase();
                        final isApproved = statusStr == 'APPROVED' || statusStr == 'DONE';
                        final currency = b['currency'] ?? 'INR';
                        final country = b['country'] ?? (currency == 'INR' ? 'India' : 'Switzerland');
                        final flag = b['flag'] ?? (country == 'India' ? '🇮🇳' : '🇨🇭');
                        final maskedAcc = acc.length > 4 ? '••••••${acc.substring(acc.length - 4)}' : acc;

                        return InkWell(
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

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SendMoneyScreen(
                                  user: _user,
                                  beneficiary: b,
                                  mode: 'P2B',
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                    style: const TextStyle(color: AppTheme.neonBlue, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary)),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isApproved ? AppTheme.successGreen.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isApproved ? "VERIFIED" : "PENDING",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isApproved ? AppTheme.successGreen : Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text("$bankName • $maskedAcc", style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text("$flag $country • $currency", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: INVEST & GLOBAL MARKETS DASHBOARD
  // ==========================================
  Widget _buildInvestTab() {
    final balanceChf = _user.balance * _inrToChfRate;
    final gainChf = balanceChf * 0.1667;
    final indices = MarketDataService.getGlobalIndices();
    final newsList = MarketDataService.getMarketNews();

    // Filter stocks based on Search Query & Category Filter
    List<StockItemModel> filteredStocks = _allStocks;
    if (_selectedStockCategory == 'Watchlist') {
      filteredStocks = filteredStocks.where((s) => _watchlistSymbols.contains(s.symbol)).toList();
    } else if (_selectedStockCategory != 'All') {
      filteredStocks = filteredStocks.where((s) => s.category == _selectedStockCategory).toList();
    }

    if (_stockSearchQuery.isNotEmpty) {
      final query = _stockSearchQuery.toLowerCase();
      filteredStocks = filteredStocks.where((s) {
        return s.symbol.toLowerCase().contains(query) ||
               s.name.toLowerCase().contains(query) ||
               s.country.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Global Markets & Investing", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkNavy)),
            Text("Swiss Banking Investment Portal", style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.neonPink),
            onPressed: () {
              _fetchExchangeRatesAndStockData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshing global market quotes...")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Rate & Transparency Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonPink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange_rounded, color: AppTheme.neonPink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Live Rate: 1 INR = ${_inrToChfRate.toStringAsFixed(4)} CHF",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Data Source: 🟢 Live Gold Spot API • 🟡 Delayed Market Snapshots",
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Portfolio Performance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Global Portfolio Value", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text("Swiss CHF", style: TextStyle(color: AppTheme.neonPink, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          "CHF ${balanceChf.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "+${gainChf.toStringAsFixed(2)} CHF (+16.67%)",
                            style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Major Global Market Indices (S&P 500, NASDAQ, SMI 20, FTSE, NIFTY)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Major Global Market Indices",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: indices.length,
                itemBuilder: (context, index) {
                  final idx = indices[index];
                  final isPos = idx.changePercent >= 0;
                  return Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(idx.flag, style: const TextStyle(fontSize: 16)),
                            Text(idx.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.darkNavy)),
                          ],
                        ),
                        Text(
                          "${idx.currentPrice.toStringAsFixed(1)}",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        Row(
                          children: [
                            Icon(isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isPos ? AppTheme.successGreen : AppTheme.dangerRed, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${isPos ? '+' : ''}${idx.changePercent.toStringAsFixed(2)}%",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isPos ? AppTheme.successGreen : AppTheme.dangerRed),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Search & Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _stockSearchController,
                  onChanged: (val) => setState(() => _stockSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search US, Swiss, Asian stocks, ETFs or Gold...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neonPink),
                    suffixIcon: _stockSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _stockSearchController.clear();
                              setState(() => _stockSearchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryChip('All', '🌍 All Assets'),
                  _buildCategoryChip('Watchlist', '⭐ Watchlist (${_watchlistSymbols.length})'),
                  _buildCategoryChip('US', '🇺🇸 US Stocks'),
                  _buildCategoryChip('Europe', '🇨🇭 Swiss & Europe'),
                  _buildCategoryChip('Asia', '🌏 Asian Markets'),
                  _buildCategoryChip('ETF', '📊 Global ETFs'),
                  _buildCategoryChip('Commodity', '🥇 Metals & Vaults'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Popular & Trending Stocks List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedStockCategory == 'Watchlist' 
                        ? "Watchlist Assets" 
                        : "Popular Global Stocks (${filteredStocks.length})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                  ),
                  Text(
                    "Real Quotes",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.neonPink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (filteredStocks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        _selectedStockCategory == 'Watchlist' 
                            ? "No stocks in watchlist yet.\nTap the star icon on any stock to add it!"
                            : "No stocks found matching '$_stockSearchQuery'.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredStocks.length,
                itemBuilder: (context, index) {
                  final stock = filteredStocks[index];
                  final isWatchlisted = _watchlistSymbols.contains(stock.symbol);
                  final isPos = stock.changePercent >= 0;
                  final changeColor = isPos ? AppTheme.successGreen : AppTheme.dangerRed;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockDetailsScreen(
                            stock: stock,
                            isWatchlisted: isWatchlisted,
                            onToggleWatchlist: () => _toggleWatchlist(stock.symbol),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                stock.logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    stock.symbol[0],
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.neonPink),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(stock.flag, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      stock.symbol,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.darkNavy),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: stock.dataSourceType == 'LIVE_API' ? Colors.blue[50] : Colors.amber[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stock.dataSourceType == 'LIVE_API' ? 'LIVE' : 'SNAPSHOT',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: stock.dataSourceType == 'LIVE_API' ? Colors.blue[800] : Colors.amber[900]),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stock.name,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${stock.currency} ${stock.price.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.darkNavy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${isPos ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: changeColor),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              isWatchlisted ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isWatchlisted ? Colors.amber : Colors.grey[400],
                              size: 22,
                            ),
                            onPressed: () => _toggleWatchlist(stock.symbol),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Section 4: Foreign Investment Categories Grid
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Foreign Investment Categories",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildInvestmentCategoryCard("🇺🇸 US Tech Stocks", "Apple, Microsoft, Nvidia", Icons.computer_rounded, const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                  _buildInvestmentCategoryCard("🇨🇭 Swiss Dividend Blue", "Nestlé, Roche, UBS", Icons.account_balance_outlined, const Color(0xFFFCE4EC), AppTheme.neonPink),
                  _buildInvestmentCategoryCard("🌏 Asian Growth Leaders", "DBS, Reliance, Singtel", Icons.public_rounded, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  _buildInvestmentCategoryCard("📊 Global Index ETFs", "S&P 500 & Vanguard Swiss", Icons.pie_chart_outline_rounded, const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                  _buildInvestmentCategoryCard("🏛️ Sovereign & Corporate", "Swiss & US Treasury Bonds", Icons.shield_outlined, const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
                  _buildInvestmentCategoryCard("🥇 Zurich Gold Vaults", "Allocated Physical Bullion", Icons.monetization_on_outlined, const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 5: Market News & Financial Analysis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Global Financial News",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                  ),
                  Text("Live Feed", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.neonPink)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            news.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.newspaper_rounded, color: AppTheme.neonPink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonPink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    news.category,
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.neonPink),
                                  ),
                                ),
                                Text(
                                  news.time,
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              news.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.darkNavy, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              news.source,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Educational Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.neonPink, AppTheme.neonBurgundy]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.neonPink.withOpacity(0.25), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Swiss Investment Academy",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Learn how to manage FX risk & build a tax-efficient multi-currency portfolio.",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedStockCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedStockCategory = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.darkNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.darkNavy : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppTheme.darkNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentCategoryCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: SPACES DASHBOARD (Redesigned)
  // ==========================================
  Widget _buildSpacesTab() {
    final mainChf = _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate);
    final mainInr = _mainBalanceInr > 0 ? _mainBalanceInr : _user.balance;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Swiss Spaces & Vaults", style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchSpaces();
              _fetchData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchSpaces();
          await _fetchData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Primary Main Account Balance in CHF
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text("🇨🇭", style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text(
                              "MAIN SWISS ACCOUNT",
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "FINMA Protected",
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "CHF ${mainChf.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_exchange_rounded, color: Colors.white60, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            "Secondary Balance: ₹ ${mainInr.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Header & Add Space Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Your Financial Spaces",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Organize funds into dedicated goal vaults",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showCreateSpaceModal,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    label: const Text("New Space", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Spaces List or Empty Onboarding State
              _isLoadingSpaces
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _spaces.isEmpty
                      ? _buildEmptySpacesOnboardingCard()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _spaces.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                          itemBuilder: (ctx, i) => _buildSpaceCardItem(_spaces[i]),
                        ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySpacesOnboardingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.neonPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.neonPink),
          ),
          const SizedBox(height: 16),
          const Text(
            "Organize your money",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create dedicated Spaces for travel, emergency funds, tax reserves, investments and custom targets.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _showCreateSpaceModal,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            label: const Text(
              "+ Create your first Space",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCardItem(SpaceModel space) {
    final themeColor = _parseColorHex(space.colorHex);
    final progress = space.progressPercentage;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpaceDetailsScreen(
              space: space,
              appId: _user.appId,
              sessionId: _user.sessionId,
              mainBalanceChf: _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate),
              onSpaceUpdated: _fetchSpaces,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getSpaceIcon(space.iconKey), color: themeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        space.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonPink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpaceDetailsScreen(
                          space: space,
                          appId: _user.appId,
                          sessionId: _user.sessionId,
                          mainBalanceChf: _mainBalanceChf > 0 ? _mainBalanceChf : (_user.balance * _inrToChfRate),
                          onSpaceUpdated: _fetchSpaces,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${space.currency} ${space.balance.toStringAsFixed(2)}",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: themeColor),
                ),
                if (space.targetAmount != null && space.targetAmount! > 0)
                  Text(
                    "Target: ${space.currency} ${space.targetAmount!.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            if (space.targetAmount != null && space.targetAmount! > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${progress.toStringAsFixed(0)}% completed",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor),
                  ),
                  if (space.targetDate != null && space.targetDate!.isNotEmpty)
                    Text(
                      "Target: ${space.targetDate}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getSpaceIcon(String key) {
    switch (key.toLowerCase()) {
      case 'travel':
      case 'holiday':
        return Icons.flight_takeoff_rounded;
      case 'emergency':
        return Icons.shield_rounded;
      case 'investment':
      case 'investments':
        return Icons.trending_up_rounded;
      case 'tax':
      case 'taxes':
        return Icons.receipt_long_rounded;
      case 'home':
      case 'property':
        return Icons.home_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'healthcare':
      case 'health':
        return Icons.medical_services_rounded;
      case 'business':
        return Icons.business_center_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Color _parseColorHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppTheme.neonPink;
    }
  }

  void _checkMpinStatusAndPrompt() {
    if (!_user.hasMpin && !_hasShownMpinPopup) {
      _hasShownMpinPopup = true;
      _showMpinSetupReminderModal();
    }
  }

  void _showMpinSetupReminderModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.neonPink, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              "Create Your Transaction MPIN",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.darkNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Protect your transfers, payouts, and multi-currency operations with a secure 6-digit transaction MPIN.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCreateMpinModal();
                },
                child: const Text("Create MPIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Later", style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMpinModal() {
    final pinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _user.hasMpin ? "Change Transaction MPIN" : "Create Transaction MPIN",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkNavy),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter a 6-digit Security MPIN for authorizing payments and payouts.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                const Text("New 6-Digit MPIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••••",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                const Text("Confirm 6-Digit MPIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••••",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final p1 = pinCtrl.text.trim();
                            final p2 = confirmPinCtrl.text.trim();

                            if (p1.length < 6 || !RegExp(r'^\d{6}$').hasMatch(p1)) {
                              setModalState(() => errorMessage = "MPIN must be exactly 6 numeric digits.");
                              return;
                            }
                            if (p1 != p2) {
                              setModalState(() => errorMessage = "MPINs do not match. Please re-enter.");
                              return;
                            }

                            setModalState(() {
                              isSubmitting = true;
                              errorMessage = null;
                            });

                            final res = await ApiService.createMpin(
                              mpin: p1,
                              sessionId: _user.sessionId,
                              appId: _user.appId,
                            );

                            setModalState(() => isSubmitting = false);

                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              await _fetchData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Transaction MPIN Created ✓ Your transaction security is enabled."),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              setModalState(() => errorMessage = res['message'] ?? "Failed to set MPIN.");
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Transaction MPIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSpaceModal() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final initialCtrl = TextEditingController();

    String selectedCategory = 'Holiday / Travel';
    String selectedIconKey = 'travel';
    String selectedCurrency = 'CHF';
    String selectedColor = '#E91E63';

    final categories = [
      {'name': 'Holiday / Travel', 'icon': 'travel', 'color': '#EC4899'},
      {'name': 'Emergency Fund', 'icon': 'emergency', 'color': '#EF4444'},
      {'name': 'Investments', 'icon': 'investment', 'color': '#10B981'},
      {'name': 'Taxes', 'icon': 'tax', 'color': '#F59E0B'},
      {'name': 'Education', 'icon': 'education', 'color': '#6366F1'},
      {'name': 'Property', 'icon': 'home', 'color': '#8B5CF6'},
      {'name': 'Healthcare', 'icon': 'healthcare', 'color': '#14B8A6'},
      {'name': 'Business', 'icon': 'business', 'color': '#0EA5E9'},
      {'name': 'Custom Space', 'icon': 'custom', 'color': '#64748B'},
    ];

    final currencies = ['CHF', 'EUR', 'USD', 'GBP', 'INR', 'SGD', 'AED', 'CAD', 'AUD'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Create New Space", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Choose Space Purpose", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      final item = categories[i];
                      final isSelected = selectedCategory == item['name'];
                      return ChoiceChip(
                        label: Text(item['name']!),
                        selected: isSelected,
                        selectedColor: AppTheme.neonPink,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setModalState(() {
                            selectedCategory = item['name']!;
                            selectedIconKey = item['icon']!;
                            selectedColor = item['color']!;
                            if (nameCtrl.text.isEmpty) {
                              nameCtrl.text = item['name']!;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Space Name",
                    hintText: "e.g. Swiss Alps Trip",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: targetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Target Amount",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: InputDecoration(
                          labelText: "Currency",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setModalState(() => selectedCurrency = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(
                    labelText: "Target Date (Optional)",
                    hintText: "e.g. 15 Dec 2026",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: initialCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Initial Deposit (Optional)",
                    hintText: "Deducted from Main Account",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a space name")),
                        );
                        return;
                      }

                      final targetAmt = double.tryParse(targetCtrl.text.trim());
                      final date = dateCtrl.text.trim();
                      final initialAmt = double.tryParse(initialCtrl.text.trim()) ?? 0.0;

                      Navigator.pop(ctx);
                      setState(() => _isLoadingSpaces = true);

                      final res = await ApiService.createSpace(
                        appId: _user.appId,
                        name: name,
                        category: selectedCategory,
                        iconKey: selectedIconKey,
                        currency: selectedCurrency,
                        targetAmount: targetAmt,
                        targetDate: date,
                        initialAmount: initialAmt,
                        colorHex: selectedColor,
                        sessionId: _user.sessionId,
                      );

                      if (mounted) {
                        if (res['success'] == true) {
                          await _fetchSpaces();
                          await _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("New Space created successfully!")),
                          );
                        } else {
                          setState(() => _isLoadingSpaces = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to create Space')),
                          );
                        }
                      }
                    },
                    child: const Text("Create Space", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 5: PROFILE SCREEN (International Banking Center)
  // ==========================================
  Widget _buildProfileTab() {
    return BankingProfileCenterScreen(
      user: _user,
      onOpenMpinModal: _showCreateMpinModal,
      onProfileUpdated: () async {
        final updated = await ApiService.getUserDetails(_user.appId, sessionId: _user.sessionId);
        if (updated != null && mounted) {
          setState(() => _user = updated);
        }
      },
    );
  }
}
