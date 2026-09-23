class ApiConstants {
  static const String baseUrl = "http://taskbazi.site/api/v1";

  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String selectStore = "$baseUrl/store/select";

  static const String syncCheck = "$baseUrl/sync-check";
  static const String categories = "$baseUrl/categories";
  static const String products = "$baseUrl/products";
  static const String createOrder = "$baseUrl/orders";
  static const String userAddresses = "$baseUrl/user/addresses";
  static const String storeUserAddress = "$baseUrl/user/addresses/store";
  static const String coupons = "$baseUrl/coupons";
  static const String validateCoupon = "$baseUrl/coupons/validate";
  static const String userWallet = "$baseUrl/user/wallet";
}
