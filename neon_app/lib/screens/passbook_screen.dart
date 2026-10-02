import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';

class PassbookScreen extends StatefulWidget {
  final String accountNumber;
  final double balance;
  final List<TransactionModel> transactions;

  const PassbookScreen({
    super.key,
    required this.accountNumber,
    required this.balance,
    required this.transactions,
  });

  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> {
  String _filterType = "ALL"; // ALL, DEBIT, CREDIT

  @override
  Widget build(BuildContext context) {
    final filteredTxns = widget.transactions.where((txn) {
      if (_filterType == "CREDIT") return txn.isCredit;
      if (_filterType == "DEBIT") return !txn.isCredit;
      return true;
    }).toList();

    double totalCredit = 0.0;
    double totalDebit = 0.0;
    for (var txn in widget.transactions) {
      if (txn.isCredit) {
        totalCredit += txn.amount;
      } else {
        totalDebit += txn.amount;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Digital Passbook", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: CustomScrollView(
        slivers: [
          // Account Summary Header Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.neonPink, AppTheme.neonBurgundy]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonPink.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "NEON ACCOUNT PASSBOOK",
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("ACTIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "₹ ${widget.balance.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "A/C: ${widget.accountNumber.isNotEmpty ? widget.accountNumber : 'CH8900008730'} • IFSC: NEON0001",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Credits (+)", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text("₹ ${totalCredit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Total Debits (-)", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text("₹ ${totalDebit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter Segment Tabs (ALL, CREDIT, DEBIT)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildFilterChip("ALL", "All Logs"),
                    _buildFilterChip("CREDIT", "Credits (+)"),
                    _buildFilterChip("DEBIT", "Debits (-)"),
                  ],
                ),
              ),
            ),
          ),

          // Passbook Transaction Ledger Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "STATEMENT ENTRIES",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  Text(
                    "${filteredTxns.length} Records",
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // Passbook Ledger Entries List
          if (filteredTxns.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text("No transactions recorded for this filter.", style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final txn = filteredTxns[index];
                  final isCredit = txn.isCredit;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
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
                            color: isCredit ? AppTheme.successGreen.withValues(alpha: 0.12) : AppTheme.dangerRed.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: isCredit ? AppTheme.successGreen : AppTheme.dangerRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.recipientName.isNotEmpty ? txn.recipientName : (isCredit ? "Deposit Received" : "Money Transferred"),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                txn.date,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isCredit ? '+' : '-'} ₹ ${txn.amount.toStringAsFixed(2)}",
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
                      ],
                    ),
                  );
                },
                childCount: filteredTxns.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
}
