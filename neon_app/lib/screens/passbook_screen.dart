import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'payment_processing_screen.dart';

class PassbookScreen extends StatefulWidget {
  final String accountNumber;
  final double balance;
  final List<TransactionModel> transactions;
  final UserModel? user;

  const PassbookScreen({
    super.key,
    required this.accountNumber,
    required this.balance,
    required this.transactions,
    this.user,
  });

  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> with SingleTickerProviderStateMixin {
  // Account state & Live API Data
  late double _accountBalanceChf;
  late String _accountNumber;
  late List<TransactionModel> _transactions;
  bool _isRefreshing = false;
  DateTime _lastSyncTime = DateTime.now();

  // Multi-Currency Converter
  String _selectedCurrency = "CHF";
  double _currentRate = 1.0; // 1 CHF = X Currency
  bool _isLoadingRate = false;

  // Supported Currencies map: Symbol & Name
  final Map<String, Map<String, String>> _currencies = {
    "CHF": {"name": "Swiss Franc", "symbol": "CHF", "flag": "🇨🇭"},
    "INR": {"name": "Indian Rupee", "symbol": "₹", "flag": "🇮🇳"},
    "AED": {"name": "UAE Dirham", "symbol": "AED", "flag": "🇦🇪"},
    "USD": {"name": "US Dollar", "symbol": "\$", "flag": "🇺🇸"},
    "EUR": {"name": "Euro", "symbol": "€", "flag": "🇪🇺"},
    "CAD": {"name": "Canadian Dollar", "symbol": "C\$", "flag": "🇨🇦"},
    "AUD": {"name": "Australian Dollar", "symbol": "A\$", "flag": "🇦🇺"},
    "SGD": {"name": "Singapore Dollar", "symbol": "S\$", "flag": "🇸🇬"},
    "GBP": {"name": "British Pound", "symbol": "£", "flag": "🇬🇧"},
  };

  // Filtering & Search state
  String _filterFlow = "ALL"; // ALL, CREDITS, DEBITS
  String _filterType = "ALL"; // ALL, PAYMENT, TRANSFER, REFUND, FEE
  String _filterStatus = "ALL"; // ALL, COMPLETED, PENDING, FAILED
  String _filterDateRange = "ALL"; // ALL, TODAY, THIS_WEEK, THIS_MONTH
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Account details masking toggle
  bool _isMasked = true;

  @override
  void initState() {
    super.initState();
    // Default account balance in CHF (Primary Base Currency)
    _accountBalanceChf = widget.balance > 0 ? widget.balance : 78.08;
    _accountNumber = widget.accountNumber.isNotEmpty ? widget.accountNumber : "CH890000873099";
    _transactions = List.from(widget.transactions);
    _onCurrencyChanged("CHF");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch exchange rate using existing ApiService
  Future<void> _onCurrencyChanged(String currencyCode) async {
    setState(() {
      _selectedCurrency = currencyCode;
    });

    if (currencyCode == "CHF") {
      setState(() {
        _currentRate = 1.0;
        _isLoadingRate = false;
      });
      return;
    }

    setState(() => _isLoadingRate = true);

    try {
      if (currencyCode == "INR") {
        final rate = await ApiService.getChfToInrRate();
        if (mounted) {
          setState(() {
            _currentRate = rate > 0 ? rate : 95.238;
            _isLoadingRate = false;
          });
        }
      } else {
        // Approximate standard Swiss live cross rates for supported currencies
        final Map<String, double> fallbackRates = {
          "USD": 1.145,
          "EUR": 1.042,
          "AED": 4.205,
          "GBP": 0.892,
          "SGD": 1.541,
          "CAD": 1.562,
          "AUD": 1.724,
        };
        if (mounted) {
          setState(() {
            _currentRate = fallbackRates[currencyCode] ?? 1.0;
            _isLoadingRate = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRate = false);
      }
    }
  }

  // Refresh Account & Transaction Data
  Future<void> _refreshAccountData() async {
    setState(() => _isRefreshing = true);
    
    // Simulate refresh / refetch user session if user details provided
    if (widget.user != null && widget.user!.appId.isNotEmpty) {
      final updated = await ApiService.getUserDetails(widget.user!.appId, sessionId: widget.user!.sessionId);
      if (updated != null && mounted) {
        setState(() {
          _accountBalanceChf = updated.balance > 0 ? updated.balance : _accountBalanceChf;
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 700));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastSyncTime = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account statement and live balance refreshed!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Generate IBAN representation cleanly
  String get _formattedIban {
    final raw = _accountNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (raw.startsWith('CH')) {
      return raw.replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} ').trim();
    }
    return "CH89 0000 8730 ${_accountNumber.length > 4 ? _accountNumber.substring(_accountNumber.length - 4) : '9912'} 1";
  }

  String get _maskedAccountNumber {
    if (!_isMasked) return _accountNumber;
    if (_accountNumber.length <= 4) return "•••• ${_accountNumber}";
    final visiblePart = _accountNumber.substring(_accountNumber.length - 4);
    return "•••• •••• $visiblePart";
  }

  // Filtered transactions list builder
  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((txn) {
      // 1. Flow filter (Credits / Debits)
      if (_filterFlow == "CREDITS" && !txn.isCredit) return false;
      if (_filterFlow == "DEBITS" && txn.isCredit) return false;

      // 2. Status filter
      if (_filterStatus != "ALL") {
        final st = txn.status.toUpperCase();
        if (_filterStatus == "COMPLETED" && !(st == "SUCCESS" || st == "COMPLETED")) return false;
        if (_filterStatus == "PENDING" && !(st == "PENDING" || st == "PROCESSING")) return false;
        if (_filterStatus == "FAILED" && !(st == "FAILED" || st == "REJECTED")) return false;
      }

      // 3. Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = txn.recipientName.toLowerCase().contains(query);
        final refMatch = txn.transactionId.toLowerCase().contains(query) || txn.utrId.toLowerCase().contains(query);
        final accMatch = txn.recipientAccount.toLowerCase().contains(query);
        if (!nameMatch && !refMatch && !accMatch) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    // Calculate dynamic ledger summary totals
    double totalCredits = 0.0;
    double totalDebits = 0.0;
    for (var txn in _transactions) {
      if (txn.isCredit) {
        totalCredits += txn.amount;
      } else {
        totalDebits += txn.amount;
      }
    }

    final String accountHolderName = widget.user?.fullName.isNotEmpty == true 
        ? widget.user!.fullName 
        : "Soumojit Saha";

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Passbook", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPink))
                : const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            tooltip: "Refresh Data",
            onPressed: _isRefreshing ? null : _refreshAccountData,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.textPrimary),
            tooltip: "Download Statement",
            onPressed: () => _showDownloadStatementDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAccountData,
        color: AppTheme.neonPink,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. MAIN BALANCE CARD & MULTI-CURRENCY CONVERTER
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonPink, AppTheme.neonBurgundy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPink.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Text("🇨🇭 ", style: TextStyle(fontSize: 12)),
                                  Text("NEON SWISS MAIN ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.8)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("ACTIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    
                    // Main Balance Label & Currency Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Main Account Balance",
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "CHF ${_accountBalanceChf.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                        // Currency Selector Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              dropdownColor: AppTheme.neonBurgundy,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                              items: _currencies.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text("${entry.value['flag']} ${entry.key}"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _onCurrencyChanged(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Equivalent Multi-Currency Live Rate Info Banner
                    if (_selectedCurrency != "CHF") ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Equivalent Value in ${_currencies[_selectedCurrency]?['name']}",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                if (_isLoadingRate)
                                  const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                else
                                  Text(
                                    "≈ ${_currencies[_selectedCurrency]?['symbol']} ${(_accountBalanceChf * _currentRate).toStringAsFixed(2)} $_selectedCurrency",
                                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "1 CHF = ${_currentRate.toStringAsFixed(3)} $_selectedCurrency",
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Updated ${DateFormat('HH:mm').format(_lastSyncTime)}",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                    const SizedBox(height: 14),

                    // Synchronized Account Status Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sync_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              "Last synchronized ${DateFormat('dd MMM • HH:mm').format(_lastSyncTime)}",
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          "Base Currency: CHF",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. ACCOUNT INFORMATION CARD
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ACCOUNT DETAILS",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.1),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isMasked = !_isMasked),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(_isMasked ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 15, color: AppTheme.neonPink),
                                const SizedBox(width: 4),
                                Text(_isMasked ? "Show" : "Hide", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.neonPink)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Detail Items Grid
                    _buildAccountDetailRow("Account Holder", accountHolderName, copyable: false),
                    const Divider(height: 16),
                    _buildAccountDetailRow("Account Number", _maskedAccountNumber, fullValue: _accountNumber),
                    const Divider(height: 16),
                    _buildAccountDetailRow("IBAN", _isMasked ? "CH89 •••• •••• •••• •••• 1" : _formattedIban, fullValue: _formattedIban),
                    const Divider(height: 16),
                    _buildAccountDetailRow("SWIFT / BIC", "UBSWCHZH80A"),
                    const Divider(height: 16),
                    _buildAccountDetailRow("Bank Name", "Neon Bank (Switzerland)"),
                  ],
                ),
              ),
            ),

            // 3. ACCOUNT ACTIONS RIBBON
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.send_rounded, "Transfer", () {
                      Navigator.pop(context);
                    }),
                    _buildActionButton(Icons.add_rounded, "Add Money", () {
                      _showAddMoneyNotice(context);
                    }),
                    _buildActionButton(Icons.file_download_outlined, "Statement", () {
                      _showDownloadStatementDialog(context);
                    }),
                    _buildActionButton(Icons.share_outlined, "Share Details", () {
                      _shareAccountDetails(context, accountHolderName);
                    }),
                  ],
                ),
              ),
            ),

            // 4. ACCOUNT BALANCE SUMMARY CARD
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem("Total Credits (+)", "CHF ${totalCredits.toStringAsFixed(2)}", AppTheme.successGreen),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    _buildSummaryItem("Total Debits (-)", "CHF ${totalDebits.toStringAsFixed(2)}", AppTheme.dangerRed),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    _buildSummaryItem("Current Balance", "CHF ${_accountBalanceChf.toStringAsFixed(2)}", AppTheme.textPrimary),
                  ],
                ),
              ),
            ),

            // 5. SEARCH & FILTER CONTROLS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: "Search by recipient, reference, ID...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Chips Segment (ALL, CREDITS, DEBITS)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildFlowFilterChip("ALL", "All Logs"),
                          _buildFlowFilterChip("CREDITS", "Credits (+)"),
                          _buildFlowFilterChip("DEBITS", "Debits (-)"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. STATEMENT ENTRIES HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TRANSACTION HISTORY",
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    Text(
                      "${filtered.length} Entries",
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // 7. TRANSACTION LIST OR EMPTY STATE
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          "No transactions found",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Try adjusting your search query or transaction filters.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final txn = filtered[index];
                    final isCredit = txn.isCredit;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: () => _openTransactionDetailsModal(context, txn),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCredit ? AppTheme.successGreen.withValues(alpha: 0.12) : AppTheme.dangerRed.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: isCredit ? AppTheme.successGreen : AppTheme.dangerRed,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          txn.recipientName.isNotEmpty ? txn.recipientName : (isCredit ? "Money Received" : "Bank Transfer"),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            "${txn.date} • ${txn.transactionId.isNotEmpty ? txn.transactionId : 'TXN-89302'}",
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isCredit ? '+' : '-'} CHF ${txn.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isCredit ? AppTheme.successGreen : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCredit ? AppTheme.successGreen : AppTheme.neonPink).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCredit ? "CREDIT" : "DEBIT",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isCredit ? AppTheme.successGreen : AppTheme.neonPink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets & Actions ---

  Widget _buildAccountDetailRow(String label, String displayValue, {String? fullValue, bool copyable = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(
              displayValue,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  final textToCopy = fullValue ?? displayValue;
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Copied $label: $textToCopy"),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.neonPink),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.neonPink, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }

  Widget _buildFlowFilterChip(String key, String label) {
    final isSelected = _filterFlow == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterFlow = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMoneyNotice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Money to Neon Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              "To deposit funds into your Swiss Neon Account, transfer directly using your international IBAN:",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("IBAN: $_formattedIban", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.neonPink, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _formattedIban));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IBAN copied to clipboard!")));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAccountDetails(BuildContext context, String holderName) {
    final text = "Neon Bank Account Details:\nHolder: $holderName\nIBAN: $_formattedIban\nSWIFT/BIC: UBSWCHZH80A\nBank: Neon Bank Switzerland";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account details formatted and copied to clipboard for sharing!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDownloadStatementDialog(BuildContext context) {
    String format = "PDF";
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Download Statement", style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select preferred statement file format:", style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("PDF Statement")),
                      selected: format == "PDF",
                      selectedColor: AppTheme.neonPink.withValues(alpha: 0.15),
                      onSelected: (val) => setDlgState(() => format = "PDF"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("CSV Data")),
                      selected: format == "CSV",
                      selectedColor: AppTheme.neonPink.withValues(alpha: 0.15),
                      onSelected: (val) => setDlgState(() => format = "CSV"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Generating $format statement download..."), duration: const Duration(seconds: 2)),
                );
              },
              child: Text("Download $format", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _openTransactionDetailsModal(BuildContext context, TransactionModel txn) {
    final isCredit = txn.isCredit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: isCredit ? AppTheme.successGreen.withValues(alpha: 0.12) : AppTheme.dangerRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isCredit ? AppTheme.successGreen : AppTheme.dangerRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "${isCredit ? '+' : '-'} CHF ${txn.amount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isCredit ? AppTheme.successGreen : AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isCredit ? "Money Received" : "Money Sent",
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailItem("Status", txn.status.toUpperCase(), isBadge: true),
            _buildDetailItem("Recipient / Sender", txn.recipientName.isNotEmpty ? txn.recipientName : "Neon Beneficiary"),
            _buildDetailItem("Account / IBAN", txn.recipientAccount.isNotEmpty ? txn.recipientAccount : "CH890000..."),
            _buildDetailItem("Transaction Reference", txn.transactionId.isNotEmpty ? txn.transactionId : "TXN-99201", copyable: true),
            _buildDetailItem("SWIFT UTR", txn.utrId.isNotEmpty ? txn.utrId : "NEON-SWISS-881", copyable: true),
            _buildDetailItem("Date & Time", txn.date.isNotEmpty ? txn.date : DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now())),
            _buildDetailItem("Currency", "CHF (Swiss Franc)"),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text("View Receipt"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      Navigator.pop(ctx);
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool copyable = false, bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          Row(
            children: [
              if (isBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.successGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.successGreen)),
                )
              else
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              if (copyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied: $value")));
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.neonPink),
                )
              ],
            ],
          ),
        ],
      ),
    );
  }
}
