class SpaceModel {
  final String spaceId;
  final String appId;
  final String name;
  final String category;
  final String iconKey;
  final String currency;
  final double balance;
  final double? targetAmount;
  final String? targetDate;
  final String colorHex;
  final String allocationType;
  final double allocationValue;
  final String createdAt;

  SpaceModel({
    required this.spaceId,
    required this.appId,
    required this.name,
    required this.category,
    required this.iconKey,
    required this.currency,
    required this.balance,
    this.targetAmount,
    this.targetDate,
    this.colorHex = '#E91E63',
    this.allocationType = 'NONE',
    this.allocationValue = 0.0,
    required this.createdAt,
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      spaceId: json['space_id'] ?? '',
      appId: json['app_id'] ?? '',
      name: json['name'] ?? 'Unnamed Space',
      category: json['category'] ?? 'Custom Space',
      iconKey: json['icon_key'] ?? 'custom',
      currency: json['currency'] ?? 'CHF',
      balance: (json['balance'] != null) ? double.tryParse(json['balance'].toString()) ?? 0.0 : 0.0,
      targetAmount: json['target_amount'] != null ? double.tryParse(json['target_amount'].toString()) : null,
      targetDate: json['target_date'],
      colorHex: json['color_hex'] ?? '#E91E63',
      allocationType: json['allocation_type'] ?? 'NONE',
      allocationValue: (json['allocation_value'] != null) ? double.tryParse(json['allocation_value'].toString()) ?? 0.0 : 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
      'app_id': appId,
      'name': name,
      'category': category,
      'icon_key': iconKey,
      'currency': currency,
      'balance': balance,
      'target_amount': targetAmount,
      'target_date': targetDate,
      'color_hex': colorHex,
      'allocation_type': allocationType,
      'allocation_value': allocationValue,
      'created_at': createdAt,
    };
  }

  double get progressPercentage {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    final pct = (balance / targetAmount!) * 100;
    return pct > 100 ? 100.0 : pct;
  }

  double get amountRemaining {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    final rem = targetAmount! - balance;
    return rem < 0 ? 0.0 : rem;
  }
}

class SpaceTransactionModel {
  final String transactionId;
  final String spaceId;
  final String appId;
  final String type; // ADD, WITHDRAW, AUTOMATIC, REVERSAL
  final double amount;
  final String currency;
  final String sourceDest;
  final String status;
  final String createdAt;

  SpaceTransactionModel({
    required this.transactionId,
    required this.spaceId,
    required this.appId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.sourceDest,
    required this.status,
    required this.createdAt,
  });

  factory SpaceTransactionModel.fromJson(Map<String, dynamic> json) {
    return SpaceTransactionModel(
      transactionId: json['transaction_id'] ?? '',
      spaceId: json['space_id'] ?? '',
      appId: json['app_id'] ?? '',
      type: json['type'] ?? 'ADD',
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      currency: json['currency'] ?? 'CHF',
      sourceDest: json['source_dest'] ?? 'Main Account',
      status: json['status'] ?? 'SUCCESS',
      createdAt: json['created_at'] ?? '',
    );
  }
}
