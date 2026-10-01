import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = "http://neonfinswiss.world/api";

  // Login with Email or Mobile + Password (Live Server API)
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 401) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      // Return error description if server un-reachable
    }

    return {
      "success": false,
      "message": "Server connection error. Please check your internet connection."
    };
  }

  // Quick Mobile & MPIN Login
  static Future<Map<String, dynamic>> loginWithPin(String phone, String pin) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login_with_pin.php"),
        body: {"phone": phone, "pin": pin},
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      if (response.statusCode == 200) return data;
      return data;
    } catch (e) {}

    return {
      "success": false,
      "message": "Connection error"
    };
  }

  // Fetch Live Transactions History
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

  // Fetch Saved Beneficiaries List
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

  // Add Beneficiary (Same Bank / Other Bank + IFSC)
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
          "beneficiary_name": name,
          "beneficiary_account_number": accountNumber,
          "ifsc_code": ifsc,
          "bank_name": bankName,
          "type": ifsc.isEmpty ? "SELF_BANK" : "OTHER_BANK",
          "nickname": nickname,
          "phone": phone,
          "email": email,
        },
      ).timeout(const Duration(seconds: 8));

      return json.decode(response.body);
    } catch (e) {}
    return {
      "success": false,
      "message": "Failed to connect to backend server.",
    };
  }

  // Execute Instant P2P Transfer / Payout
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
      ).timeout(const Duration(seconds: 8));

      return json.decode(response.body);
    } catch (e) {}

    return {
      "success": false,
      "message": "Transfer failed. Server connection error.",
    };
  }
}
