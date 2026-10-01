class UserModel {
  final String appId;
  final String fullName;
  final String email;
  final String phone;
  final String accountType;
  final double balance;
  final String accountNumber;
  final String status;

  UserModel({
    required this.appId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.balance,
    required this.accountNumber,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      appId: json['app_id'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'Neon User',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      accountType: json['account_type'] ?? 'CURRENT',
      balance: (json['balance'] != null) ? double.tryParse(json['balance'].toString()) ?? 0.0 : 0.0,
      accountNumber: json['account_number'] ?? 'CH890000',
      status: json['status'] ?? 'APPROVED',
    );
  }
}
