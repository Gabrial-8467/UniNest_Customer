import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/rating_dialog.dart';
import 'order_tracking.dart';

class OrderHistoryScreen extends StatelessWidget {
  final bool showBackButton;

  const OrderHistoryScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final orders = appState.orderHistory;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Order History',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: showBackButton
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2D3436),
                    ),
                  )
                : null,
            automaticallyImplyLeading: showBackButton,
          ),
          body: appState.isLoadingOrders && orders.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : orders.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final placedAt = order['placedAt'] as DateTime;
                    return _buildOrderCard(context, order, placedAt);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No orders placed yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your placed orders will show up here, and you can track them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => AppStateScope.of(context).refreshOrders(),
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

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    DateTime placedAt,
  ) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final preview = items.take(2).map((item) => item['name']).join(', ');
    final status = order['status'] as String;

    Color statusColor;
    switch (status) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Out for Delivery':
        statusColor = AppColors.primary;
        break;
      case 'Preparing':
      case 'Ready for Pickup':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  order['orderId'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(placedAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2D3436)),
          ),
          if (items.length > 2)
            Text(
              '+${items.length - 2} more items',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order['itemCount']} items',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              Text(
                '\u20B9${(order['total'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((status.toLowerCase() == 'delivered' ||
                  status.toLowerCase() == 'completed' ||
                  status.toLowerCase() == 'picked up') &&
              order['isReviewed'] != true) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Use order ID directly from the order data we already have
                  // backendOrderId is stored when orders are normalized in app_state
                  final orderIdToUse = order['backendOrderId'] as String?;
                  final displayId = order['orderId'] as String?;

                  debugPrint('🔍 Using orderIdToUse: $orderIdToUse');
                  debugPrint('🔍 Display orderId: $displayId');

                  showRatingDialog(
                    context,
                    orderIdToUse ?? displayId ?? '',
                    displayOrderId: displayId,
                    onSubmitted: () {
                      // Refresh orders after rating to update UI
                      AppStateScope.of(context).refreshOrders();
                    },
                  );
                },
                icon: const Icon(Icons.star, size: 16),
                label: const Text('Rate Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ] else if ((status.toLowerCase() == 'delivered' ||
                  status.toLowerCase() == 'completed' ||
                  status.toLowerCase() == 'picked up') &&
              order['isReviewed'] == true) ...[
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Order Rated',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (status.toLowerCase() == 'cancelled') ...[
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Order Cancelled',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Update order status before navigating
                  AppStateScope.of(context).updateOrderStatus(order['orderId']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderTrackingScreen(
                        orderId: order['orderId'],
                        showBackButton: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }
}
