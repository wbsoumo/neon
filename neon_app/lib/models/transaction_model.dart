class TransactionModel {
  final String id;
  final String transactionId;
  final String senderAppId;
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final String type;
  final String flowType; // 'CREDIT' or 'DEBIT'
  final String utrId;
  final String date;
  final String status;

  TransactionModel({
    required this.id,
    required this.transactionId,
    required this.senderAppId,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.type,
    required this.flowType,
    required this.utrId,
    required this.date,
    required this.status,
  });

  bool get isCredit => flowType == 'CREDIT' || type == 'CREDIT';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'PAYMENT').toString().toUpperCase();
    final rawFlow = (json['flow_type'] ?? '').toString().toUpperCase();
    final resolvedFlow = rawFlow.isNotEmpty ? rawFlow : (rawType == 'CREDIT' ? 'CREDIT' : 'DEBIT');

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
      senderAppId: json['sender_app_id']?.toString() ?? '',
      recipientAccount: json['recipient_account']?.toString() ?? '',
      recipientName: (json['recipient_name'] != null && json['recipient_name'].toString().isNotEmpty)
          ? json['recipient_name'].toString()
          : ((json['recipient_account'] != null && json['recipient_account'].toString().isNotEmpty)
              ? json['recipient_account'].toString()
              : 'Recipient'),
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      type: rawType,
      flowType: resolvedFlow,
      utrId: json['utr_id']?.toString() ?? '',
      date: json['created_at']?.toString() ?? json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUCCESS',
    );
  }
}
