import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/secure_logger.dart';

class AppConfig {
  // Environment configuration
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (isDebugMode) {
        SecureLogger.warning('Could not load .env file: $e');
      }
      // Fallback to default values
    }
  }

  // API Configuration
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback for development
    if (isDebugMode) {
      return 'http://192.168.1.18:5000';
    }

    // Production fallback
    return 'https://your-production-api.com';
  }

  // Security Settings
  static bool get enforceHttps {
    final enforce = dotenv.env['ENFORCE_HTTPS'];
    if (enforce != null) {
      return enforce.toLowerCase() == 'true';
    }
    return !isDebugMode; // Enforce HTTPS in release mode
  }

  static int get connectionTimeoutSeconds {
    final timeout = dotenv.env['API_TIMEOUT_SECONDS'];
    return timeout != null ? int.tryParse(timeout) ?? 30 : 30;
  }

  // Feature Flags
  static bool get enableDebugLogging {
    final enable = dotenv.env['ENABLE_DEBUG_LOGGING'];
    if (enable != null) {
      return enable.toLowerCase() == 'true';
    }
    return isDebugMode;
  }

  static bool get enableAnalytics {
    final enable = dotenv.env['ENABLE_ANALYTICS'];
    if (enable != null) {
      return enable.toLowerCase() == 'true';
    }
    return isReleaseMode;
  }

  // Security Keys
  static String get encryptionKey {
    return dotenv.env['ENCRYPTION_KEY'] ?? '';
  }

  static String get jwtSecret {
    return dotenv.env['JWT_SECRET'] ?? '';
  }

  // Network timeout settings
  static Duration get connectionTimeout =>
      Duration(seconds: connectionTimeoutSeconds);
  static Duration get receiveTimeout =>
      Duration(seconds: connectionTimeoutSeconds);

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

  // Helper method to validate and secure URL
  static String validateAndGetBaseUrl() {
    String url = baseUrl;

    // Enforce HTTPS in production if enabled
    if (enforceHttps && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    if (isDebugMode &&
        (url.contains('localhost') || url.contains('127.0.0.1'))) {
      SecureLogger.warning(
        '⚠️ WARNING: Using localhost/127.0.0.1. This won\'t work on physical devices!',
      );
      SecureLogger.warning(
        'Please change to your computer\'s local IP address (e.g., 192.168.1.x)',
      );
    }

    return url;
  }

  // Validate if URL is secure
  static bool isSecureUrl(String url) {
    return url.startsWith('https://');
  }

  // Get secure base URL
  static String getSecureBaseUrl() {
    final url = validateAndGetBaseUrl();
    if (enforceHttps && !isSecureUrl(url)) {
      throw Exception('Insecure URL detected. HTTPS is required.');
    }
    return url;
  }
}
