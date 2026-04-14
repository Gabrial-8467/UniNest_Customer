import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class Helpers {
  // Generate random ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  // Calculate distance between two coordinates (in km)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Check if email is valid (quick check)
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Check if phone is valid (Indian numbers)
  static bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  // Get screen size category
  static String getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 'mobile';
    if (width < 900) return 'tablet';
    return 'desktop';
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == 'tablet';
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == 'mobile';
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.grey[800],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  // Debounce function
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      if (timer != null) timer!.cancel();
      timer = Timer(delay, () => func());
    };
  }

  // Validate Indian pincode
  static bool isValidPincode(String pincode) {
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode);
  }

  // Get color for order status
  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate estimated delivery time
  static DateTime calculateEstimatedDelivery(String deliveryOption) {
    final now = DateTime.now();
    switch (deliveryOption.toLowerCase()) {
      case 'express':
        return now.add(const Duration(minutes: 30));
      case 'standard':
        return now.add(const Duration(minutes: 45));
      case 'schedule':
        return now.add(const Duration(hours: 1));
      default:
        return now.add(const Duration(minutes: 45));
    }
  }

  // Check if string is empty or whitespace
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  // Safe parse double
  static double safeParseDouble(String? value, {double defaultValue = 0.0}) {
    if (value == null || value.isEmpty) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  // Safe parse int
  static int safeParseInt(String? value, {int defaultValue = 0}) {
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
}
