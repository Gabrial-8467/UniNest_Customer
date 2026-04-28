import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'auth_service.dart';
import 'dart:async';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static const String _cachedNotificationsKey =
      'cached_foreground_notifications';

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
      debugPrint('=== NOTIFICATION DEBUG ===');
      debugPrint('Full message: ${message.toString()}');
      debugPrint('Notification title: ${message.notification?.title}');
      debugPrint('Notification body: ${message.notification?.body}');
      debugPrint('Message data: ${message.data}');

      // Extract title and message from notification object (primary)
      String title = message.notification?.title ?? '';
      String body = message.notification?.body ?? '';

      // Backend sends notification in notification object, fallback to data if needed
      if (title.isEmpty && message.data.isNotEmpty) {
        title = message.data['title']?.toString() ?? '';
      }
      if (body.isEmpty && message.data.isNotEmpty) {
        body =
            message.data['body']?.toString() ??
            message.data['message']?.toString() ??
            '';
      }

      debugPrint('=== EXTRACTED VALUES ===');
      debugPrint('Final title: "$title"');
      debugPrint('Final body: "$body"');
      debugPrint('Title empty: ${title.isEmpty}');
      debugPrint('Body empty: ${body.isEmpty}');

      // Broadcast notification to UI
      final notificationId =
          message.data['notificationId']?.toString() ??
          message.data['_id']?.toString() ??
          message.data['id']?.toString() ??
          message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final notificationData = {
        'notificationId': notificationId,
        'title': title,
        'body': body,
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('Broadcasting notification: $notificationData');
      unawaited(_cacheForegroundNotification(notificationData));
      _notificationController.add(notificationData);
      debugPrint('=== END NOTIFICATION DEBUG ===');
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

  static Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawNotifications =
          prefs.getStringList(_cachedNotificationsKey) ?? const <String>[];

      return rawNotifications
          .map((rawNotification) => jsonDecode(rawNotification))
          .whereType<Map>()
          .map((notification) => Map<String, dynamic>.from(notification))
          .toList();
    } catch (e) {
      debugPrint('Error reading cached notifications: $e');
      return const [];
    }
  }

  static Future<void> clearCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedNotificationsKey);
    } catch (e) {
      debugPrint('Error clearing cached notifications: $e');
    }
  }

  static Future<void> markCachedNotificationRead(String notificationId) async {
    if (notificationId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotifications = await getCachedNotifications();
      final updatedNotifications = cachedNotifications
          .map((notification) {
            if ((notification['_id'] ?? '').toString() == notificationId) {
              return {...notification, 'isRead': true};
            }
            return notification;
          })
          .map(jsonEncode)
          .toList();

      await prefs.setStringList(_cachedNotificationsKey, updatedNotifications);
    } catch (e) {
      debugPrint('Error marking cached notification as read: $e');
    }
  }

  static Future<void> _cacheForegroundNotification(
    Map<String, dynamic> notificationData,
  ) async {
    final title = notificationData['title']?.toString().trim() ?? '';
    final body =
        (notificationData['body'] ?? notificationData['message'])
            ?.toString()
            .trim() ??
        '';
    if (title.isEmpty && body.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotifications = await getCachedNotifications();
      final data = notificationData['data'] is Map
          ? Map<String, dynamic>.from(notificationData['data'] as Map)
          : const <String, dynamic>{};
      final notificationId =
          notificationData['notificationId']?.toString() ??
          notificationData['id']?.toString() ??
          data['notificationId']?.toString() ??
          data['_id']?.toString() ??
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final notification = {
        '_id': notificationId,
        'title': title,
        'message': body,
        'type':
            notificationData['type']?.toString() ??
            data['type']?.toString() ??
            'system',
        'isRead': false,
        'createdAt':
            notificationData['timestamp']?.toString() ??
            DateTime.now().toIso8601String(),
        'data': data,
      };
      final mergedNotifications = [
        notification,
        ...cachedNotifications.where(
          (cached) => (cached['_id'] ?? '').toString() != notificationId,
        ),
      ].take(50).map(jsonEncode).toList();

      await prefs.setStringList(_cachedNotificationsKey, mergedNotifications);
    } catch (e) {
      debugPrint('Error caching foreground notification: $e');
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
}
