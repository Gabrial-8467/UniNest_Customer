class ApiEndpoints {
  const ApiEndpoints._();

  // API Base Paths
  static const String apiPrefix = '/api/customer';
  static const String publicApiPrefix = '/api/public';

  // Authentication
  static const String register = '$apiPrefix/auth/register';
  static const String login = '$apiPrefix/auth/login';
  static const String changePassword = '$apiPrefix/auth/change-password';
  static const String refreshToken = '$apiPrefix/auth/refresh-token';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';
  static const String verifyEmail = '$apiPrefix/auth/verify-email';
  static const String logout = '$apiPrefix/auth/logout';
  static const String authStatus = '$apiPrefix/auth/status';
  static const String resendVerification =
      '$apiPrefix/auth/resend-verification';
  static const String deleteAccount = '$apiPrefix/auth/account';

  // Customer profile
  static const String profile = '$apiPrefix/profile';

  // Catalog (Public - No Auth Required)
  static const String vendors = '/api/vendors';
  static const String nearbyVendors = '/api/vendors/nearby';
  static const String products = '/api/products';
  static const String featuredProducts = '/api/products/featured';
  static const String categories = '/api/categories';
  static const String search = '/api/search';

  // Orders
  static const String orders = '$apiPrefix/orders';

  static String vendorById(String vendorId) => '$vendors/$vendorId';
  static String productById(String productId) => '$products/$productId';
  static String orderById(String orderId) => '$orders/$orderId';
  static String cancelOrder(String orderId) => '$orders/$orderId/cancel';
  static String trackOrder(String orderId) => '$orders/$orderId/track';
  static String reviewOrder(String orderId) => '$orders/$orderId/review';

  // Notifications
  static const String notifications = '$apiPrefix/notifications';
  static const String markNotificationsRead = '$apiPrefix/notifications/read';

  // Utility
  static const String health = '/health';
}
