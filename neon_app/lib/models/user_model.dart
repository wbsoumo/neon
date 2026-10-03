class UserModel {
  final String appId;
  final String fullName;
  final String email;
  final String phone;
  final String accountType;
  final double balance;
  final String accountNumber;
  final String status;
  final String photoPath;
  final String dob;
  final String gender;
  final String address;
  final String nationalId;
  final String country;

  final String sessionId;

  UserModel({
    required this.appId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.balance,
    required this.accountNumber,
    required this.status,
    this.photoPath = '',
    this.dob = '',
    this.gender = '',
    this.address = '',
    this.nationalId = '',
    this.country = 'Switzerland',
    this.sessionId = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String sessionId = ''}) {
    return UserModel(
      appId: json['app_id'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'Neon User',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      accountType: json['account_type'] ?? 'CURRENT',
      balance: (json['balance'] != null) ? double.tryParse(json['balance'].toString()) ?? 0.0 : 0.0,
      accountNumber: json['account_number'] ?? 'CH890000',
      status: json['status'] ?? 'APPROVED',
      photoPath: json['photo_path'] ?? json['signature_path'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      nationalId: json['national_id'] ?? json['aadhaar_number'] ?? '',
      country: json['country'] ?? 'Switzerland',
      sessionId: sessionId.isNotEmpty ? sessionId : (json['session_id'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_id': appId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'account_type': accountType,
      'balance': balance,
      'account_number': accountNumber,
      'status': status,
      'photo_path': photoPath,
      'dob': dob,
      'gender': gender,
      'address': address,
      'national_id': nationalId,
      'country': country,
      'session_id': sessionId,
    };
  }
}
