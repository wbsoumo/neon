import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'payment_processing_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> beneficiary;
  final String mode; // "P2P" (Neon Bank) or "P2B" (Other Banks)

  const SendMoneyScreen({
    super.key,
    required this.user,
    required this.beneficiary,
    required this.mode,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isReviewing = false;
  bool _isProcessing = false;

  late String _recipientName;
  late String _bankName;
  late String _accountNumber;
  late String _ifscCode;
  late String _country;
  late String _flag;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final b = widget.beneficiary;
    _recipientName = b['beneficiary_name'] ?? b['nickname'] ?? 'Recipient';
    _bankName = b['bank_name'] ?? b['nickname'] ?? (widget.mode == 'P2P' ? 'Neon Bank' : 'External Bank');
    _accountNumber = b['beneficiary_account_number'] ?? '';
    _ifscCode = b['ifsc_code'] ?? '';
    _country = b['country'] ?? (b['currency'] == 'INR' ? 'India' : 'Switzerland');
    _flag = b['flag'] ?? (_country == 'India' ? '🇮🇳' : '🇨🇭');
    _currency = b['currency'] ?? 'INR';
  }

  String get _maskedAccount {
    if (_accountNumber.length <= 4) return _accountNumber;
    final last4 = _accountNumber.substring(_accountNumber.length - 4);
    return '••••••••$last4';
  }

  void _proceedToReview() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid transfer amount.")),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transfer amount must be greater than zero.")),
      );
      return;
    }

    if (widget.user.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient balance! Available: ₹ ${widget.user.balance.toStringAsFixed(2)}"),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isReviewing = true);
  }

  void _showMpinVerificationModal(double amount) {
    final pinControllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());

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
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppTheme.neonPink, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              "Security MPIN Authorization",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              "Authorize transfer of $_currency ${amount.toStringAsFixed(2)} to $_recipientName",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: pinControllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        focusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final enteredPin = pinControllers.map((c) => c.text).join();
                  if (enteredPin.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter full 6-digit MPIN.")),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _executeTransaction(amount, enteredPin);
                },
                child: const Text("Confirm & Authorize", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeTransaction(double amount, String mpin) async {
    setState(() => _isProcessing = true);
    final remarks = _remarksController.text.trim();

    Map<String, dynamic> res;
    if (widget.mode == 'P2P') {
      res = await ApiService.sendP2P(
        senderAppId: widget.user.appId,
        recipientAccount: _accountNumber,
        amount: amount,
        mpin: mpin,
      );
    } else {
      res = await ApiService.sendPayout(
        senderAppId: widget.user.appId,
        beneficiaryName: _recipientName,
        beneficiaryAccount: _accountNumber,
        ifscCode: _ifscCode,
        amount: amount,
        mpin: mpin,
      );
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Enrich response data with recipient details if missing
    res['recipient_name'] = res['recipient_name'] ?? _recipientName;
    res['recipient_account'] = res['recipient_account'] ?? _accountNumber;
    res['amount'] = res['amount'] ?? amount;
    if (remarks.isNotEmpty) {
      res['remarks'] = remarks;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(
          responseData: res,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_isReviewing ? "Review Transfer" : "Send Money", style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isReviewing ? _buildReviewStep() : _buildInputStep(),
      ),
    );
  }

  Widget _buildInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipient Card Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.neonPink.withValues(alpha: 0.12),
                child: Text(
                  _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : 'R',
                  style: const TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TO RECIPIENT", style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(_recipientName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text("$_bankName • $_maskedAccount", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(_country, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Amount Input Box
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TRANSFER AMOUNT", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _currency == 'INR' ? '₹' : 'CHF',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.neonPink),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: "0.00",
                        hintStyle: TextStyle(color: Colors.black26),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    "₹ ${widget.user.balance.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Optional Remarks Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
            ],
          ),
          child: TextField(
            controller: _remarksController,
            decoration: InputDecoration(
              labelText: "Remarks / Note (Optional)",
              hintText: "e.g. Family transfer or Rent payment",
              prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.grey, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: _proceedToReview,
            child: const Text("Continue to Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remarks = _remarksController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TRANSFER SUMMARY", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 16),
              _buildReviewRow("Recipient", _recipientName),
              _buildReviewRow("Bank Name", _bankName),
              _buildReviewRow("Account / IBAN", _maskedAccount),
              _buildReviewRow("Destination", "$_flag $_country"),
              if (_ifscCode.isNotEmpty) _buildReviewRow("IFSC / SWIFT Code", _ifscCode),
              const Divider(height: 24),
              _buildReviewRow("Transfer Amount", "$_currency ${amount.toStringAsFixed(2)}", isBold: true),
              _buildReviewRow("Transfer Fee", "Free (Zero FX Fee)"),
              if (remarks.isNotEmpty) _buildReviewRow("Remarks", remarks),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isProcessing ? null : () => setState(() => _isReviewing = false),
                child: const Text("Edit Details"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isProcessing ? null : () => _showMpinVerificationModal(amount),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              fontSize: isBold ? 16 : 13,
              color: isBold ? AppTheme.neonPink : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
