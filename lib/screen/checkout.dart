import 'package:flutter/material.dart';

import '../state/app_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedPaymentMethod = 0;

  final List<Map<String, dynamic>> paymentMethods = const [
    {'id': 0, 'name': 'Cash', 'icon': Icons.money},
    {'id': 1, 'name': 'UPI', 'icon': Icons.qr_code_scanner},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        if (appState.cartItems.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(
              child: Text(
                'Your cart is empty. Add items before checkout.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(),
          body: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildOrderSummary(appState),
              const SizedBox(height: 16),
              _buildPaymentMethods(),
              const SizedBox(height: 24),
            ],
          ),
          bottomNavigationBar: _buildPlaceOrderButton(appState),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Checkout',
        style: TextStyle(
          color: Color(0xFF2D3436),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
      ),
    );
  }

  Widget _buildOrderSummary(CampusAppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 14),
          ...appState.cartItems.map(_buildOrderItem),
          const Divider(height: 22),
          _summaryRow('Subtotal', appState.subtotal),
          _summaryRow('Delivery Fee', appState.deliveryFee),
          _summaryRow('Platform Fee', appState.platformFee),
          _summaryRow('Tax', appState.tax),
          const Divider(height: 18),
          _summaryRow('Total', appState.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['imageUrl'],
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 42,
                height: 42,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant_menu, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item['name']} x${item['quantity']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          Text(
            '\u20B9${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF2D3436),
            ),
          ),
          Text(
            '\u20B9${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return _sectionCard(
      title: 'Payment Method',
      child: Column(children: paymentMethods.map(_paymentMethodTile).toList()),
    );
  }

  Widget _paymentMethodTile(Map<String, dynamic> method) {
    final selected = selectedPaymentMethod == method['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? const Color(0xFFFF6B6B).withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFFFF6B6B) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Icon(method['icon'] as IconData, color: const Color(0xFF2D3436)),
            const SizedBox(width: 10),
            Text(
              method['name'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(CampusAppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _placeOrder(appState),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Place Order - \u20B9${appState.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(CampusAppState appState) async {
    if (appState.cartItems.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFFF6B6B)),
            SizedBox(width: 14),
            Text('Placing your order...'),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    final method = paymentMethods.firstWhere(
      (item) => item['id'] == selectedPaymentMethod,
      orElse: () => paymentMethods.first,
    );

    final orderId = appState.placeOrder(
      paymentMethod: method['name'] as String,
      deliveryOption: 'delivery',
    );

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Placed'),
        content: Text('Your order $orderId has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }
}
