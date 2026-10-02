import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = "http://neonfinswiss.world/api";
  static const String _userKey = "saved_neon_user";
  static const String _sessionKey = "saved_session_id";

  // Session persistence helpers
  static Future<void> saveUserSession(UserModel user, String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWithSession = UserModel(
      appId: user.appId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      accountType: user.accountType,
      balance: user.balance,
      accountNumber: user.accountNumber,
      status: user.status,
      sessionId: sessionId,
    );
    await prefs.setString(_userKey, json.encode(userWithSession.toJson()));
    if (sessionId.isNotEmpty) {
      await prefs.setString(_sessionKey, sessionId);
    }
  }

  static Future<UserModel?> getSavedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    final savedSessionId = prefs.getString(_sessionKey) ?? '';
    if (userStr != null && userStr.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(userStr);
        return UserModel.fromJson(jsonMap, sessionId: savedSessionId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_sessionKey);
  }

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
    } catch (e) {
      debugPrint("getUserDetails error: $e");
    }
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
    } catch (e) {
      debugPrint("getTransactions error: $e");
    }
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
    } catch (e) {
      debugPrint("getBeneficiaries error: $e");
    }
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
      final savedUser = await getSavedUserSession();
      final sessionId = savedUser?.sessionId ?? '';

      final Map<String, String> headers = {};
      if (sessionId.isNotEmpty) {
        headers["X-Session-ID"] = sessionId;
        headers["Authorization"] = "Bearer $sessionId";
      }

      final response = await http.post(
        Uri.parse("$baseUrl/add_beneficiary.php"),
        headers: headers,
        body: {
          "app_id": appId,
          "session_id": sessionId,
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
