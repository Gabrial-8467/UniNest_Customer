import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'checkout.dart';

class CartScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBrowseMenu;

  const CartScreen({super.key, this.showBackButton = true, this.onBrowseMenu});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final cartItems = appState.cartItems;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, appState),
          body: cartItems.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(appState),
          bottomNavigationBar: cartItems.isEmpty
              ? null
              : _buildCheckoutBar(context, appState),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CampusAppState appState,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'My Cart',
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
            appState.clearCart();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
          },
          icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
          tooltip: 'Clear Cart',
        ),
      ],
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from home or canteen menu to checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  widget.onBrowseMenu ??
                  () {
                    if (widget.showBackButton) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pushNamed(context, '/home');
                  },
              child: const Text('Browse Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CampusAppState appState) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appState.cartItems.length,
            itemBuilder: (context, index) {
              final item = appState.cartItems[index];
              return _buildCartItem(appState, item);
            },
          ),
        ),
        _buildOrderSummary(appState),
      ],
    );
  }

  Widget _buildCartItem(CampusAppState appState, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item['imageUrl'] is Map
                  ? item['imageUrl']['url'] ?? ''
                  : (item['imageUrl'] ?? '').toString(),
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 78,
                height: 78,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant_menu),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['canteenName'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u20B9${(item['price'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        final current = item['quantity'] as int;
                        appState.updateCartQuantity(item['id'], current - 1);
                      },
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 30,
                        minWidth: 30,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(
                          '${item['quantity']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final current = item['quantity'] as int;
                        appState.updateCartQuantity(item['id'], current + 1);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 30,
                        minWidth: 30,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => appState.removeFromCart(item['id']),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CampusAppState appState) {
    // Show only items subtotal, no extra fees
    final subtotal = appState.subtotal;

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
      child: Column(children: [_summaryRow('Total', subtotal, isTotal: true)]),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isLateNight = false,
  }) {
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
            '${amount < 0 ? '-' : ''}\u20B9${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? Colors.green
                  : (isLateNight
                        ? Colors.orange
                        : (isTotal
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF2D3436))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CampusAppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '\u20B9${appState.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
