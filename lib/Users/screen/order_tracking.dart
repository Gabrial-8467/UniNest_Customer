import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'live_chat.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final bool showBackButton;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.showBackButton = true,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Update order status when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).updateOrderStatus(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final order = appState.getOrderById(widget.orderId);

        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Order Tracking'),
              backgroundColor: AppColors.surface,
              elevation: 0,
            ),
            body: const Center(child: Text('Order not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildOrderStatusCard(order),
                const SizedBox(height: 20),
                _buildTrackingTimeline(order),
                const SizedBox(height: 20),
                _buildOrderDetails(order),
                const SizedBox(height: 20),
                _buildActionButtons(order),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'Order Tracking',
        style: TextStyle(
          color: Color(0xFF2D3436),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            )
          : null,
      automaticallyImplyLeading: widget.showBackButton,
      actions: [
        IconButton(
          onPressed: () {
            // Refresh order status
            AppStateScope.of(context).updateOrderStatus(widget.orderId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status updated'),
                backgroundColor: Color(0xFFFF6B6B),
              ),
            );
          },
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildOrderStatusCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final estimatedDelivery = order['estimatedDelivery'] as DateTime;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Delivered':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'Out for Delivery':
        statusColor = AppColors.secondary;
        statusIcon = Icons.delivery_dining;
        break;
      case 'Preparing':
      case 'Ready for Pickup':
        statusColor = AppColors.accent;
        statusIcon = Icons.restaurant;
        break;
      default:
        statusColor = AppColors.textLight;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Order #${order['orderId']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (status != 'Delivered') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimated delivery: ${_formatTime(estimatedDelivery)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  Expanded(
                    child: Text(
                      'Order delivered successfully!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(Map<String, dynamic> order) {
    final trackingSteps = (order['trackingSteps'] as List)
        .cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...trackingSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == trackingSteps.length - 1;

            return _buildTrackingStep(
              step['title'],
              step['description'],
              step['time'] as DateTime,
              step['completed'] as bool,
              isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrackingStep(
    String title,
    String description,
    DateTime time,
    bool completed,
    bool isLast,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : Icons.access_time,
                color: completed ? Colors.white : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: completed
                          ? AppColors.textSecondary
                          : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(time),
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 16, top: 8),
            height: 40,
            width: 2,
            color: completed ? AppColors.primary : Colors.grey[300],
          ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Location
          if (order['delivery'] != null) ...[
            const Text(
              'Delivery Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDeliveryAddress(order['delivery']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Qty: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\u20B9${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _buildPriceRow('Subtotal', order['subtotal']),
          _buildPriceRow('Delivery Fee', order['deliveryFee']),
          _buildPriceRow('Platform Fee', order['platformFee']),
          _buildPriceRow('Tax', order['tax']),
          const Divider(height: 24),
          _buildPriceRow('Total', order['total'], isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '\u20B9${(amount as double).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = order['status'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (status == 'Out for Delivery') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeliveryPartnerInfo(),
                icon: const Icon(Icons.phone),
                label: const Text('Contact Delivery Partner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (status == 'Delivered') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRateOrderDialog(order),
                icon: const Icon(Icons.star),
                label: const Text('Rate Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showOrderHelp(),
              icon: const Icon(Icons.help_outline),
              label: const Text('Need Help?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryPartnerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.delivery_dining, color: Colors.white, size: 30),
            ),
            SizedBox(height: 16),
            Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Delivery Partner',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text('⭐ 4.8 (245 deliveries)'),
            SizedBox(height: 16),
            Text('Phone: +1 234 567 8900'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling delivery partner...'),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showRateOrderDialog(Map<String, dynamic> order) {
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Your Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: rating > 0
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          backgroundColor: Color(0xFFFF6B6B),
                        ),
                      );
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeliveryAddress(dynamic delivery) {
    if (delivery is! Map<String, dynamic>) return '';
    final parts = <String>[];
    if (delivery['block']?.toString().isNotEmpty == true) {
      parts.add(delivery['block'].toString());
    }
    if (delivery['room']?.toString().isNotEmpty == true) {
      parts.add('Room ${delivery['room']}');
    }
    if (delivery['floor']?.toString().isNotEmpty == true) {
      parts.add('${delivery['floor']} Floor');
    }
    if (delivery['landmark']?.toString().isNotEmpty == true) {
      parts.add('Near ${delivery['landmark']}');
    }
    return parts.join(', ');
  }

  void _showOrderHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How can we help you with this order?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('Talk to our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling support...'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LiveChatScreen(showBackButton: true),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@campuseats.com'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email app...'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
