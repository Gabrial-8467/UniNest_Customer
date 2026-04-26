class ApiEndpoints {
  const ApiEndpoints._();

  // API Base Paths
  static const String apiPrefix = '/api/customer';
  static const String publicApiPrefix = '/api/public';
  static const String vendorApiPrefix = '/api/vendor';

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
  // Featured products use products endpoint with featured=true query param
  static const String categories = '/api/categories';

  // Vendor Products
  static const String vendorProducts = '$vendorApiPrefix/products';
  static const int maxFeaturedProducts = 3; // Vendor featured products limit
  static const String search = '/api/public/search';

  // Orders
  static const String orders = '$apiPrefix/orders';
  static const String calculatePricing = '$apiPrefix/orders/calculate-pricing';

  static String vendorById(String vendorId) => '$vendors/$vendorId';
  static String productById(String productId) => '$products/$productId';
  static String orderById(String orderId) => '$orders/$orderId';
  static String cancelOrder(String orderId) => '$orders/$orderId/cancel';
  static String trackOrder(String orderId) => '$orders/$orderId/track';
  static String reviewOrder(String orderId) => '$orders/$orderId/review';

  // Vendor Products
  static String vendorProductById(String productId) =>
      '$vendorProducts/$productId';

  // Notifications
  static const String notifications = '$apiPrefix/notifications';
  static const String markNotificationsRead = '$apiPrefix/notifications/read';

  // Utility
  static const String health = '/health';
  static const String customerHealth = '$apiPrefix/health';
}
