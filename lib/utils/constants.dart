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
  static const List<String> userTypes = ['customer', 'vendor'];

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

// Registered Canteens Data
const List<Map<String, dynamic>> kRegisteredCanteens = [
  {
    'id': 'canteen_1',
    'name': 'Main Canteen',
    'location': 'Main Building',
    'rating': 4.5,
    'reviewCount': 120,
    'isOpen': true,
    'imageUrl': 'https://picsum.photos/seed/canteen1/200/200.jpg',
    'description': 'The main canteen offering a variety of meals and snacks',
    'openingTime': '08:00',
    'closingTime': '20:00',
  },
  {
    'id': 'canteen_2',
    'name': 'Engineering Canteen',
    'location': 'Engineering Block',
    'rating': 4.2,
    'reviewCount': 85,
    'isOpen': true,
    'imageUrl': 'https://picsum.photos/seed/canteen2/200/200.jpg',
    'description': 'Specialized meals for engineering students',
    'openingTime': '09:00',
    'closingTime': '19:00',
  },
  {
    'id': 'canteen_3',
    'name': 'Science Canteen',
    'location': 'Science Complex',
    'rating': 4.0,
    'reviewCount': 95,
    'isOpen': false,
    'imageUrl': 'https://picsum.photos/seed/canteen3/200/200.jpg',
    'description': 'Fresh and healthy meals for science students',
    'openingTime': '08:30',
    'closingTime': '18:30',
  },
];

// Catalog Products Data
const List<Map<String, dynamic>> kCatalogProducts = [
  {
    'id': 'product_1',
    'name': 'Veg Burger',
    'description': 'Fresh vegetable patty with lettuce and sauce',
    'price': 89.99,
    'category': 'Burgers',
    'imageUrl': 'https://picsum.photos/seed/burger1/200/200.jpg',
    'stock': 50,
    'canteenId': 'canteen_1',
    'canteenName': 'Main Canteen',
    'rating': 4.5,
    'reviewCount': 25,
    'isFavorite': false,
  },
  {
    'id': 'product_2',
    'name': 'Chicken Pizza',
    'description': 'Classic chicken pizza with cheese and vegetables',
    'price': 199.99,
    'category': 'Pizza',
    'imageUrl': 'https://picsum.photos/seed/pizza1/200/200.jpg',
    'stock': 30,
    'canteenId': 'canteen_1',
    'canteenName': 'Main Canteen',
    'rating': 4.7,
    'reviewCount': 40,
    'isFavorite': false,
  },
  {
    'id': 'product_3',
    'name': 'Cold Coffee',
    'description': 'Refreshing cold coffee with ice cream',
    'price': 59.99,
    'category': 'Drinks',
    'imageUrl': 'https://picsum.photos/seed/coffee1/200/200.jpg',
    'stock': 100,
    'canteenId': 'canteen_2',
    'canteenName': 'Engineering Canteen',
    'rating': 4.3,
    'reviewCount': 60,
    'isFavorite': false,
  },
  {
    'id': 'product_4',
    'name': 'Chocolate Ice Cream',
    'description': 'Rich chocolate ice cream with toppings',
    'price': 79.99,
    'category': 'Desserts',
    'imageUrl': 'https://picsum.photos/seed/icecream1/200/200.jpg',
    'stock': 40,
    'canteenId': 'canteen_3',
    'canteenName': 'Science Canteen',
    'rating': 4.6,
    'reviewCount': 35,
    'isFavorite': false,
  },
  {
    'id': 'product_5',
    'name': 'French Fries',
    'description': 'Crispy golden french fries with seasoning',
    'price': 49.99,
    'category': 'Snacks',
    'imageUrl': 'https://picsum.photos/seed/fries1/200/200.jpg',
    'stock': 80,
    'canteenId': 'canteen_1',
    'canteenName': 'Main Canteen',
    'rating': 4.4,
    'reviewCount': 55,
    'isFavorite': false,
  },
  {
    'id': 'product_6',
    'name': 'Veg Sandwich',
    'description': 'Healthy vegetable sandwich with fresh ingredients',
    'price': 69.99,
    'category': 'Snacks',
    'imageUrl': 'https://picsum.photos/seed/sandwich1/200/200.jpg',
    'stock': 60,
    'canteenId': 'canteen_2',
    'canteenName': 'Engineering Canteen',
    'rating': 4.2,
    'reviewCount': 30,
    'isFavorite': false,
  },
];
