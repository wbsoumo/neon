import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinkit_series/domain/constants/api_constants.dart';

class ApiService {
  static const String _kCategoriesCacheKey = 'cache_categories_data';
  static const String _kCategoriesEtagKey = 'cache_categories_etag';

  static const String _kProductsCacheKey = 'cache_products_data_';
  static const String _kProductsEtagKey = 'cache_products_etag_';

  // 1. Fetch Store Selection & Operational Status
  static Future<Map<String, dynamic>?> fetchSelectedStore({double? lat, double? lng}) async {
    try {
      final Uri uri = Uri.parse(ApiConstants.selectStore).replace(
        queryParameters: {
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['store'];
        }
      }
    } catch (e) {
      debugPrint("API Error fetching store: $e");
    }
    return null;
  }

  // 2. Fetch Categories with Local Storage Cache & Delta ETag
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    SharedPreferences? prefs;
    List<Map<String, dynamic>> cachedCategories = [];
    String? etag;

    try {
      prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_kCategoriesCacheKey);
      etag = prefs.getString(_kCategoriesEtagKey);
      if (jsonStr != null) {
        final List list = jsonDecode(jsonStr);
        cachedCategories = List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint("Error reading categories cache: $e");
    }

    try {
      final Map<String, String> headers = {};
      if (etag != null && etag.isNotEmpty) {
        headers['If-None-Match'] = etag;
      }

      final response = await http
          .get(Uri.parse(ApiConstants.categories), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 304) {
        // Backend confirms data not modified; return local cache instantly
        return cachedCategories;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<Map<String, dynamic>> freshCats = List<Map<String, dynamic>>.from(data['data']);
          
          // Save to local storage asynchronously
          if (prefs != null) {
            prefs.setString(_kCategoriesCacheKey, jsonEncode(freshCats));
            final String? newEtag = response.headers['etag'];
            if (newEtag != null) {
              prefs.setString(_kCategoriesEtagKey, newEtag);
            }
          }
          return freshCats;
        }
      }
    } catch (e) {
      debugPrint("API Error fetching categories, returning cache: $e");
    }

    return cachedCategories;
  }

  // 3. Fetch Products with Local Storage Cache & Delta ETag Sync
  static Future<List<Map<String, dynamic>>> fetchProducts({int? categoryId, int storeId = 1}) async {
    final String cacheKey = "$_kProductsCacheKey${storeId}_${categoryId ?? 'all'}";
    final String etagKey = "$_kProductsEtagKey${storeId}_${categoryId ?? 'all'}";

    SharedPreferences? prefs;
    List<Map<String, dynamic>> cachedProducts = [];
    String? etag;

    try {
      prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(cacheKey);
      etag = prefs.getString(etagKey);
      if (jsonStr != null) {
        final List list = jsonDecode(jsonStr);
        cachedProducts = List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint("Error reading products cache: $e");
    }

    try {
      final Map<String, String> queryParams = {
        'store_id': storeId.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      };
      final Uri uri = Uri.parse(ApiConstants.products).replace(queryParameters: queryParams);

      final Map<String, String> headers = {};
      if (etag != null && etag.isNotEmpty) {
        headers['If-None-Match'] = etag;
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 304) {
        // Data not changed on server; return local cache instantly
        return cachedProducts;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<Map<String, dynamic>> freshProducts = List<Map<String, dynamic>>.from(data['data']);

          // Update local storage
          if (prefs != null) {
            prefs.setString(cacheKey, jsonEncode(freshProducts));
            final String? newEtag = response.headers['etag'];
            if (newEtag != null) {
              prefs.setString(etagKey, newEtag);
            }
          }
          return freshProducts;
        }
      }
    } catch (e) {
      debugPrint("API Error fetching products, returning local cache: $e");
    }

    return cachedProducts;
  }

  // 4. Create Order & Reserve Inventory in Backend
  static Future<Map<String, dynamic>> createOrder({
    required String userName,
    required String userPhone,
    required String deliveryAddress,
    required List<Map<String, dynamic>> items,
    int storeId = 1,
    String paymentMethod = "PhonePe UPI",
  }) async {
    try {
      final body = jsonEncode({
        "user_name": userName,
        "user_phone": userPhone,
        "delivery_address": deliveryAddress,
        "store_id": storeId,
        "payment_method": paymentMethod,
        "items": items,
      });

      final response = await http.post(
        Uri.parse(ApiConstants.createOrder),
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection error: $e"
      };
    }
  }
}
