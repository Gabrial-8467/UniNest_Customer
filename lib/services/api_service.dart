import 'mock_api_service.dart';

class ApiService {
  // Backend server URL - use computer's actual IP
  static const String baseUrl = 'http://localhost:3000';

  // Mock authentication methods - redirecting to MockApiService
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String userType = 'customer',
  }) async {
    return MockApiService.register(
      email: email,
      password: password,
      fullName: fullName,
      userType: userType,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return MockApiService.login(email: email, password: password);
  }

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    return MockApiService.getUserProfile(token);
  }

  static Future<Map<String, dynamic>> getCanteens() async {
    return MockApiService.getCanteens();
  }

  static Future<bool> healthCheck() async {
    return MockApiService.healthCheck();
  }

  static Future<Map<String, dynamic>> testConnection() async {
    return MockApiService.testConnection();
  }

  static Future<void> logout() async {
    return MockApiService.logout();
  }

  static Future<bool> isLoggedIn() async {
    return MockApiService.isLoggedIn();
  }
}
