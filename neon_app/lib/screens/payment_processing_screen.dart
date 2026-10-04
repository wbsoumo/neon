import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PaymentProcessingScreen extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const PaymentProcessingScreen({super.key, required this.responseData});

  @override
  Widget build(BuildContext context) {
    final statusStr = (responseData['status'] ?? responseData['tx_status'] ?? 'SUCCESS').toString().toUpperCase();
    final isSuccess = statusStr == 'SUCCESS' || statusStr == 'COMPLETED';
    final isPending = statusStr == 'PENDING' || statusStr == 'PROCESSING';
    
    final txnId = responseData['transaction_id'] ?? responseData['tx_id'] ?? responseData['id'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final utrId = responseData['utr_id'] ?? responseData['utr'] ?? 'NEON${DateTime.now().microsecondsSinceEpoch.toString().substring(0, 10)}';
    final recipientName = responseData['recipient_name'] ?? responseData['beneficiary_name'] ?? responseData['recipient_account'] ?? 'Beneficiary';
    final recipientAccount = responseData['recipient_account'] ?? responseData['beneficiary_account'] ?? 'N/A';
    final rawAmount = responseData['amount'] ?? '0.00';
    final double amount = (rawAmount is num) ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 0.0);
    final dateStr = responseData['created_at'] ?? responseData['date'] ?? DateTime.now().toString().substring(0, 16);

    Color themeColor = isSuccess ? AppTheme.successGreen : (isPending ? Colors.amber[800]! : AppTheme.dangerRed);
    Color bgLightColor = isSuccess ? Colors.green[50]! : (isPending ? Colors.amber[50]! : Colors.red[50]!);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Transaction Receipt", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Advanced Receipt Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Animated Status Circle Icon
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: bgLightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : (isPending ? Icons.schedule_rounded : Icons.error_rounded),
                      size: 52,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isSuccess ? "Transfer Successful" : (isPending ? "Transfer Processing" : "Transfer Failed"),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: themeColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSuccess 
                        ? "Money sent successfully to recipient account" 
                        : (isPending ? "Your transfer is under compliance review" : "Transaction could not be authorized"),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Amount Display Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text("AMOUNT TRANSFERRED", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.1)),
                        const SizedBox(height: 4),
                        Text(
                          "CHF ${amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                        ),
                        if (responseData['amount_inr'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "≈ ₹ ${(responseData['amount_inr'] as num).toDouble().toStringAsFixed(2)} INR",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Receipt Meta Key-Values
                  _buildReceiptRow(Icons.person_outline_rounded, "Recipient Name", recipientName),
                  const SizedBox(height: 14),
                  _buildReceiptRow(Icons.account_balance_outlined, "Recipient Account", recipientAccount),
                  const SizedBox(height: 14),
                  _buildReceiptRowWithCopy(context, Icons.tag_rounded, "Transaction Reference", txnId),
                  const SizedBox(height: 14),
                  _buildReceiptRowWithCopy(context, Icons.numbers_rounded, "Bank UTR ID", utrId),
                  const SizedBox(height: 14),
                  _buildReceiptRow(Icons.access_time_rounded, "Date & Timestamp", dateStr),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_outlined, size: 18, color: AppTheme.textMuted),
                          SizedBox(width: 10),
                          Text("Payment Status", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: bgLightColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusStr,
                          style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Return to Dashboard Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text("Done & Back to Dashboard", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRowWithCopy(BuildContext context, IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Copied $label: $value")),
            );
          },
          child: Row(
            children: [
              Text(
                value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, size: 14, color: AppTheme.neonPink),
            ],
          ),
        ),
      ],
    );
  }
}
