import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/secure_logger.dart';

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _enforceHttps = String.fromEnvironment('ENFORCE_HTTPS');
  static const String _apiTimeoutSeconds = String.fromEnvironment(
    'API_TIMEOUT_SECONDS',
  );
  static const String _enableDebugLogging = String.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
  );
  static const String _enableAnalytics = String.fromEnvironment(
    'ENABLE_ANALYTICS',
  );
  static const String _encryptionKey = String.fromEnvironment('ENCRYPTION_KEY');
  static const String _jwtSecret = String.fromEnvironment('JWT_SECRET');
  static const String _razorpayKey = String.fromEnvironment('RAZORPAY_KEY');

  // Environment configuration
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(
        fileName: kIsWeb ? 'assets/env/app_config.txt' : '.env',
        isOptional: true,
        mergeWith: _dartDefineEnv,
      );
    } catch (e) {
      dotenv.testLoad(mergeWith: _dartDefineEnv);
      if (isDebugMode) {
        debugPrint('WARNING: Could not load environment config: $e');
      }
      // Fallback to default values
    }
  }

  static Map<String, String> get _dartDefineEnv {
    return {
      if (_apiBaseUrl.trim().isNotEmpty) 'API_BASE_URL': _apiBaseUrl.trim(),
      if (_enforceHttps.trim().isNotEmpty)
        'ENFORCE_HTTPS': _enforceHttps.trim(),
      if (_apiTimeoutSeconds.trim().isNotEmpty)
        'API_TIMEOUT_SECONDS': _apiTimeoutSeconds.trim(),
      if (_enableDebugLogging.trim().isNotEmpty)
        'ENABLE_DEBUG_LOGGING': _enableDebugLogging.trim(),
      if (_enableAnalytics.trim().isNotEmpty)
        'ENABLE_ANALYTICS': _enableAnalytics.trim(),
      if (_encryptionKey.trim().isNotEmpty)
        'ENCRYPTION_KEY': _encryptionKey.trim(),
      if (_jwtSecret.trim().isNotEmpty) 'JWT_SECRET': _jwtSecret.trim(),
      if (_razorpayKey.trim().isNotEmpty) 'RAZORPAY_KEY': _razorpayKey.trim(),
    };
  }

  static String? _envValue(String key) {
    if (!dotenv.isInitialized) {
      return _dartDefineEnv[key];
    }

    return dotenv.env[key] ?? _dartDefineEnv[key];
  }

  // API Configuration
  static String get baseUrl {
    final envUrl = _envValue('API_BASE_URL')?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }
    throw StateError(
      'API_BASE_URL is missing in environment config. Expected Render backend URL.',
    );
  }

  // Security Settings
  static bool get enforceHttps {
    final enforce = _envValue('ENFORCE_HTTPS');
    if (enforce != null) {
      return enforce.toLowerCase() == 'true';
    }
    return !isDebugMode; // Enforce HTTPS in release mode
  }

  static int get connectionTimeoutSeconds {
    final timeout = _envValue('API_TIMEOUT_SECONDS');
    return timeout != null ? int.tryParse(timeout) ?? 30 : 30;
  }

  // Feature Flags
  static bool get enableDebugLogging {
    final enable = _envValue('ENABLE_DEBUG_LOGGING');
    if (enable != null) {
      return enable.toLowerCase() == 'true';
    }
    return isDebugMode;
  }

  static bool get enableAnalytics {
    final enable = _envValue('ENABLE_ANALYTICS');
    if (enable != null) {
      return enable.toLowerCase() == 'true';
    }
    return isReleaseMode;
  }

  // Security Keys
  static String get encryptionKey {
    return _envValue('ENCRYPTION_KEY') ?? '';
  }

  static String get jwtSecret {
    return _envValue('JWT_SECRET') ?? '';
  }

  // Razorpay Configuration
  static String get razorpayKey {
    return _envValue('RAZORPAY_KEY') ?? '';
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
