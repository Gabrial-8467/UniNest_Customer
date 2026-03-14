import 'dart:io';
import '../config/app_config.dart';
import '../utils/secure_logger.dart';

/// SSL Certificate validation utility for secure HTTPS connections
class SSLValidator {
  /// Validate SSL certificate for HTTPS connections
  static bool validateCertificate(String url) {
    try {
      final uri = Uri.parse(url);

      // Only validate HTTPS URLs
      if (!uri.scheme.startsWith('https')) {
        if (AppConfig.enforceHttps) {
          SecureLogger.error('Insecure URL detected: $url', tag: 'SSL');
          return false;
        }
        SecureLogger.warning('Using HTTP connection: $url', tag: 'SSL');
        return true;
      }

      // Additional SSL validation can be added here
      // For now, we rely on Flutter's built-in SSL validation
      return _performSSLChecks(uri);
    } catch (e) {
      SecureLogger.error(
        'SSL validation failed for $url',
        error: e,
        tag: 'SSL',
      );
      return false;
    }
  }

  /// Perform additional SSL checks
  static bool _performSSLChecks(Uri uri) {
    try {
      // Check for common SSL issues
      if (uri.host.contains('localhost') || uri.host.contains('127.0.0.1')) {
        if (AppConfig.isReleaseMode) {
          SecureLogger.error(
            'Localhost detected in release mode: ${uri.host}',
            tag: 'SSL',
          );
          return false;
        }
        SecureLogger.warning(
          'Using localhost in debug mode: ${uri.host}',
          tag: 'SSL',
        );
      }

      // Check for IP addresses (should use domain names in production)
      if (_isIpAddress(uri.host) && AppConfig.isReleaseMode) {
        SecureLogger.error(
          'IP address detected in release mode: ${uri.host}',
          tag: 'SSL',
        );
        return false;
      }

      return true;
    } catch (e) {
      SecureLogger.error('SSL checks failed', error: e, tag: 'SSL');
      return false;
    }
  }

  /// Check if host is an IP address
  static bool _isIpAddress(String host) {
    final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    return ipPattern.hasMatch(host);
  }

  /// Get secure HTTP client with SSL validation
  static HttpClient getSecureHttpClient() {
    final client = HttpClient();

    // Enforce SSL certificate validation
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          if (AppConfig.isDebugMode) {
            // In debug mode, be more permissive but still log
            SecureLogger.warning(
              'Accepting certificate for $host:$port in debug mode',
              tag: 'SSL',
            );
            return true;
          }

          // In release mode, be strict
          SecureLogger.error(
            'Bad certificate rejected for $host:$port',
            tag: 'SSL',
          );
          return false;
        };

    return client;
  }

  /// Validate API endpoint security
  static bool validateApiEndpoint(String endpoint) {
    try {
      final fullUrl = '${AppConfig.getSecureBaseUrl()}$endpoint';
      return validateCertificate(fullUrl);
    } catch (e) {
      SecureLogger.error(
        'Failed to validate API endpoint: $endpoint',
        error: e,
        tag: 'SSL',
      );
      return false;
    }
  }

  /// Check if connection is secure
  static bool isSecureConnection(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https';
    } catch (e) {
      SecureLogger.error(
        'Failed to check connection security for $url',
        error: e,
        tag: 'SSL',
      );
      return false;
    }
  }

  /// Enforce HTTPS for production
  static String enforceHttps(String url) {
    if (AppConfig.enforceHttps && url.startsWith('http://')) {
      final secureUrl = url.replaceFirst('http://', 'https://');
      SecureLogger.info('Enforced HTTPS: $url -> $secureUrl', tag: 'SSL');
      return secureUrl;
    }
    return url;
  }
}
