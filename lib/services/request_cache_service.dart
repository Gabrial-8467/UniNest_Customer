import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for caching API requests and deduplicating in-flight requests
/// to reduce server load significantly
class RequestCacheService {
  static final RequestCacheService _instance = RequestCacheService._internal();
  factory RequestCacheService() => _instance;
  RequestCacheService._internal();

  // Cache storage: key -> CachedResponse
  final Map<String, _CachedResponse> _cache = {};

  // In-flight request deduplication: key -> Completer
  final Map<String, Completer<http.Response>> _inFlightRequests = {};

  // Pending debounce timers: key -> Timer
  final Map<String, Timer> _debounceTimers = {};

  // Default cache TTL (Time To Live) durations by endpoint pattern
  static final Map<RegExp, Duration> _defaultTtls = {
    // Products and canteens change infrequently - cache for 5 minutes
    RegExp(r'/products|/vendors|/canteens'): const Duration(minutes: 5),
    // Categories almost never change - cache for 15 minutes
    RegExp(r'/categories'): const Duration(minutes: 15),
    // User-specific data changes occasionally - cache for 2 minutes
    RegExp(r'/orders|/profile|/notifications'): const Duration(minutes: 2),
    // Search results - cache for 1 minute (might change)
    RegExp(r'/search'): const Duration(minutes: 1),
    // Static/health data - cache for 10 minutes
    RegExp(r'/health|/config'): const Duration(minutes: 10),
  };

  // Minimum cache TTL (for dynamic data like order status)
  static const Duration minTtl = Duration(seconds: 5);

  // Maximum cache entries to prevent memory leaks
  static const int _maxCacheEntries = 100;

  /// Generate cache key from request details
  String _generateCacheKey(String method, Uri uri, {String? body}) {
    final keyParts = [method.toUpperCase(), uri.toString()];
    if (body != null && body.isNotEmpty) {
      keyParts.add(body);
    }
    return keyParts.join('|');
  }

  /// Get TTL for a given URL based on endpoint patterns
  Duration _getTtlForUrl(String url) {
    for (final entry in _defaultTtls.entries) {
      if (entry.key.hasMatch(url)) {
        return entry.value;
      }
    }
    // Default TTL for unrecognized endpoints
    return const Duration(minutes: 1);
  }

  /// Check if cache entry is still valid
  bool _isCacheValid(_CachedResponse? cached, Duration ttl) {
    if (cached == null) return false;
    final age = DateTime.now().difference(cached.timestamp);
    return age < ttl;
  }

  /// Clean old cache entries when cache gets too large
  void _cleanupCache() {
    if (_cache.length <= _maxCacheEntries) return;

    // Sort by timestamp (oldest first) and remove oldest entries
    final entries = _cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final entriesToRemove = entries.length - _maxCacheEntries;
    for (var i = 0; i < entriesToRemove; i++) {
      _cache.remove(entries[i].key);
    }

    if (kDebugMode) {
      debugPrint('🧹 Cache cleanup: removed $entriesToRemove entries');
    }
  }

  /// Execute HTTP request with caching and deduplication
  ///
  /// [requestFn] - Function that performs the actual HTTP request
  /// [method] - HTTP method (GET, POST, etc.)
  /// [uri] - Request URI
  /// [body] - Request body (for POST/PUT/PATCH)
  /// [customTtl] - Optional custom cache TTL (null = auto-detect)
  /// [skipCache] - Force fresh request, bypass cache
  /// [deduplicate] - Whether to deduplicate in-flight requests (default: true)
  ///
  Future<http.Response> execute({
    required Future<http.Response> Function() requestFn,
    required String method,
    required Uri uri,
    String? body,
    Duration? customTtl,
    bool skipCache = false,
    bool deduplicate = true,
  }) async {
    final cacheKey = _generateCacheKey(method, uri, body: body);
    final ttl = customTtl ?? _getTtlForUrl(uri.toString());

    // Check cache first (only for GET requests by default)
    if (!skipCache && method.toUpperCase() == 'GET') {
      final cached = _cache[cacheKey];
      if (cached != null && _isCacheValid(cached, ttl)) {
        if (kDebugMode) {
          debugPrint(
            '💾 Cache HIT: $method ${uri.path} (age: ${DateTime.now().difference(cached.timestamp).inSeconds}s)',
          );
        }
        return http.Response(
          cached.body,
          cached.statusCode,
          headers: cached.headers,
        );
      }
    }

    // Deduplicate in-flight requests
    if (deduplicate) {
      final existingCompleter = _inFlightRequests[cacheKey];
      if (existingCompleter != null && !existingCompleter.isCompleted) {
        if (kDebugMode) {
          debugPrint('🔄 Request deduplication: $method ${uri.path}');
        }
        return existingCompleter.future;
      }
    }

    // Create completer for deduplication
    final completer = Completer<http.Response>();
    _inFlightRequests[cacheKey] = completer;

    try {
      // Execute actual request
      if (kDebugMode) {
        debugPrint('🌐 Cache MISS: $method ${uri.path}');
      }

      final response = await requestFn();

      // Cache successful GET responses
      if (method.toUpperCase() == 'GET' &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        _cache[cacheKey] = _CachedResponse(
          body: response.body,
          statusCode: response.statusCode,
          headers: response.headers,
          timestamp: DateTime.now(),
        );
        _cleanupCache();
      }

      // Clear cache for modifying operations on the same resource
      if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase())) {
        _invalidateRelatedCache(uri);
      }

      completer.complete(response);
      return response;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Debounce rapid requests - only execute after [delay] of no new calls
  ///
  /// Returns a Future that completes with the response, or null if debounced
  Future<http.Response?> executeDebounced({
    required Future<http.Response> Function() requestFn,
    required String method,
    required Uri uri,
    String? body,
    Duration delay = const Duration(milliseconds: 300),
    Duration? customTtl,
    bool skipCache = false,
  }) async {
    final cacheKey = _generateCacheKey(method, uri, body: body);

    // Cancel existing debounce timer
    _debounceTimers[cacheKey]?.cancel();

    // Check cache immediately
    if (!skipCache && method.toUpperCase() == 'GET') {
      final cached = _cache[cacheKey];
      final ttl = customTtl ?? _getTtlForUrl(uri.toString());
      if (_isCacheValid(cached, ttl)) {
        return http.Response(
          cached!.body,
          cached.statusCode,
          headers: cached.headers,
        );
      }
    }

    // Create new debounced request
    final completer = Completer<http.Response?>();

    _debounceTimers[cacheKey] = Timer(delay, () async {
      try {
        final response = await execute(
          requestFn: requestFn,
          method: method,
          uri: uri,
          body: body,
          customTtl: customTtl,
          skipCache: skipCache,
        );
        completer.complete(response);
      } catch (error) {
        completer.completeError(error);
      } finally {
        _debounceTimers.remove(cacheKey);
      }
    });

    return completer.future;
  }

  /// Invalidate cache entries related to a specific URI
  void _invalidateRelatedCache(Uri uri) {
    final path = uri.path;
    final keysToRemove = _cache.keys.where((key) {
      // Invalidate exact match and parent collection
      return key.contains(path) ||
          (path.contains('/') &&
              key.contains(path.substring(0, path.lastIndexOf('/'))));
    }).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint(
        '🗑️ Cache invalidated for ${keysToRemove.length} entries related to $path',
      );
    }
  }

  /// Manually invalidate cache for a specific pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys
        .where((key) => regex.hasMatch(key))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint(
        '🗑️ Cache invalidated for pattern "$pattern": ${keysToRemove.length} entries',
      );
    }
  }

  /// Clear entire cache
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Entire cache cleared');
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    int validEntries = 0;
    int expiredEntries = 0;

    for (final entry in _cache.entries) {
      final ttl = _getTtlForUrl(entry.key);
      if (_isCacheValid(entry.value, ttl)) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'inFlightRequests': _inFlightRequests.length,
      'pendingDebounces': _debounceTimers.length,
    };
  }

  /// Pre-warm cache with data (useful for prefetching)
  void prewarmCache(
    String method,
    Uri uri,
    http.Response response, {
    String? body,
  }) {
    if (method.toUpperCase() != 'GET') return;

    final cacheKey = _generateCacheKey(method, uri, body: body);
    _cache[cacheKey] = _CachedResponse(
      body: response.body,
      statusCode: response.statusCode,
      headers: response.headers,
      timestamp: DateTime.now(),
    );
    _cleanupCache();

    if (kDebugMode) {
      debugPrint('🔥 Cache pre-warmed: ${uri.path}');
    }
  }
}

/// Internal class for cached response data
class _CachedResponse {
  final String body;
  final int statusCode;
  final Map<String, String> headers;
  final DateTime timestamp;

  _CachedResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.timestamp,
  });
}

/// Extension methods for easy cache integration
extension RequestCacheExtension on http.Client {
  /// Execute cached GET request
  Future<http.Response> getCached(
    Uri url, {
    Map<String, String>? headers,
    Duration? ttl,
    bool skipCache = false,
  }) async {
    return RequestCacheService().execute(
      requestFn: () => get(url, headers: headers),
      method: 'GET',
      uri: url,
      customTtl: ttl,
      skipCache: skipCache,
    );
  }

  /// Execute debounced GET request (for search/auto-complete)
  Future<http.Response?> getDebounced(
    Uri url, {
    Map<String, String>? headers,
    Duration delay = const Duration(milliseconds: 300),
    Duration? ttl,
  }) async {
    return RequestCacheService().executeDebounced(
      requestFn: () => get(url, headers: headers),
      method: 'GET',
      uri: url,
      delay: delay,
      customTtl: ttl,
    );
  }
}
