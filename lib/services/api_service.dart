import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Backend server URL
  static const String baseUrl = 'http://localhost:5000';

  // Register user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String userType = 'customer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'userType': userType,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
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

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get canteens
  static Future<Map<String, dynamic>> getCanteens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/canteens'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to get canteens',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Health check
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  // Test connectivity with detailed error
  static Future<Map<String, dynamic>> testConnection() async {
    final urls = [
      'http://localhost:5000',
      'http://10.0.2.2:5000',
      'http://127.0.0.1:5000',
    ];

    for (String url in urls) {
      for (String endpoint in ['/ping', '/health']) {
        try {
          final response = await http
              .get(Uri.parse('$url$endpoint'))
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            return {
              'success': true,
              'message': 'Backend is reachable',
              'baseUrl': url,
              'endpoint': endpoint,
              'statusCode': response.statusCode,
              'response': response.body,
            };
          }
        } catch (e) {
          debugPrint('Failed to connect to $url$endpoint: $e');
          continue; // Try next endpoint
        }
      }
    }

    return {
      'success': false,
      'error': 'Connection failed on all URLs and endpoints',
      'baseUrl': 'none',
      'testedUrls': urls,
    };
  }
}
