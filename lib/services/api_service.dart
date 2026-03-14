import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  // Authentication methods
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String userType = 'customer', // Default user type
    String? studentType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'userType': userType,
          'studentType': studentType,
        }),
      );

      debugPrint('🔥 Register response status: ${response.statusCode}');
      debugPrint('🔥 Register response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('🔥 Login response status: ${response.statusCode}');
      debugPrint('🔥 Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token to AuthService
        final token = responseData['data']['token'];
        if (token != null) {
          await AuthService.saveToken(token);
        }
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      debugPrint('❌ Login network error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      debugPrint('🔍 Fetching user profile...');
      debugPrint('📍 URL: ${AppConfig.baseUrl}${AppConfig.profileEndpoint}');
      debugPrint('🔑 Token: ${token.isNotEmpty ? "Present" : "Missing"}');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 Profile response status: ${response.statusCode}');
      debugPrint('📄 Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Profile data received: ${responseData['data']}');
          return {'success': true, 'data': responseData['data']};
        } else {
          debugPrint('❌ Profile API returned success: false');
          return {
            'success': false,
            'error': responseData['error'] ?? 'Profile fetch failed',
          };
        }
      } else {
        debugPrint(
          '❌ Profile fetch failed with status: ${response.statusCode}',
        );
        return {
          'success': false,
          'error':
              'Failed to get user profile (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('💥 Profile fetch error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      debugPrint('🔍 Fetching products...');
      debugPrint('📍 URL: ${AppConfig.baseUrl}${AppConfig.productsEndpoint}');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.productsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Products response status: ${response.statusCode}');
      debugPrint('📄 Products response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Products data received: ${responseData['data']}');
          return {'success': true, 'data': responseData['data']};
        } else {
          debugPrint('❌ Products API returned success: false');
          return {
            'success': false,
            'error': responseData['error'] ?? 'Products fetch failed',
          };
        }
      } else {
        debugPrint(
          '❌ Products fetch failed with status: ${response.statusCode}',
        );
        return {
          'success': false,
          'error': 'Failed to get products (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('💥 Products fetch error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCanteens() async {
    try {
      debugPrint('🔍 Fetching canteens...');
      debugPrint('📍 URL: ${AppConfig.baseUrl}/api/canteens');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/canteens'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Canteens response status: ${response.statusCode}');
      debugPrint('📄 Canteens response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Canteens data received: ${responseData['data']}');
          return {'success': true, 'data': responseData['data']};
        } else {
          debugPrint('❌ Canteens API returned success: false');
          return {
            'success': false,
            'error': responseData['error'] ?? 'Canteens fetch failed',
          };
        }
      } else {
        debugPrint(
          '❌ Canteens fetch failed with status: ${response.statusCode}',
        );
        return {
          'success': false,
          'error': 'Failed to get canteens (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('💥 Canteens fetch error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing connection to backend...');
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}${AppConfig.productsEndpoint}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            Duration(seconds: AppConfig.connectionTimeout.inSeconds),
            onTimeout: () {
              debugPrint('⏰ Connection test timed out');
              throw Exception('Connection timeout');
            },
          );

      final isConnected = response.statusCode == 200;
      debugPrint(
        '📡 Connection test result: ${isConnected ? "Connected" : "Failed"}',
      );
      return isConnected;
    } catch (e) {
      debugPrint('💥 Connection test failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.ordersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items,
          'totalAmount': totalAmount,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getMyOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.myOrdersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get orders'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.productsEndpoint}/$productId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get product'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? userType,
    String? studentType,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (userType != null) body['userType'] = userType;
      if (studentType != null) body['studentType'] = studentType;
      if (password != null) body['password'] = password;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Profile update failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> uploadImage({
    required String token,
    required String imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Image upload failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Admin endpoints
  static Future<Map<String, dynamic>> getAllUsers(String adminToken) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.adminUsersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAllOrders(String adminToken) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.adminOrdersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to get orders'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<void> logout() async {
    // Implement logout logic if needed (clear token on server)
    // For now, just clear local storage
  }

  static Future<bool> isLoggedIn() async {
    // Check if token exists and is valid
    // This would need token storage implementation
    return false;
  }

  // Helper method to get current base URL for debugging
  static String getCurrentBaseUrl() {
    return AppConfig.validateAndGetBaseUrl();
  }
}
