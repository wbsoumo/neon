import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = "http://neonfinswiss.world/api";

  // ==========================================
  // 1. AUTHENTICATION (STRICT LIVE API ONLY)
  // ==========================================

  // Login with Mobile/Email & Password against live MySQL database
  static Future<Map<String, dynamic>> loginWithCredentials(String identity, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "mobile": identity,
          "email": identity,
          "username": identity,
          "password": password,
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        "success": false,
        "message": "Failed to connect to backend server ($baseUrl). Please check internet."
      };
    }
  }

  // Login with Mobile & 6-Digit MPIN
  static Future<Map<String, dynamic>> loginWithPin(String phone, String pin) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login_with_pin.php"),
        body: {"phone": phone, "pin": pin},
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Network error during MPIN verification."
      };
    }
  }

  // Register New Account
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String address,
    required String nationalId,
    required String accountType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        body: {
          "full_name": fullName,
          "email": email,
          "phone": phone,
          "password": password,
          "address": address,
          "national_id": nationalId,
          "aadhaar_number": nationalId,
          "account_type": accountType,
        },
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Server error while creating account."
      };
    }
  }

  // ==========================================
  // 2. USER DETAILS & BALANCE (STRICT LIVE API)
  // ==========================================

  static Future<UserModel?> getUserDetails(String appId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_user_details.php?app_id=$appId"),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {}
    return null;
  }

  // Update Profile Details
  static Future<Map<String, dynamic>> updateProfile(String appId, Map<String, String> updateFields) async {
    try {
      final bodyMap = {"app_id": appId, ...updateFields};
      final response = await http.post(
        Uri.parse("$baseUrl/update_profile.php"),
        body: bodyMap,
      ).timeout(const Duration(seconds: 8));

      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to update profile details"};
    }
  }

  // ==========================================
  // 3. TRANSACTIONS & BENEFICIARIES (STRICT LIVE API)
  // ==========================================

  // Get Live Transactions from Database
  static Future<List<TransactionModel>> getTransactions(String appId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_transactions.php?app_id=$appId"),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['transactions'] != null) {
          final List list = data['transactions'];
          return list.map((item) => TransactionModel.fromJson(item)).toList();
        }
      }
    } catch (e) {}
    return [];
  }

  // Get Live Beneficiaries List
  static Future<List<Map<String, dynamic>>> getBeneficiaries(String appId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_beneficiaries.php?app_id=$appId"),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['beneficiaries'] != null) {
          return List<Map<String, dynamic>>.from(data['beneficiaries']);
        }
      }
    } catch (e) {}
    return [];
  }

  // Add Beneficiary to Database
  static Future<Map<String, dynamic>> addBeneficiary({
    required String appId,
    required String name,
    required String accountNumber,
    required String ifsc,
    required String bankName,
    required String accountType,
    required String nickname,
    required String phone,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_beneficiary.php"),
        body: {
          "app_id": appId,
          "type": ifsc.isEmpty ? "SELF_BANK" : "OTHER_BANK",
          "beneficiary_name": name,
          "beneficiary_account_number": accountNumber,
          "ifsc_code": ifsc,
          "nickname": nickname,
          "phone": phone,
          "email": email,
        },
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Network error while saving beneficiary.",
      };
    }
  }

  // Execute P2P Transfer & Deduct Balance in Database
  static Future<Map<String, dynamic>> sendP2P({
    required String senderAppId,
    required String recipientAccount,
    required double amount,
    required String mpin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/transfer_payout.php"),
        body: {
          "sender_app_id": senderAppId,
          "recipient_account": recipientAccount,
          "amount": amount.toString(),
          "mpin": mpin,
        },
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Transfer error. Please check server status.",
      };
    }
  }

  // ==========================================
  // 4. STATEMENTS & COMPLIANCE
  // ==========================================

  static Future<Map<String, dynamic>> requestStatement({
    required String appId,
    required String startDate,
    required String endDate,
    required String format,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/request_statement.php"),
        body: {
          "app_id": appId,
          "start_date": startDate,
          "end_date": endDate,
          "format": format
        },
      ).timeout(const Duration(seconds: 8));

      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to request statement."};
    }
  }
}
