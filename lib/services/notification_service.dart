import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'auth_service.dart';
import 'dart:async';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Request permission (iOS only, Android auto-grants)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notifications denied');
      return;
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _registerTokenWithBackend(newToken);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground notification: ${message.notification?.title}');

      // Broadcast notification to UI
      final notificationData = {
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _notificationController.add(notificationData);
    });

    // App opened from notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Opened from notification: ${message.data}');
      _handleNotificationTap(message.data);
    });
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Get actual JWT token from AuthService
      final authToken = await AuthService.getToken();

      if (authToken == null || authToken.isEmpty) {
        debugPrint('❌ No auth token available for FCM registration');
        return;
      }

      // Call your backend API
      final response = await http.post(
        Uri.parse(
          'https://uninest-backend.onrender.com/api/notifications/register-token',
        ),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': token,
          'deviceType': 'android', // or 'ios'
          'deviceName': 'User Device',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token registered successfully');
      } else {
        debugPrint('Failed to register token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final orderId = data['orderId'];

    debugPrint('Notification tap - type: $type, orderId: $orderId');

    switch (type) {
      case 'order':
        // Navigate to order detail screen
        // Navigator.push(context, OrderDetailPage(orderId: orderId));
        break;
      default:
        // Navigate to home or notifications screen
        break;
    }
  }

  /// Get the current FCM token (useful for testing)
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Test FCM token registration (for development testing)
  static Future<void> testTokenRegistration() async {
    try {
      final token = await getToken();
      if (token != null) {
        debugPrint('🔍 Test: FCM token obtained: ${token.substring(0, 20)}...');

        // Get actual JWT token from AuthService
        final authToken = await AuthService.getToken();

        if (authToken == null || authToken.isEmpty) {
          debugPrint('❌ Test: No auth token available - please login first');
          return;
        }

        debugPrint('🔍 Test: Auth token available, attempting registration...');

        final response = await http.post(
          Uri.parse(
            'https://uninest-backend.onrender.com/api/notifications/register-token',
          ),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'fcmToken': token,
            'deviceType': 'android',
            'deviceName': 'User Device',
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Test: FCM token registered successfully');
        } else {
          debugPrint('❌ Test: Registration failed - ${response.body}');
        }
      } else {
        debugPrint('❌ Test: Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('❌ Test: Error testing token registration: $e');
    }
  }
}
