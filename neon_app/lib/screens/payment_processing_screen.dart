import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaymentProcessingScreen extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const PaymentProcessingScreen({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final status = responseData['status'] ?? 'SUCCESS';
    final txnId = responseData['transaction_id'] ?? responseData['tx_id'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final amount = responseData['amount'] ?? '0.00';
    final isSuccess = status.toString().toUpperCase() == 'SUCCESS';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Payment Status", style: TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green[50] : Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 56,
                  color: isSuccess ? AppTheme.successGreen : Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? "Payment Successful!" : "Payment Processing",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess ? "Your transaction has been executed securely" : "Your transfer is being reviewed by compliance",
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Transaction Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildDetailRow("Transaction ID", txnId),
                    const Divider(height: 24),
                    _buildDetailRow("Amount Transferred", "CHF $amount"),
                    const Divider(height: 24),
                    _buildDetailRow("Date & Time", DateTime.now().toString().substring(0, 16)),
                    const Divider(height: 24),
                    _buildDetailRow("Status", status.toString().toUpperCase(), isStatus: true, isSuccess: isSuccess),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Back to Dashboard", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false, bool isSuccess = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green[50] : Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isSuccess ? AppTheme.successGreen : Colors.amber[900],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          )
        else
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
