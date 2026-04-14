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
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }
    throw StateError(
      'API_BASE_URL is missing in .env. Expected Render backend URL.',
    );
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

  static String getPublicApiBaseUrl() {
    final url = getSecureBaseUrl();
    // Remove trailing /api/customer or /api/public if present since endpoints already include them
    if (url.endsWith('/api/customer')) {
      return url.substring(0, url.length - '/api/customer'.length);
    }
    if (url.endsWith('/api/public')) {
      return url.substring(0, url.length - '/api/public'.length);
    }
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - '/api'.length);
    }
    if (url.endsWith('/customer')) {
      return url.substring(0, url.length - '/customer'.length);
    }
    return url;
  }

  static String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
