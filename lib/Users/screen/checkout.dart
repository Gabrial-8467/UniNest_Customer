import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'order_tracking.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedPaymentMethod = 0;
  bool isPlacingOrder = false;

  // Razorpay instance
  late Razorpay _razorpay;
  String? _currentOrderId;

  // Delivery location controllers
  final _blockController = TextEditingController();
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  final _landmarkController = TextEditingController();

  final List<Map<String, dynamic>> paymentMethods = const [
    {
      'id': 0,
      'name': 'Cash on Delivery',
      'value': 'cod',
      'icon': Icons.money,
      'gateway': null,
    },
    {
      'id': 1,
      'name': 'Card (Online)',
      'value': 'card',
      'icon': Icons.credit_card,
      'gateway': 'razorpay',
    },
    {
      'id': 2,
      'name': 'UPI (Online)',
      'value': 'upi',
      'icon': Icons.qr_code_scanner,
      'gateway': 'razorpay',
    },
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _blockController.dispose();
    _roomController.dispose();
    _floorController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Razorpay Payment Success: ${response.paymentId}');

    if (_currentOrderId == null) return;

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication error. Please login again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      final verifyResult = await ApiService.verifyRazorpayPayment(
        token: token,
        orderId: _currentOrderId!,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (verifyResult['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(
                orderId: _currentOrderId!,
                showBackButton: true,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment verification failed: ${verifyResult['error']}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Razorpay Payment Error: ${response.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('👛 External Wallet: ${response.walletName}');
  }

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
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildOrderSummary(appState),
              const SizedBox(height: 16),
              _buildDeliveryAddress(appState),
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
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'Checkout',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildDeliveryAddress(CampusAppState appState) {
    return _sectionCard(
      title: 'Delivery Location',
      child: Column(
        children: [
          _buildLocationTextField(
            controller: _blockController,
            label: 'Block / Building',
            hint: 'e.g., Block A, Main Building',
            icon: Icons.apartment,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLocationTextField(
                  controller: _roomController,
                  label: 'Room Number',
                  hint: 'e.g., 101',
                  icon: Icons.meeting_room,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationTextField(
                  controller: _floorController,
                  label: 'Floor',
                  hint: 'e.g., Ground, 1st',
                  icon: Icons.stairs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLocationTextField(
            controller: _landmarkController,
            label: 'Nearby Landmark (Optional)',
            hint: 'e.g., Near Library, Cafeteria',
            icon: Icons.place,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CampusAppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              color: AppColors.textPrimary,
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
              item['imageUrl'] is Map
                  ? item['imageUrl']['url'] ?? ''
                  : (item['imageUrl'] ?? '').toString(),
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 42,
                height: 42,
                color: AppColors.background,
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 20,
                  color: AppColors.textLight,
                ),
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
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '\u20B9${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '\u20B9${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
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
            color: selected ? AppColors.primary : AppColors.textLight,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Icon(method['icon'] as IconData, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Text(
              method['name'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
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
        color: AppColors.surface,
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
              color: AppColors.textPrimary,
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
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _placeOrder(appState),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
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

    setState(() => isPlacingOrder = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Placing your order...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final token = await AuthService.getToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        Navigator.pop(context);
        setState(() => isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to place order'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final method = paymentMethods.firstWhere(
        (item) => item['id'] == selectedPaymentMethod,
        orElse: () => paymentMethods.first,
      );

      // Prepare order items
      final items = appState.cartItems.map((item) {
        return {
          'productId': item['id'],
          'quantity': item['quantity'],
          'customizations': [],
        };
      }).toList();

      // Build delivery address object for backend
      final addressParts = <String>[];
      if (_blockController.text.trim().isNotEmpty) {
        addressParts.add(_blockController.text.trim());
      }
      if (_roomController.text.trim().isNotEmpty) {
        addressParts.add('Room ${_roomController.text.trim()}');
      }
      if (_floorController.text.trim().isNotEmpty) {
        addressParts.add('${_floorController.text.trim()} Floor');
      }
      final addressString = addressParts.join(', ');

      final deliveryAddress = {
        'address': addressString,
        'type': 'campus',
        'landmark': _landmarkController.text.trim(),
        'location': {
          'building': _blockController.text.trim(),
          'room': _roomController.text.trim(),
          'floor': _floorController.text.trim(),
        },
      };

      // Create order via API
      final result = await ApiService.createOrder(
        token: token,
        items: items,
        paymentMethod: method['value'] as String,
        deliveryAddress: deliveryAddress,
        fulfillmentType: 'delivery',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final orderData = result['data'];
        final orderId = orderData['_id'] ?? orderData['orderNumber'] ?? '';
        _currentOrderId = orderId;

        // Handle Razorpay payment for online methods
        if (method['gateway'] == 'razorpay') {
          // Create Razorpay order
          final razorpayOrderResult = await ApiService.createRazorpayOrder(
            token: token,
            orderId: orderId,
          );

          if (razorpayOrderResult['success'] == true) {
            final razorpayData = razorpayOrderResult['data'];
            final razorpayOrderId = razorpayData['razorpayOrderId'];
            final amount = razorpayData['amount'];
            final key = razorpayData['key'];

            // Open Razorpay checkout
            final options = {
              'key': key,
              'amount': amount,
              'name': 'Campus Eats',
              'description': 'Order #$orderId',
              'order_id': razorpayOrderId,
              'theme': {'color': '#FF6B6B'},
            };

            _razorpay.open(options);
            // Don't navigate yet - wait for payment callback
            return;
          } else {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to create payment order: ${razorpayOrderResult['error']}',
                ),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
        }

        // For COD - proceed directly
        Navigator.pop(context);

        // Clear cart
        appState.clearCart();

        // Show success dialog
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Order Placed'),
            content: Text('Your order has been placed successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        // Navigate to order tracking
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderTrackingScreen(orderId: orderId, showBackButton: true),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${result['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
  }

  Widget _buildLocationTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }
}
