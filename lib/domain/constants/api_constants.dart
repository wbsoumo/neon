class ApiConstants {
  static const String baseUrl = "https://admin.sbmartquick.com/api/v1";

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
  static const String registerFcmToken = "$baseUrl/user/fcm-token";
  static const String sliders = "$baseUrl/sliders";

  // Store Manager App Endpoints
  static const String managerLogin = "$baseUrl/manager/login";
  static const String managerOrders = "$baseUrl/manager/orders";
  static const String managerRiders = "$baseUrl/manager/riders";
  static const String managerUpdateOrderStatus = "$baseUrl/manager/orders/update-status";
}


