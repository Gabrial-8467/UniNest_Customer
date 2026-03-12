import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Users/data/mock_data.dart';

class MockApiService {
  // Mock user storage
  static const String _mockUserKey = 'mock_user_data';
  static const String _mockTokenKey = 'mock_auth_token';

  // Mock authentication
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String userType = 'customer',
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful registration
      final userData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'fullName': fullName,
        'userType': userType,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Store mock user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockUserKey, userData.toString());
      await prefs.setString(_mockTokenKey, 'mock_token_${DateTime.now().millisecondsSinceEpoch}');

      return {'success': true, 'data': userData};
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login for any email/password (for demo purposes)
      if (email.isNotEmpty && password.length >= 6) {
        final userData = {
          'id': 'mock_user_id',
          'email': email,
          'fullName': email.split('@')[0], // Extract name from email
          'userType': 'customer',
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        };

        // Store mock user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_mockUserKey, userData.toString());
        await prefs.setString(_mockTokenKey, userData['token']!);

        return {'success': true, 'data': userData};
      } else {
        return {'success': false, 'error': 'Invalid email or password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Login failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_mockUserKey);
      
      if (userData != null) {
        return {'success': true, 'data': {'user': userData}};
      } else {
        return {'success': false, 'error': 'User not found'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to get profile: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCanteens() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return {'success': true, 'data': kRegisteredCanteens};
    } catch (e) {
      return {'success': false, 'error': 'Failed to get canteens: ${e.toString()}'};
    }
  }

  static Future<bool> healthCheck() async {
    try {
      // Mock health check - always returns true for frontend-only
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      // Mock successful connection test
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'success': true,
        'message': 'Mock service is working',
        'baseUrl': 'mock://frontend-only',
        'endpoint': 'mock',
        'statusCode': 200,
        'response': 'Mock response - frontend is working without backend',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Mock service error: ${e.toString()}',
        'baseUrl': 'mock://frontend-only',
      };
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mockUserKey);
      await prefs.remove(_mockTokenKey);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_mockTokenKey);
      return token != null;
    } catch (e) {
      return false;
    }
  }
}
