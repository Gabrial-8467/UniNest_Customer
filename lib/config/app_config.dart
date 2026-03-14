import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment configuration
  static const bool isDebugMode = true;

  // API Configuration
  // For physical device testing, use your computer's local IP address
  // To find your IP:
  // - Windows: ipconfig in command prompt
  // - Mac: ifconfig or ip a in terminal
  // - The IP should look like: 192.168.1.x or 10.0.0.x

  // Default configuration for physical device
  static const String _baseUrl = 'http://192.168.1.18:5000';

  // Alternative configurations (uncomment and modify as needed)
  // static const String _baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  // static const String _baseUrl = 'http://127.0.0.1:5000'; // For iOS simulator
  // static const String _baseUrl = 'http://localhost:5000'; // For development/testing
  // static const String _baseUrl = 'https://your-production-api.com'; // For production

  static String get baseUrl {
    if (isDebugMode) {
      return _baseUrl;
    }
    return _baseUrl; // Change to production URL when ready
  }

  // Network timeout settings - reduced for faster response
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // API endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String profileEndpoint = '/api/auth/profile';
  static const String productsEndpoint = '/api/products';
  static const String ordersEndpoint = '/api/orders';
  static const String myOrdersEndpoint = '/api/orders/myorders';
  static const String uploadEndpoint = '/api/upload';
  static const String adminUsersEndpoint = '/api/admin/users';
  static const String adminOrdersEndpoint = '/api/admin/orders';

  // Helper method to validate IP configuration
  static String validateAndGetBaseUrl() {
    final url = baseUrl;
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      debugPrint(
        '⚠️ WARNING: Using localhost/127.0.0.1. This won\'t work on physical devices!',
      );
      debugPrint(
        'Please change to your computer\'s local IP address (e.g., 192.168.1.x)',
      );
    }
    return url;
  }
}
