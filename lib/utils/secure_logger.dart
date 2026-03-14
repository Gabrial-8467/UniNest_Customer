import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Secure logging utility that only logs in debug mode
/// and sanitizes sensitive information
class SecureLogger {
  static const List<String> _sensitiveKeywords = [
    'token',
    'password',
    'secret',
    'key',
    'auth',
    'credential',
    'session',
  ];

  /// Log debug information only in debug mode
  static void debug(String message, {String? tag}) {
    if (!AppConfig.enableDebugLogging) return;

    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;

    if (kDebugMode) {
      print(formattedMessage);
    }
  }

  /// Log error information (always allowed in production for critical errors)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] ERROR: $sanitizedMessage'
        : 'ERROR: $sanitizedMessage';

    if (kDebugMode) {
      print(formattedMessage);
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    } else {
      // In production, you might want to send this to a logging service
      // For now, we'll use debugPrint for critical errors only
      debugPrint(formattedMessage);
    }
  }

  /// Log warning information
  static void warning(String message, {String? tag}) {
    if (!AppConfig.enableDebugLogging) return;

    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] WARNING: $sanitizedMessage'
        : 'WARNING: $sanitizedMessage';

    if (kDebugMode) {
      print(formattedMessage);
    }
  }

  /// Log information (only in debug mode)
  static void info(String message, {String? tag}) {
    if (!AppConfig.enableDebugLogging) return;

    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] INFO: $sanitizedMessage'
        : 'INFO: $sanitizedMessage';

    if (kDebugMode) {
      print(formattedMessage);
    }
  }

  /// Sanitize message to remove sensitive information
  static String _sanitizeMessage(String message) {
    String sanitized = message;

    // Remove potential sensitive data patterns
    for (final keyword in _sensitiveKeywords) {
      // Pattern to match keyword followed by : and potentially sensitive data
      final pattern = RegExp(
        '($keyword["\']?\\s*[:=]\\s*["\']?)([^"\\s,}]+)',
        caseSensitive: false,
      );
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}[REDACTED]';
      });
    }

    // Remove potential JWT tokens (long alphanumeric strings with dots)
    final jwtPattern = RegExp(
      r'[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
    );
    sanitized = sanitized.replaceAll(jwtPattern, '[JWT_TOKEN]');

    // Remove potential API keys (long alphanumeric strings)
    final apiKeyPattern = RegExp(r'[A-Za-z0-9]{20,}');
    sanitized = sanitized.replaceAll(apiKeyPattern, '[API_KEY]');

    // Remove email addresses
    final emailPattern = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    sanitized = sanitized.replaceAll(emailPattern, '[EMAIL]');

    return sanitized;
  }

  /// Log network request (sanitized)
  static void logRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (!AppConfig.enableDebugLogging) return;

    final sanitizedUrl = _sanitizeUrl(url);
    debug('$method $sanitizedUrl', tag: 'HTTP');

    if (body != null && kDebugMode) {
      final sanitizedBody = _sanitizeMap(body);
      debugPrint('Body: $sanitizedBody');
    }
  }

  /// Log network response (sanitized)
  static void logResponse(int statusCode, String url, {dynamic body}) {
    if (!AppConfig.enableDebugLogging) return;

    final sanitizedUrl = _sanitizeUrl(url);
    debug('Response $statusCode from $sanitizedUrl', tag: 'HTTP');

    if (body != null && kDebugMode) {
      final sanitizedBody = _sanitizeResponse(body);
      debugPrint('Response: $sanitizedBody');
    }
  }

  /// Sanitize URL to remove sensitive query parameters
  static String _sanitizeUrl(String url) {
    final uri = Uri.parse(url);
    final sanitizedQuery = <String, String>{};

    uri.queryParameters.forEach((key, value) {
      if (_sensitiveKeywords.any(
        (keyword) => key.toLowerCase().contains(keyword),
      )) {
        sanitizedQuery[key] = '[REDACTED]';
      } else {
        sanitizedQuery[key] = value;
      }
    });

    final sanitizedUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      queryParameters: sanitizedQuery.isEmpty ? null : sanitizedQuery,
    );

    return sanitizedUri.toString();
  }

  /// Sanitize map data
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (_sensitiveKeywords.any(
        (keyword) => key.toLowerCase().contains(keyword),
      )) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// Sanitize response data
  static dynamic _sanitizeResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return _sanitizeMap(data);
    } else if (data is String) {
      return _sanitizeMessage(data);
    } else {
      return data;
    }
  }
}
