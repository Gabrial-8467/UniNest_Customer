import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'order_tracking.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showBackButton;

  const NotificationsScreen({super.key, this.showBackButton = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMoreData = false;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  static const String _menuMarkAllRead = 'mark_all_read';
  static const String _menuClearAll = 'clear_all';
  static const String _clearedNotificationsKey = 'cleared_notification_ids';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = NotificationService.onNotification.listen((
      notificationData,
    ) {
      if (mounted) {
        final title = notificationData['title']?.toString().trim() ?? '';
        final message = notificationData['body']?.toString().trim() ?? '';

        // Only add notification if it has actual content
        if (title.isNotEmpty || message.isNotEmpty) {
          setState(() {
            // Add new notification to the beginning of the list
            notifications.insert(0, {
              '_id': DateTime.now().millisecondsSinceEpoch.toString(),
              'title': title,
              'message': message,
              'isRead': false,
              'createdAt':
                  notificationData['timestamp'] ??
                  DateTime.now().toIso8601String(),
              'data': notificationData['data'] ?? {},
            });
          });

          // Update notification count in app state
          AppStateScope.of(context).updateNotificationCount(
            notifications.where((n) => !(n['isRead'] ?? false)).length,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        notifications = [];
      });
    }

    setState(() {
      if (refresh) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage = 'Please login to view notifications';
        });
        return;
      }

      final result = await ApiService.getNotifications(
        token: token,
        page: currentPage,
        limit: 20,
      );

      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final clearedNotificationIds = await _getClearedNotificationIds();
        // Handle different API response structures
        final notificationsData = data['notifications'];
        final List<dynamic> newNotifications;
        if (notificationsData is List) {
          newNotifications = notificationsData;
        } else if (notificationsData is Map) {
          // If notifications is a map, try to extract values or use empty list
          newNotifications = notificationsData.values.toList();
        } else {
          newNotifications = [];
        }
        final pagination = data['pagination'] ?? {};

        setState(() {
          final castNotifications = newNotifications
              .whereType<Map<String, dynamic>>()
              .where((notification) {
                final notificationId = (notification['_id'] ?? '').toString();
                return notificationId.isEmpty ||
                    !clearedNotificationIds.contains(notificationId);
              })
              .toList();
          if (refresh || currentPage == 1) {
            notifications = castNotifications;
          } else {
            notifications.addAll(castNotifications);
          }
          totalPages = pagination['pages'] ?? 1;
          hasMoreData = currentPage < totalPages;
          isLoading = false;
          isLoadingMore = false;
        });
        if (mounted) {
          final readIds = notifications
              .where((n) => n['isRead'] == true)
              .map((n) => (n['_id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          AppStateScope.of(context).updateNotificationCount(
            notifications.where((n) => !(n['isRead'] ?? false)).length,
            readNotificationIds: readIds,
          );
        }
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Failed to load notifications';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMoreData) return;
    setState(() {
      currentPage++;
    });
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await ApiService.markAllNotificationsRead(token);
      if (result['success'] == true) {
        await _loadNotifications(refresh: true);
        if (mounted) {
          final allIds = notifications
              .map((n) => (n['_id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          AppStateScope.of(
            context,
          ).updateNotificationCount(0, readNotificationIds: allIds);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text(
          'This will remove all notifications from this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    final notificationIds = notifications
        .map((notification) => (notification['_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    await _saveClearedNotificationIds(notificationIds);

    if (!mounted) return;

    setState(() {
      notifications = [];
      currentPage = 1;
      totalPages = 1;
      hasMoreData = false;
    });
    final allIds = notificationIds.toList();
    AppStateScope.of(
      context,
    ).updateNotificationCount(0, readNotificationIds: allIds);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<Set<String>> _getClearedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_clearedNotificationsKey) ?? const <String>[])
        .toSet();
  }

  Future<void> _saveClearedNotificationIds(List<String> notificationIds) async {
    if (notificationIds.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final existingIds =
        prefs.getStringList(_clearedNotificationsKey) ?? const <String>[];
    final mergedIds = {...existingIds, ...notificationIds}.toList();
    await prefs.setStringList(_clearedNotificationsKey, mergedIds);
  }

  Future<void> _handleHeaderMenuAction(String action) async {
    switch (action) {
      case _menuMarkAllRead:
        await _markAllAsRead();
        break;
      case _menuClearAll:
        await _clearAllNotifications();
        break;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      // Mark as read locally first for instant feedback
      setState(() {
        final index = notifications.indexWhere(
          (n) => n['_id'] == notificationId,
        );
        if (index != -1) {
          notifications[index]['isRead'] = true;
        }
      });

      // Call API to mark single notification as read
      await ApiService.markNotificationAsRead(
        token: token,
        notificationId: notificationId,
      );

      // Update notification count in AppState
      if (mounted) {
        final appState = AppStateScope.of(context);
        final readIds = notifications
            .where((n) => n['isRead'] == true)
            .map((n) => (n['_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
        appState.updateNotificationCount(
          notifications.where((n) => !(n['isRead'] ?? false)).length,
          readNotificationIds: readIds,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'review':
        return Icons.star_outline;
      case 'system':
        return Icons.info_outline;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'account_alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'review':
        return AppColors.accent;
      case 'system':
        return AppColors.info;
      case 'promotion':
        return AppColors.secondary;
      case 'account_alert':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    _markAsRead(notification['_id'] ?? '');

    // Navigate based on notification type
    final type = notification['type'] ?? '';
    final data = notification['data'] ?? {};

    switch (type.toLowerCase()) {
      case 'order':
        final orderId = data['orderId'] ?? '';
        if (orderId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderTrackingScreen(orderId: orderId, showBackButton: true),
            ),
          );
        }
        break;
      case 'payment':
        final orderId = data['orderId'] ?? '';
        if (orderId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderTrackingScreen(orderId: orderId, showBackButton: true),
            ),
          );
        }
        break;
      default:
        // Just mark as read for other types
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: widget.showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleHeaderMenuAction,
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: _menuMarkAllRead,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.done_all),
                    title: Text('Mark all as read'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: _menuClearAll,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear all notifications'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadNotifications(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 80,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll notify you about orders, offers, and updates',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : ElevatedButton(
                      onPressed: _loadMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        final notification = notifications[index];
        final isRead = notification['isRead'] ?? false;
        final type = notification['type'] ?? 'system';
        final title = notification['title'] ?? '';
        final message = notification['message'] ?? '';
        final createdAt = notification['createdAt'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isRead
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimeAgo(createdAt),
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
            onTap: () => _handleNotificationTap(notification),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
