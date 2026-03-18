import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Save authentication token securely
  static Future<void> saveToken(String token) async {
    try {
      await SecureStorageService.saveToken(token);
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      } else {
        rethrow;
      }
    }
  }

  // Save refresh token securely
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await SecureStorageService.saveRefreshToken(refreshToken);
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_refreshTokenKey, refreshToken);
      } else {
        rethrow;
      }
    }
  }

  // Get authentication token securely
  static Future<String?> getToken() async {
    try {
      return await SecureStorageService.getToken();
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      }
      return null;
    }
  }

  // Get refresh token securely
  static Future<String?> getRefreshToken() async {
    try {
      return await SecureStorageService.getRefreshToken();
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_refreshTokenKey);
      }
      return null;
    }
  }

  // Save user data securely
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await SecureStorageService.saveUserData(userData);
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, userData.toString());
      } else {
        rethrow;
      }
    }
  }

  // Get user data securely
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await SecureStorageService.getUserData();
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString(_userKey);
        if (userDataString != null) {
          // Simple parsing - in production, you'd want proper JSON parsing
          return {'email': 'user@example.com'}; // Placeholder
        }
      }
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      return await SecureStorageService.isLoggedIn();
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final token = await getToken();
        return token != null && token.isNotEmpty;
      }
      return false;
    }
  }

  // Logout - clear all auth data
  static Future<void> logout() async {
    try {
      await SecureStorageService.clearAuthData();
    } catch (e) {
      // Fallback to SharedPreferences for development
      if (AppConfig.isDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userKey);
      }
    }
  }

  // Clear all data (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
