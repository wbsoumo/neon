import 'package:flutter/material.dart';
import '../models/space_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SpaceDetailsScreen extends StatefulWidget {
  final SpaceModel space;
  final String appId;
  final String sessionId;
  final double mainBalanceChf;
  final Function() onSpaceUpdated;

  const SpaceDetailsScreen({
    super.key,
    required this.space,
    required this.appId,
    required this.sessionId,
    required this.mainBalanceChf,
    required this.onSpaceUpdated,
  });

  @override
  State<SpaceDetailsScreen> createState() => _SpaceDetailsScreenState();
}

class _SpaceDetailsScreenState extends State<SpaceDetailsScreen> {
  late SpaceModel _currentSpace;
  List<SpaceTransactionModel> _transactions = [];
  bool _isLoadingTxs = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentSpace = widget.space;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTxs = true);
    final res = await ApiService.fetchSpaceTransactions(
      appId: widget.appId,
      spaceId: _currentSpace.spaceId,
      sessionId: widget.sessionId,
    );

    if (mounted) {
      if (res['success'] == true && res['transactions'] != null) {
        final List list = res['transactions'];
        setState(() {
          _transactions = list.map((x) => SpaceTransactionModel.fromJson(x)).toList();
          _isLoadingTxs = false;
        });
      } else {
        setState(() => _isLoadingTxs = false);
      }
    }
  }

  IconData _getIconData(String key) {
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

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppTheme.neonPink;
    }
  }

  void _showAddMoneyModal() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
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
                Text(
                  "Add Money to ${_currentSpace.name}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.neonPink),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Source Account", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        "Main CHF Account (Bal: CHF ${widget.mainBalanceChf.toStringAsFixed(2)})",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount (${_currentSpace.currency})",
                prefixText: "${_currentSpace.currency} ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter a valid amount")),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _executeTransfer('ADD', amt);
                      },
                child: const Text("Confirm Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawMoneyModal() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
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
                Text(
                  "Withdraw from ${_currentSpace.name}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.outbox_rounded, color: Colors.orange),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Destination Account", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const Text(
                        "Main Swiss Account (CHF)",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount (${_currentSpace.currency})",
                prefixText: "${_currentSpace.currency} ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: "Available in space: ${_currentSpace.currency} ${_currentSpace.balance.toStringAsFixed(2)}",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter a valid amount")),
                          );
                          return;
                        }
                        if (amt > _currentSpace.balance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Insufficient funds in this space")),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _executeTransfer('WITHDRAW', amt);
                      },
                child: const Text("Confirm Withdrawal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeTransfer(String type, double amount) async {
    setState(() => _isProcessing = true);
    final res = await ApiService.transferSpaceMoney(
      appId: widget.appId,
      spaceId: _currentSpace.spaceId,
      type: type,
      amount: amount,
      sessionId: widget.sessionId,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (res['success'] == true) {
        final newBal = (res['new_space_balance'] as num).toDouble();
        setState(() {
          _currentSpace = SpaceModel(
            spaceId: _currentSpace.spaceId,
            appId: _currentSpace.appId,
            name: _currentSpace.name,
            category: _currentSpace.category,
            iconKey: _currentSpace.iconKey,
            currency: _currentSpace.currency,
            balance: newBal,
            targetAmount: _currentSpace.targetAmount,
            targetDate: _currentSpace.targetDate,
            colorHex: _currentSpace.colorHex,
            allocationType: _currentSpace.allocationType,
            allocationValue: _currentSpace.allocationValue,
            createdAt: _currentSpace.createdAt,
          );
        });
        _loadTransactions();
        widget.onSpaceUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Transaction completed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to execute transfer')),
        );
      }
    }
  }

  void _showEditModal() {
    final nameCtrl = TextEditingController(text: _currentSpace.name);
    final targetCtrl = TextEditingController(
      text: _currentSpace.targetAmount != null ? _currentSpace.targetAmount!.toStringAsFixed(2) : '',
    );
    final dateCtrl = TextEditingController(text: _currentSpace.targetDate ?? '');

    String allocType = _currentSpace.allocationType;
    final allocValCtrl = TextEditingController(
      text: _currentSpace.allocationValue > 0 ? _currentSpace.allocationValue.toString() : '',
    );

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit ${_currentSpace.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Space Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Target Amount (${_currentSpace.currency})",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: "Target Date (e.g. 15 Dec 2026)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Automatic Monthly Allocation Rule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: allocType,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'NONE', child: Text("No Auto Allocation")),
                  DropdownMenuItem(value: 'FIXED_MONTHLY', child: Text("Fixed Monthly Amount")),
                  DropdownMenuItem(value: 'PERCENTAGE_INCOMING', child: Text("Percentage of Deposit")),
                ],
                onChanged: (val) => setModalState(() => allocType = val!),
              ),
              if (allocType != 'NONE') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: allocValCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: allocType == 'PERCENTAGE_INCOMING' ? "Percentage (%)" : "Fixed Amount (${_currentSpace.currency})",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = nameCtrl.text.trim();
                    final newTarget = double.tryParse(targetCtrl.text.trim());
                    final newDate = dateCtrl.text.trim();
                    final newAllocVal = double.tryParse(allocValCtrl.text.trim()) ?? 0.0;

                    if (newName.isEmpty) return;

                    Navigator.pop(ctx);
                    setState(() => _isProcessing = true);

                    final res = await ApiService.updateSpace(
                      appId: widget.appId,
                      spaceId: _currentSpace.spaceId,
                      name: newName,
                      targetAmount: newTarget,
                      targetDate: newDate,
                      allocationType: allocType,
                      allocationValue: newAllocVal,
                      sessionId: widget.sessionId,
                    );

                    if (mounted) {
                      setState(() => _isProcessing = false);
                      if (res['success'] == true) {
                        setState(() {
                          _currentSpace = SpaceModel(
                            spaceId: _currentSpace.spaceId,
                            appId: _currentSpace.appId,
                            name: newName,
                            category: _currentSpace.category,
                            iconKey: _currentSpace.iconKey,
                            currency: _currentSpace.currency,
                            balance: _currentSpace.balance,
                            targetAmount: newTarget,
                            targetDate: newDate,
                            colorHex: _currentSpace.colorHex,
                            allocationType: allocType,
                            allocationValue: newAllocVal,
                            createdAt: _currentSpace.createdAt,
                          );
                        });
                        widget.onSpaceUpdated();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Space settings saved successfully")),
                        );
                      }
                    }
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Space?"),
        content: Text("Are you sure you want to delete '${_currentSpace.name}'? Any remaining funds (${_currentSpace.currency} ${_currentSpace.balance.toStringAsFixed(2)}) will automatically be returned to your Main Account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final res = await ApiService.deleteSpace(
                appId: widget.appId,
                spaceId: _currentSpace.spaceId,
                sessionId: widget.sessionId,
              );
              if (mounted) {
                if (res['success'] == true) {
                  widget.onSpaceUpdated();
                  Navigator.pop(context); // close details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Space deleted successfully")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(_currentSpace.colorHex);
    final progress = _currentSpace.progressPercentage;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_currentSpace.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showEditModal),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: _confirmDelete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Space Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIconData(_currentSpace.iconKey), color: Colors.white, size: 30),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentSpace.category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Saved Balance", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    "${_currentSpace.currency} ${_currentSpace.balance.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  if (_currentSpace.targetAmount != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${progress.toStringAsFixed(0)}% of ${_currentSpace.currency} ${_currentSpace.targetAmount!.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Remaining: ${_currentSpace.currency} ${_currentSpace.amountRemaining.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (_currentSpace.targetDate != null && _currentSpace.targetDate!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Target Date: ${_currentSpace.targetDate}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions (Add & Withdraw)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _showAddMoneyModal,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                    label: const Text("Add Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.orange[800]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _showWithdrawMoneyModal,
                    icon: Icon(Icons.outbox_rounded, color: Colors.orange[800]),
                    label: Text("Withdraw", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Allocation Rule Summary
            if (_currentSpace.allocationType != 'NONE') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew_rounded, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Automatic Allocation Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                          Text(
                            _currentSpace.allocationType == 'PERCENTAGE_INCOMING'
                                ? "Auto transfers ${_currentSpace.allocationValue}% of all incoming deposits."
                                : "Auto transfers ${_currentSpace.currency} ${_currentSpace.allocationValue} monthly.",
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Transaction History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Activity History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTransactions),
              ],
            ),
            const SizedBox(height: 10),

            _isLoadingTxs
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("No space activity recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final tx = _transactions[i];
                          final isAdd = tx.type == 'ADD';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isAdd ? Colors.green[50] : Colors.orange[50],
                                  child: Icon(
                                    isAdd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isAdd ? Colors.green : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.sourceDest,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.createdAt,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${isAdd ? '+' : '-'} ${tx.currency} ${tx.amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isAdd ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
