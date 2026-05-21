import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import 'auth_service.dart';
import 'request_cache_service.dart';

class ApiService {
  static String get _baseUrl => AppConfig.getPublicApiBaseUrl();
  static String get _publicBaseUrl => AppConfig.getPublicApiBaseUrl();

  // Common headers
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Helper method for HTTP requests with caching support
  static Future<Map<String, dynamic>> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? queryParams,
    bool usePublicBaseUrl = false,
    bool skipCache = false,
    bool deduplicate = true,
  }) async {
    try {
      final uri = _buildUri(
        endpoint,
        queryParams: queryParams,
        usePublicBaseUrl: usePublicBaseUrl,
      );

      debugPrint('🔍 API Request: $method $uri');
      if (body != null) {
        debugPrint('📤 Request Body (Map): ${_sanitizeLogData(body)}');
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          // Use cached request for GET calls
          response = await RequestCacheService().execute(
            requestFn: () => http
                .get(uri, headers: _getHeaders(token: token))
                .timeout(AppConfig.connectionTimeout),
            method: 'GET',
            uri: uri,
            skipCache: skipCache,
            deduplicate: deduplicate,
          );
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: _getHeaders(token: token),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.connectionTimeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: _getHeaders(token: token),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.connectionTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: _getHeaders(token: token),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.connectionTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: _getHeaders(token: token))
              .timeout(AppConfig.connectionTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('💥 API Error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Uri _buildUri(
    String endpoint, {
    Map<String, String>? queryParams,
    bool usePublicBaseUrl = false,
  }) {
    final baseUrl = usePublicBaseUrl ? _publicBaseUrl : _baseUrl;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    final url = '$normalizedBase/$normalizedEndpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }

    return Uri.parse(url);
  }

  // Sanitize sensitive data for logging
  static Map<String, dynamic> _sanitizeLogData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('password')) {
      sanitized['password'] = '[REDACTED]';
    }
    if (sanitized.containsKey('currentPassword')) {
      sanitized['currentPassword'] = '[REDACTED]';
    }
    if (sanitized.containsKey('newPassword')) {
      sanitized['newPassword'] = '[REDACTED]';
    }
    return sanitized;
  }

  // ==================== AUTHENTICATION ENDPOINTS ====================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'customer',
    String? studentType,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        ...studentType != null ? {'studentType': studentType} : {},
      },
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );

    if (result['success'] == true) {
      final token = result['data']['token'] ?? '';
      final refreshToken = result['data']['refreshToken'] ?? '';

      if (token.isNotEmpty) {
        await AuthService.saveToken(token);
        await AuthService.saveRefreshToken(refreshToken);
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.refreshToken,
      token: refreshToken,
    );
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.forgotPassword,
      body: {'email': email},
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.resetPassword,
      body: {'token': token, 'password': password},
    );
  }

  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.verifyEmail,
      body: {'token': token},
    );
  }

  static Future<Map<String, dynamic>> logout(String token) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.logout,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.changePassword,
      token: token,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.profile,
      token: token,
    );
  }

  // Alias for backward compatibility
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    return await getProfile(token);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatar != null) body['avatar'] = avatar;

    return await _makeRequest(
      method: 'PUT',
      endpoint: ApiEndpoints.profile,
      token: token,
      body: body,
    );
  }

  static Future<Map<String, dynamic>> getAuthStatus(String token) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.authStatus,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> resendVerification(String token) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.resendVerification,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> deleteAccount(String token) async {
    return await _makeRequest(
      method: 'DELETE',
      endpoint: ApiEndpoints.deleteAccount,
      token: token,
    );
  }

  // ==================== HEALTH CHECK ENDPOINT ====================

  static Future<Map<String, dynamic>> getCustomerHealth() async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.health,
      usePublicBaseUrl: true,
    );
  }

  // ==================== CUSTOMER ENDPOINTS ====================

  static Future<Map<String, dynamic>> getVendors({
    String? token,
    String? category,
    String? search,
    String? status,
    String? sortBy,
    String? order,
    bool? isOpen,
    double? longitude,
    double? latitude,
    int? maxDistance,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (order != null) queryParams['order'] = order;
    if (isOpen != null) queryParams['isOpen'] = isOpen.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (maxDistance != null) {
      queryParams['maxDistance'] = maxDistance.toString();
    }

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.vendors,
      token: token,
      queryParams: queryParams,
      usePublicBaseUrl: true,
    );
  }

  // Alias for backward compatibility
  static Future<Map<String, dynamic>> getCanteens({String? token}) async {
    return await getVendors(token: token);
  }

  static Future<Map<String, dynamic>> getNearbyVendors({
    required String token,
    required double longitude,
    required double latitude,
    String? category,
    String? search,
    String? status,
    String? sortBy,
    String? order,
    int? maxDistance,
  }) async {
    final queryParams = <String, String>{
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (order != null) queryParams['order'] = order;
    if (maxDistance != null) {
      queryParams['maxDistance'] = maxDistance.toString();
    }

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.nearbyVendors,
      token: token,
      queryParams: queryParams,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> getVendorById({
    required String token,
    required String vendorId,
  }) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.vendorById(vendorId),
      token: token,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> getProducts({
    String? token,
    String? vendor,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    List<String>? dietary,
    double? rating,
    String? sortBy,
    String? order,
    bool? available,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (vendor != null) queryParams['vendor'] = vendor;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (dietary != null && dietary.isNotEmpty) {
      queryParams['dietary'] = dietary.join(',');
    }
    if (rating != null) queryParams['rating'] = rating.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (order != null) queryParams['sortOrder'] = order;
    if (available != null) queryParams['isAvailable'] = available.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.products,
      token: token,
      queryParams: queryParams,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> getFeaturedProducts({
    String? token,
    String? vendor,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    List<String>? dietary,
    double? rating,
    String? sortBy,
    String? order,
    bool? available,
  }) async {
    final queryParams = <String, String>{'featured': 'true'};
    if (vendor != null) queryParams['vendor'] = vendor;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (dietary != null && dietary.isNotEmpty) {
      queryParams['dietary'] = dietary.join(',');
    }
    if (rating != null) queryParams['rating'] = rating.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (order != null) queryParams['order'] = order;
    if (available != null) queryParams['available'] = available.toString();

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.products,
      token: token,
      queryParams: queryParams,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> getProductById({
    String? token,
    required String productId,
  }) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.productById(productId),
      token: token,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> createOrder({
    required String token,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? fulfillmentType,
    String? couponCode,
    String? vendorId,
  }) async {
    // Build items with 'productId' field and string quantity
    final List<Map<String, dynamic>> orderItems = [];
    for (final item in items) {
      final qty = item['quantity'];
      orderItems.add({
        'productId': (item['productId'] ?? item['product'] ?? item['id'] ?? '')
            .toString(),
        'quantity': (qty?.toString() ?? '1'),
      });
    }

    final methodValue = paymentMethod.toLowerCase() == 'cod'
        ? 'cod'
        : 'razorpay';

    // Build deliveryAddress with flat fields matching backend schema
    final deliveryBody = <String, dynamic>{
      'address': (deliveryAddress['address'] ?? '').toString(),
      'addressType':
          (deliveryAddress['type'] ??
                  deliveryAddress['addressType'] ??
                  'campus')
              .toString(),
      'building': (deliveryAddress['building'] ?? '').toString(),
      'room': (deliveryAddress['room'] ?? '').toString(),
    };

    // Add landmark if provided
    final landmark = (deliveryAddress['landmark'] ?? '').toString();
    if (landmark.isNotEmpty) {
      deliveryBody['landmark'] = landmark;
    }

    // Generate idempotency key to prevent duplicate orders on retries
    final idempotencyKey =
        'ord_${DateTime.now().millisecondsSinceEpoch}_${(1000 + Random().nextInt(8999))}';

    final body = <String, dynamic>{
      'items': orderItems,
      'paymentMethod': methodValue,
      'deliveryAddress': deliveryBody,
      'idempotencyKey': idempotencyKey,
      if (vendorId != null && vendorId.isNotEmpty) 'vendor': vendorId,
      if (fulfillmentType != null && fulfillmentType.isNotEmpty)
        'fulfillmentType': fulfillmentType,
    };

    final result = await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.orders,
      token: token,
      body: body,
    );

    return result;
  }

  static Future<Map<String, dynamic>> calculatePricingPreview({
    required String token,
    required List<Map<String, dynamic>> items,
    required String vendorId,
    String? offerCode,
    String? fulfillmentType,
  }) async {
    final List<Map<String, dynamic>> orderItems = [];
    for (final item in items) {
      final qty = item['quantity'];
      orderItems.add({
        'productId': (item['productId'] ?? item['product'] ?? item['id'] ?? '')
            .toString(),
        'quantity': (qty?.toString() ?? '1'),
      });
    }

    final body = <String, dynamic>{
      'items': orderItems,
      'vendorId': vendorId,
      if (offerCode != null && offerCode.isNotEmpty) 'offerCode': offerCode,
      if (fulfillmentType != null && fulfillmentType.isNotEmpty)
        'fulfillmentType': fulfillmentType,
    };

    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.calculatePricing,
      token: token,
      body: body,
    );
  }

  static Future<Map<String, dynamic>> getUserOrders({
    required String token,
    int? page,
    int? limit,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null) queryParams['status'] = status;

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.orders,
      token: token,
      queryParams: queryParams,
    );
  }

  static Future<Map<String, dynamic>> getOrderById({
    required String token,
    required String orderId,
  }) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.orderById(orderId),
      token: token,
    );
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required String token,
    required String orderId,
    required String reason,
  }) async {
    return await _makeRequest(
      method: 'PUT',
      endpoint: ApiEndpoints.cancelOrder(orderId),
      token: token,
      body: {'reason': reason},
    );
  }

  static Future<Map<String, dynamic>> rateOrder({
    required String token,
    required String orderId,
    required int food,
    required int overall,
    int? delivery,
    String? review,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: ApiEndpoints.reviewOrder(orderId),
      token: token,
      body: {
        'rating': {
          'food': food,
          'delivery': delivery ?? overall,
          'experience': overall,
        },
        'comment': review,
      },
    );
  }

  static Future<Map<String, dynamic>> getOrderStatistics(String token) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: '${ApiEndpoints.orders}/stats',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> search({
    String? token,
    String? query,
    String? category,
    String? vendor,
    String? vendorName,
    bool? featured,
    int? limit,
    int? skip,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (category != null) queryParams['category'] = category;
    if (vendor != null) queryParams['vendor'] = vendor;
    if (vendorName != null) queryParams['vendorName'] = vendorName;
    if (featured != null) queryParams['featured'] = featured.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (skip != null) queryParams['skip'] = skip.toString();

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.search,
      token: token,
      queryParams: queryParams,
      usePublicBaseUrl: true,
    );
  }

  static Future<Map<String, dynamic>> getCategories(String? token) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.categories,
      token: token,
      usePublicBaseUrl: true,
    );
  }

  // ==================== NOTIFICATION ENDPOINTS ====================

  static Future<Map<String, dynamic>> getNotifications({
    required String token,
    int? page,
    int? limit,
    bool? isRead,
    String? type,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (isRead != null) queryParams['isRead'] = isRead.toString();
    if (type != null) queryParams['type'] = type;

    final result = await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.notifications,
      token: token,
      queryParams: queryParams,
    );

    if (result['success'] != true) {
      return result;
    }

    final rawData = result['data'];
    final normalizedData = <String, dynamic>{};

    if (rawData is Map<String, dynamic>) {
      normalizedData.addAll(rawData);
    } else if (rawData is List) {
      normalizedData['notifications'] = rawData;
    } else {
      normalizedData['notifications'] = <dynamic>[];
    }

    final rawNotifications = normalizedData['notifications'];
    if (rawNotifications is List) {
      normalizedData['notifications'] = rawNotifications;
    } else if (rawNotifications is Map<String, dynamic>) {
      final nestedNotifications = rawNotifications['notifications'];
      if (nestedNotifications is List) {
        normalizedData['notifications'] = nestedNotifications;
      } else {
        normalizedData['notifications'] = rawNotifications.values
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    } else {
      normalizedData['notifications'] = <dynamic>[];
    }

    normalizedData['pagination'] =
        normalizedData['pagination'] is Map<String, dynamic>
        ? normalizedData['pagination']
        : <String, dynamic>{};
    normalizedData['unreadCount'] =
        (normalizedData['unreadCount'] as num?)?.toInt() ??
        ((normalizedData['pagination'] as Map<String, dynamic>)['total']
                as num?)
            ?.toInt() ??
        0;

    return {...result, 'data': normalizedData};
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead(
    String token,
  ) async {
    return await _makeRequest(
      method: 'PUT',
      endpoint: ApiEndpoints.markNotificationsRead,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> markNotificationAsRead({
    required String token,
    required String notificationId,
  }) async {
    return await _makeRequest(
      method: 'PUT',
      endpoint: '${ApiEndpoints.notifications}/$notificationId/read',
      token: token,
    );
  }

  // ==================== RAZORPAY PAYMENT ENDPOINTS ====================

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required String token,
    required String orderId,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: '${ApiEndpoints.orderById(orderId)}/payment/razorpay-order',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String token,
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _makeRequest(
      method: 'POST',
      endpoint: '${ApiEndpoints.orderById(orderId)}/payment/verify',
      token: token,
      body: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
  }

  // ==================== UTILITY METHODS ====================

  static Future<bool> testConnection() async {
    try {
      final result = await healthCheck();
      return result['success'] == true;
    } catch (e) {
      debugPrint('💥 Connection test failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    return await _makeRequest(method: 'GET', endpoint: ApiEndpoints.health);
  }

  static String getCurrentBaseUrl() {
    return _baseUrl;
  }

  // ==================== MULTIPART FORM DATA HELPER ====================

  static Future<Map<String, dynamic>> _makeMultipartRequest({
    required String method,
    required String endpoint,
    required String token,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    try {
      final uri = _buildUri(endpoint, usePublicBaseUrl: false);
      debugPrint('🔍 Multipart Request: $method $uri');

      http.MultipartRequest request;
      switch (method.toUpperCase()) {
        case 'POST':
          request = http.MultipartRequest('POST', uri);
          break;
        case 'PUT':
          request = http.MultipartRequest('PUT', uri);
          break;
        case 'PATCH':
          request = http.MultipartRequest('PATCH', uri);
          break;
        default:
          throw Exception('Unsupported multipart method: $method');
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(
        AppConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'error':
              responseData['error'] ??
              responseData['message'] ??
              'Request failed',
          'errorCode': responseData['errorCode'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('💥 Multipart API Error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== VENDOR PRODUCTS ENDPOINTS ====================

  static Future<int> _getFeaturedProductsCount(String token) async {
    final result = await getVendorProducts(
      token: token,
      isFeatured: true,
      limit: 1,
    );
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final pagination = data?['pagination'] as Map<String, dynamic>?;
      return (pagination?['total'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static Future<Map<String, dynamic>> getVendorProducts({
    required String token,
    bool? isFeatured,
    int? page,
    int? limit,
    String? category,
    String? status,
    String? availability,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, String>{};
    if (isFeatured != null) queryParams['isFeatured'] = isFeatured.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (category != null) queryParams['category'] = category;
    if (status != null) queryParams['status'] = status;
    if (availability != null) queryParams['availability'] = availability;
    if (search != null) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.vendorProducts,
      token: token,
      queryParams: queryParams,
    );
  }

  static Future<Map<String, dynamic>> createVendorProduct({
    required String token,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    String? availability,
    bool? isFeatured,
    List<http.MultipartFile>? images,
    String? imagesJson,
  }) async {
    // Check featured products limit before creating
    if (isFeatured == true) {
      final currentCount = await _getFeaturedProductsCount(token);
      if (currentCount >= ApiEndpoints.maxFeaturedProducts) {
        return {
          'success': false,
          'message':
              'Maximum ${ApiEndpoints.maxFeaturedProducts} featured products allowed per vendor',
          'errorCode': 'FEATURED_LIMIT_EXCEEDED',
        };
      }
    }

    final fields = <String, String>{
      'name': name,
      'description': description,
      'price': price.toString(),
      'category': category,
      'stock': stock.toString(),
    };

    if (availability != null) fields['availability'] = availability;
    if (isFeatured != null) fields['isFeatured'] = isFeatured.toString();
    if (imagesJson != null) fields['images'] = imagesJson;

    return await _makeMultipartRequest(
      method: 'POST',
      endpoint: ApiEndpoints.vendorProducts,
      token: token,
      fields: fields,
      files: images,
    );
  }

  static Future<Map<String, dynamic>> updateVendorProduct({
    required String token,
    required String productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? availability,
    String? category,
    bool? isFeatured,
    List<http.MultipartFile>? images,
    String? imagesJson,
  }) async {
    // Check featured products limit before updating
    if (isFeatured == true) {
      final currentCount = await _getFeaturedProductsCount(token);
      if (currentCount >= ApiEndpoints.maxFeaturedProducts) {
        return {
          'success': false,
          'message':
              'Maximum ${ApiEndpoints.maxFeaturedProducts} featured products allowed per vendor',
          'errorCode': 'FEATURED_LIMIT_EXCEEDED',
        };
      }
    }

    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (description != null) fields['description'] = description;
    if (price != null) fields['price'] = price.toString();
    if (stock != null) fields['stock'] = stock.toString();
    if (availability != null) fields['availability'] = availability;
    if (category != null) fields['category'] = category;
    if (isFeatured != null) fields['isFeatured'] = isFeatured.toString();
    if (imagesJson != null) fields['images'] = imagesJson;

    return await _makeMultipartRequest(
      method: 'PUT',
      endpoint: ApiEndpoints.vendorProductById(productId),
      token: token,
      fields: fields.isNotEmpty ? fields : null,
      files: images,
    );
  }

  static Future<Map<String, dynamic>> patchVendorProduct({
    required String token,
    required String productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? availability,
    String? category,
    bool? isFeatured,
    List<http.MultipartFile>? images,
    String? imagesJson,
  }) async {
    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (description != null) fields['description'] = description;
    if (price != null) fields['price'] = price.toString();
    if (stock != null) fields['stock'] = stock.toString();
    if (availability != null) fields['availability'] = availability;
    if (category != null) fields['category'] = category;
    if (isFeatured != null) fields['isFeatured'] = isFeatured.toString();
    if (imagesJson != null) fields['images'] = imagesJson;

    return await _makeMultipartRequest(
      method: 'PATCH',
      endpoint: ApiEndpoints.vendorProductById(productId),
      token: token,
      fields: fields.isNotEmpty ? fields : null,
      files: images,
    );
  }

  static Future<Map<String, dynamic>> getVendorProductById({
    required String token,
    required String productId,
  }) async {
    return await _makeRequest(
      method: 'GET',
      endpoint: ApiEndpoints.vendorProductById(productId),
      token: token,
    );
  }

  static Future<Map<String, dynamic>> deleteVendorProduct({
    required String token,
    required String productId,
  }) async {
    return await _makeRequest(
      method: 'DELETE',
      endpoint: ApiEndpoints.vendorProductById(productId),
      token: token,
    );
  }
}
