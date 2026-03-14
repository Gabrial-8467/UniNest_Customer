class AppConstants {
  // App Info
  static const String appName = 'Campus Eats';
  static const String appVersion = '1.0.0';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // Colors
  static const int primaryColorValue = 0xFFFF6B6B;
  static const int secondaryColorValue = 0xFF2D3436;
  static const int backgroundColorValue = 0xFFF8F9FA;
  static const int errorColorValue = 0xFFE74C3C;
  static const int successColorValue = 0xFF27AE60;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network Settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String cartKey = 'cart_items';
  static const String favoritesKey = 'favorites';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Product Categories
  static const List<String> productCategories = [
    'Medicine',
    'Healthcare',
    'Personal Care',
    'Wellness',
    'First Aid',
    'Vitamins',
  ];

  // Order Statuses
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  // Payment Methods
  static const List<String> paymentMethods = ['cash', 'card', 'upi', 'wallet'];

  // User Types
  static const List<String> userTypes = ['customer'];

  // Student Types
  static const List<String> studentTypes = ['hostler', 'day_scholar'];

  // Image URLs (fallback)
  static const String defaultProductImage =
      'https://picsum.photos/seed/product/200/200.jpg';
  static const String defaultUserAvatar =
      'https://picsum.photos/seed/avatar/200/200.jpg';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int maxNameLength = 50;
  static const int maxAddressLength = 200;

  // Delivery
  static const double defaultDeliveryFee = 29.99;
  static const double platformFee = 1.99;
  static const double taxRate = 0.08; // 8%

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration userCacheDuration = Duration(days: 1);
}
