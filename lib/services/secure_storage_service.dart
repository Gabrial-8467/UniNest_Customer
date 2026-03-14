import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage keys (hashed for additional security)
  static String _hashKey(String key) {
    final encryptionKey = AppConfig.encryptionKey;
    if (encryptionKey.isEmpty) {
      // Fallback to simple hashing if no encryption key is provided
      final bytes = utf8.encode(key);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
    final bytes = utf8.encode(key + encryptionKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Save authentication token securely
  static Future<void> saveToken(String token) async {
    try {
      final hashedKey = _hashKey('auth_token');
      await _storage.write(key: hashedKey, value: token);
    } catch (e) {
      throw Exception('Failed to save token securely: $e');
    }
  }

  // Get authentication token securely
  static Future<String?> getToken() async {
    try {
      final hashedKey = _hashKey('auth_token');
      return await _storage.read(key: hashedKey);
    } catch (e) {
      throw Exception('Failed to retrieve token securely: $e');
    }
  }

  // Save user data securely
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final hashedKey = _hashKey('user_data');
      final jsonString = jsonEncode(userData);
      await _storage.write(key: hashedKey, value: jsonString);
    } catch (e) {
      throw Exception('Failed to save user data securely: $e');
    }
  }

  // Get user data securely
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final hashedKey = _hashKey('user_data');
      final userDataString = await _storage.read(key: hashedKey);

      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve user data securely: $e');
    }
  }

  // Save refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      final hashedKey = _hashKey('refresh_token');
      await _storage.write(key: hashedKey, value: refreshToken);
    } catch (e) {
      throw Exception('Failed to save refresh token securely: $e');
    }
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final hashedKey = _hashKey('refresh_token');
      return await _storage.read(key: hashedKey);
    } catch (e) {
      throw Exception('Failed to retrieve refresh token securely: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _hashKey('auth_token'));
      await _storage.delete(key: _hashKey('user_data'));
      await _storage.delete(key: _hashKey('refresh_token'));
    } catch (e) {
      throw Exception('Failed to clear auth data securely: $e');
    }
  }

  // Clear all secure storage
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  // Check if storage contains key
  static Future<bool> containsKey(String key) async {
    try {
      final hashedKey = _hashKey(key);
      return await _storage.containsKey(key: hashedKey);
    } catch (e) {
      return false;
    }
  }

  // Get all keys (for debugging purposes only)
  static Future<Map<String, String>> getAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw Exception('Failed to read all secure storage data: $e');
    }
  }

  // Save biometric preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final hashedKey = _hashKey('biometric_enabled');
      await _storage.write(key: hashedKey, value: enabled.toString());
    } catch (e) {
      throw Exception('Failed to save biometric preference: $e');
    }
  }

  // Get biometric preference
  static Future<bool> isBiometricEnabled() async {
    try {
      final hashedKey = _hashKey('biometric_enabled');
      final value = await _storage.read(key: hashedKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }
}
