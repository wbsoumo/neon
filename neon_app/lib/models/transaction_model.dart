class TransactionModel {
  final String id;
  final String transactionId;
  final String senderAppId;
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final String type;
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
    required this.utrId,
    required this.date,
    required this.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id'] ?? '',
      senderAppId: json['sender_app_id'] ?? '',
      recipientAccount: json['recipient_account'] ?? '',
      recipientName: json['recipient_name'] ?? json['recipient_account'] ?? 'Recipient',
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      type: json['type'] ?? 'PAYMENT',
      utrId: json['utr_id'] ?? '',
      date: json['created_at'] ?? '',
      status: json['status'] ?? 'SUCCESS',
    );
  }
}
