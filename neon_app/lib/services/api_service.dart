import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = "https://neonfinswiss.world/api";
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

  // Local Storage for Recent Neon Bank Recipients (No DB insertion)
  static const String _recentNeonKey = "recent_neon_bank_recipients";

  static Future<List<Map<String, dynamic>>> getRecentNeonRecipients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_recentNeonKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = json.decode(jsonStr);
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      debugPrint("Error reading recent Neon recipients: $e");
    }
    return [];
  }

  static Future<void> saveRecentNeonRecipient({
    required String name,
    required String accountNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getRecentNeonRecipients();

      // Remove existing item with same account number if present
      current.removeWhere((item) => item['accountNumber'] == accountNumber);

      // Mask account number for safe local storage display
      String masked = accountNumber;
      if (accountNumber.length > 4) {
        masked = "••••${accountNumber.substring(accountNumber.length - 4)}";
      }

      // Add to front of list
      current.insert(0, {
        "name": name,
        "accountNumber": accountNumber,
        "maskedAccount": masked,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      // Keep maximum 5 recent recipients
      final trimmed = current.take(5).toList();
      await prefs.setString(_recentNeonKey, json.encode(trimmed));
    } catch (e) {
      debugPrint("Error saving recent Neon recipient: $e");
    }
  }

  static Future<void> removeRecentNeonRecipient(String accountNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getRecentNeonRecipients();
      current.removeWhere((item) => item['accountNumber'] == accountNumber);
      await prefs.setString(_recentNeonKey, json.encode(current));
    } catch (e) {
      debugPrint("Error removing recent Neon recipient: $e");
    }
  }

  // ==========================================
  // 1. AUTHENTICATION (STRICT LIVE API ONLY)
  // ==========================================

  // Fetch current FCM Token safely with explicit notification permission prompt
  static Future<String> getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint("[FCM] User notification permission status: ${settings.authorizationStatus}");

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint("[FCM] Token acquired: $token");
        return token;
      }
    } catch (e) {
      debugPrint("[FCM] Could not get token: $e");
    }
    return '';
  }

  // Update FCM token on backend server
  static Future<void> syncFcmToken(String appId) async {
    if (appId.isEmpty) return;
    try {
      final token = await getFcmToken();
      if (token.isNotEmpty) {
        await http.post(
          Uri.parse("$baseUrl/update_fcm_token.php"),
          body: {
            "app_id": appId,
            "fcm_token": token,
            "fmc_token": token,
          },
        ).timeout(const Duration(seconds: 5));
        debugPrint("[FCM] Synced token for $appId");
      }
    } catch (e) {
      debugPrint("[FCM] Sync error: $e");
    }
  }

  // Login with Mobile/Email & Password against live MySQL database
  static Future<Map<String, dynamic>> loginWithCredentials(String identity, String password) async {
    try {
      final fcmToken = await getFcmToken();
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "mobile": identity,
          "email": identity,
          "username": identity,
          "password": password,
          "fcm_token": fcmToken,
          "fmc_token": fcmToken,
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
      final fcmToken = await getFcmToken();
      final response = await http.post(
        Uri.parse("$baseUrl/login_with_pin.php"),
        body: {
          "phone": phone,
          "pin": pin,
          "fcm_token": fcmToken,
          "fmc_token": fcmToken,
        },
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Network error during MPIN verification."
      };
    }
  }

  static Map<String, String> _buildHeaders([String sessionId = '']) {
    final headers = <String, String>{
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
      "Accept": "application/json",
    };
    final trimmedSession = sessionId.trim();
    if (trimmedSession.isNotEmpty) {
      headers["Authorization"] = "Bearer $trimmedSession";
    }
    return headers;
  }

  static Map<String, dynamic> _safeParseJson(String responseBody, {String defaultErrorMessage = "Invalid server response."}) {
    final trimmed = responseBody.trim();
    if (trimmed.startsWith('<')) {
      return {
        "success": false,
        "message": defaultErrorMessage
      };
    }
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {
      "success": false,
      "message": defaultErrorMessage
    };
  }

  // Create / Set 6-Digit Transaction MPIN (Aadhaar Removed)
  static Future<Map<String, dynamic>> createMpin({
    required String mpin,
    required String sessionId,
    String appId = '',
  }) async {
    try {
      final savedUser = await getSavedUserSession();
      final effectiveSessionId = sessionId.isNotEmpty ? sessionId : (savedUser?.sessionId ?? '');
      final effectiveAppId = appId.isNotEmpty ? appId : (savedUser?.appId ?? '');

      final headers = _buildHeaders(effectiveSessionId);

      final bodyParams = <String, String>{
        "mpin": mpin,
      };
      if (effectiveSessionId.trim().isNotEmpty) {
        bodyParams["session_id"] = effectiveSessionId.trim();
      }
      if (effectiveAppId.trim().isNotEmpty) {
        bodyParams["app_id"] = effectiveAppId.trim();
      }

      debugPrint("POSTing createMpin with params=$bodyParams");

      final response = await http.post(
        Uri.parse("$baseUrl/create_mpin.php"),
        headers: headers,
        body: bodyParams,
      ).timeout(const Duration(seconds: 10));

      debugPrint("createMpin statusCode: ${response.statusCode}");
      debugPrint("createMpin body: ${response.body}");

      final trimmed = response.body.trim();
      if (trimmed.startsWith('<')) {
        final snippet = trimmed.length > 150 ? trimmed.substring(0, 150) : trimmed;
        return {
          "success": false,
          "message": "HTTP ${response.statusCode}: $snippet"
        };
      }

      return _safeParseJson(response.body, defaultErrorMessage: "Failed to set MPIN. Please try again.");
    } catch (e) {
      debugPrint("createMpin catch: $e");
      return {
        "success": false,
        "message": "Error creating MPIN: ${e.toString()}"
      };
    }
  }

  // Standalone MPIN Verification Endpoint
  static Future<Map<String, dynamic>> verifyMpin({
    required String mpin,
    required String sessionId,
    required String appId,
  }) async {
    try {
      final savedUser = await getSavedUserSession();
      final effectiveSessionId = sessionId.isNotEmpty ? sessionId : (savedUser?.sessionId ?? '');
      final effectiveAppId = appId.isNotEmpty ? appId : (savedUser?.appId ?? '');

      final headers = _buildHeaders(effectiveSessionId);

      final bodyParams = <String, String>{
        "mpin": mpin,
      };
      if (effectiveSessionId.trim().isNotEmpty) {
        bodyParams["session_id"] = effectiveSessionId.trim();
      }
      if (effectiveAppId.trim().isNotEmpty) {
        bodyParams["app_id"] = effectiveAppId.trim();
      }

      final response = await http.post(
        Uri.parse("$baseUrl/verify_mpin.php"),
        headers: headers,
        body: bodyParams,
      ).timeout(const Duration(seconds: 10));

      return _safeParseJson(response.body, defaultErrorMessage: "Failed to verify MPIN. Please try again.");
    } catch (e) {
      return {
        "success": false,
        "message": "Error during MPIN verification: ${e.toString()}"
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

  static Future<UserModel?> getUserDetails(String appId, {String sessionId = ''}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_user_details.php?app_id=$appId&session_id=$sessionId"),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user'], sessionId: sessionId);
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

  // Verify Neon Bank Account & Get Customer Details
  static Future<Map<String, dynamic>> getUserByAccount(String accountNumber) async {
    try {
      final savedUser = await getSavedUserSession();
      final sessionId = savedUser?.sessionId ?? '';

      final response = await http.get(
        Uri.parse("$baseUrl/get_user_by_account.php?account_number=$accountNumber&session_id=$sessionId"),
        headers: _buildHeaders(sessionId),
      ).timeout(const Duration(seconds: 8));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Account verification failed. Please check your network connection.",
      };
    }
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
    double dailyLimit = 50000.0,
    String type = "OTHER_BANK",
  }) async {
    try {
      final savedUser = await getSavedUserSession();
      final sessionId = savedUser?.sessionId ?? '';

      final String resolvedType = type.isNotEmpty ? type : (ifsc.isEmpty ? "SELF_BANK" : "OTHER_BANK");
      final String resolvedNickname = nickname.isNotEmpty ? nickname : (bankName.isNotEmpty ? bankName : "Beneficiary");

      final response = await http.post(
        Uri.parse("$baseUrl/add_beneficiary.php"),
        headers: _buildHeaders(sessionId),
        body: {
          "app_id": appId,
          "session_id": sessionId,
          "type": resolvedType,
          "beneficiary_name": name,
          "beneficiary_account_number": accountNumber,
          "ifsc_code": ifsc,
          "nickname": resolvedNickname,
          "daily_limit": dailyLimit.toStringAsFixed(2),
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
      final savedUser = await getSavedUserSession();
      final sessionId = savedUser?.sessionId ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/transfer_p2p.php"),
        headers: _buildHeaders(sessionId),
        body: {
          "app_id": senderAppId,
          "sender_app_id": senderAppId,
          "session_id": sessionId,
          "recipient_account_number": recipientAccount,
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

  // Execute P2B Payout to Real External Bank
  static Future<Map<String, dynamic>> sendPayout({
    required String senderAppId,
    required String beneficiaryName,
    required String beneficiaryAccount,
    required String ifscCode,
    required double amount,
    required String mpin,
    String provider = "jiopay",
  }) async {
    try {
      final savedUser = await getSavedUserSession();
      final sessionId = savedUser?.sessionId ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/transfer_payout.php"),
        headers: _buildHeaders(sessionId),
        body: {
          "app_id": senderAppId,
          "sender_app_id": senderAppId,
          "session_id": sessionId,
          "provider": provider,
          "beneficiary_name": beneficiaryName,
          "beneficiary_account": beneficiaryAccount,
          "beneficiary_account_number": beneficiaryAccount,
          "ifsc_code": ifscCode,
          "ifsc": ifscCode,
          "amount": amount.toString(),
          "mpin": mpin,
        },
      ).timeout(const Duration(seconds: 12));

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Payout error. Please check network connection.",
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

  // ==========================================
  // 5. LIVE OPEN SOURCE CURRENCY & INVEST API
  // ==========================================

  /// Fetch live exchange rate from INR to CHF via Frankfurter Open Source API
  static Future<double> getInrToChfRate() async {
    try {
      final res = await http
          .get(Uri.parse("https://api.frankfurter.app/latest?from=INR&to=CHF"))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rate = (data['rates']?['CHF'] as num?)?.toDouble();
        if (rate != null && rate > 0) {
          return rate;
        }
      }
    } catch (e) {
      debugPrint("Currency API error: $e");
    }
    // Fallback rate: 1 INR ≈ 0.0105 CHF
    return 0.0105;
  }

  /// Fetch live exchange rate from CHF to INR via Frankfurter Open Source API
  static Future<double> getChfToInrRate() async {
    try {
      final res = await http
          .get(Uri.parse("https://api.frankfurter.app/latest?from=CHF&to=INR"))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rate = (data['rates']?['INR'] as num?)?.toDouble();
        if (rate != null && rate > 0) {
          return rate;
        }
      }
    } catch (e) {
      debugPrint("CHF to INR Currency API error: $e");
    }
    // Fallback rate: 1 CHF ≈ 95.24 INR
    return 95.238;
  }

  /// Fetch historical EUR/CHF rates for stock graph visualization
  static Future<List<double>> getStockHistoryData(String period) async {
    try {
      String startDateStr;
      final now = DateTime.now();
      if (period == "1d" || period == "1w") {
        final past = now.subtract(const Duration(days: 7));
        startDateStr = "${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')}";
      } else if (period == "1m") {
        final past = now.subtract(const Duration(days: 30));
        startDateStr = "${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')}";
      } else {
        final past = now.subtract(const Duration(days: 365));
        startDateStr = "${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')}";
      }

      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final url = "https://api.frankfurter.app/$startDateStr..$todayStr?from=EUR&to=CHF";
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final ratesObj = data['rates'] as Map<String, dynamic>?;
        if (ratesObj != null && ratesObj.isNotEmpty) {
          final List<double> values = [];
          ratesObj.forEach((date, map) {
            if (map['CHF'] != null) {
              values.add((map['CHF'] as num).toDouble());
            }
          });
          if (values.isNotEmpty) return values;
        }
      }
    } catch (e) {
      debugPrint("Stock history API error: $e");
    }
    // Fallback graph points if network unavailable
    return [0.932, 0.935, 0.941, 0.938, 0.945, 0.949, 0.952];
  }

  // ==========================================
  // 6. SPACES API INTEGRATION
  // ==========================================

  static Future<Map<String, dynamic>> fetchSpaces(String appId, {String sessionId = ''}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: {"action": "list", "app_id": appId, "session_id": sessionId},
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to load spaces from server."};
    }
  }

  static Future<Map<String, dynamic>> createSpace({
    required String appId,
    required String name,
    required String category,
    required String iconKey,
    required String currency,
    double? targetAmount,
    String? targetDate,
    double initialAmount = 0.0,
    String colorHex = '#E91E63',
    String allocationType = 'NONE',
    double allocationValue = 0.0,
    String sessionId = '',
  }) async {
    try {
      final body = {
        "action": "create",
        "app_id": appId,
        "name": name,
        "category": category,
        "icon_key": iconKey,
        "currency": currency,
        "color_hex": colorHex,
        "allocation_type": allocationType,
        "allocation_value": allocationValue.toString(),
        "initial_amount": initialAmount.toString(),
        "session_id": sessionId,
      };
      if (targetAmount != null) body["target_amount"] = targetAmount.toString();
      if (targetDate != null) body["target_date"] = targetDate;

      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: body,
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to create space on server."};
    }
  }

  static Future<Map<String, dynamic>> updateSpace({
    required String appId,
    required String spaceId,
    required String name,
    double? targetAmount,
    String? targetDate,
    String allocationType = 'NONE',
    double allocationValue = 0.0,
    String sessionId = '',
  }) async {
    try {
      final body = {
        "action": "update",
        "app_id": appId,
        "space_id": spaceId,
        "name": name,
        "allocation_type": allocationType,
        "allocation_value": allocationValue.toString(),
        "session_id": sessionId,
      };
      if (targetAmount != null) body["target_amount"] = targetAmount.toString();
      if (targetDate != null) body["target_date"] = targetDate;

      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: body,
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to update space."};
    }
  }

  static Future<Map<String, dynamic>> deleteSpace({
    required String appId,
    required String spaceId,
    String sessionId = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: {"action": "delete", "app_id": appId, "space_id": spaceId, "session_id": sessionId},
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to delete space."};
    }
  }

  static Future<Map<String, dynamic>> transferSpaceMoney({
    required String appId,
    required String spaceId,
    required String type, // ADD or WITHDRAW
    required double amount,
    String sessionId = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: {
          "action": "transfer",
          "app_id": appId,
          "space_id": spaceId,
          "type": type,
          "amount": amount.toString(),
          "session_id": sessionId,
        },
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to execute transfer."};
    }
  }

  static Future<Map<String, dynamic>> fetchSpaceTransactions({
    required String appId,
    required String spaceId,
    String sessionId = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/spaces.php"),
        body: {
          "action": "transactions",
          "app_id": appId,
          "space_id": spaceId,
          "session_id": sessionId,
        },
      ).timeout(const Duration(seconds: 10));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Failed to fetch transactions."};
    }
  }
}

