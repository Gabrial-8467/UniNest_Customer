import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/razorpay_checkout.dart';
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
  String fulfillmentType = 'delivery'; // 'delivery' or 'takeaway'
  String? _couponCode;
  bool _isLoadingPricing = false;
  String? _vendorId;

  // Razorpay instance
  late Razorpay _razorpay;
  String? _currentOrderId;
  List<Map<String, dynamic>> _pendingCartSnapshot = const [];
  Map<String, dynamic>? _pendingDeliveryAddress;
  Map<String, dynamic>? _pendingOrderData;

  // Delivery location controllers
  final _blockController = TextEditingController();
  final _roomController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _couponController = TextEditingController();

  // Field validation errors
  String? _blockError;

  final List<Map<String, dynamic>> paymentMethods = const [
    {
      'id': 0,
      'name': 'Cash on Delivery',
      'value': 'COD',
      'icon': Icons.money,
      'gateway': null,
    },
    {
      'id': 1,
      'name': 'Pay via Razorpay',
      'value': 'razorpay',
      'icon': Icons.credit_card,
      'gateway': 'razorpay',
    },
  ];

  final List<Map<String, dynamic>> fulfillmentOptions = const [
    {'id': 'delivery', 'name': 'Delivery', 'icon': Icons.delivery_dining},
    {'id': 'takeaway', 'name': 'Self Pickup', 'icon': Icons.store},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    // Fetch pricing from backend after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBackendPricing();
    });
  }

  Future<void> _fetchBackendPricing() async {
    final appState = AppStateScope.of(context);
    if (appState.cartItems.isEmpty) return;

    // Get vendor ID from first cart item
    final firstItem = appState.cartItems.first;
    final product = appState.getProductById(firstItem['id'] as String);
    if (product == null) return;

    final canteen = appState.getCanteenById(product['canteenId'] as String);
    if (canteen == null) return;

    _vendorId = canteen['id'] as String? ?? canteen['_id'] as String?;
    if (_vendorId == null) return;

    setState(() => _isLoadingPricing = true);

    await appState.fetchPricingFromBackend(
      vendorId: _vendorId!,
      offerCode: _couponCode,
      fulfillmentType: fulfillmentType,
    );

    if (mounted) {
      setState(() => _isLoadingPricing = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _blockController.dispose();
    _roomController.dispose();
    _landmarkController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    setState(() {
      _blockError = null;
    });
  }

  bool _validateAddressFields() {
    _clearFieldErrors();
    bool isValid = true;

    if (fulfillmentType == 'delivery') {
      final block = _blockController.text.trim();

      if (block.isEmpty) {
        setState(() => _blockError = 'Block / Building is required');
        isValid = false;
      }
    }

    return isValid;
  }

  int _resolveRazorpayAmount({
    required dynamic rawAmount,
    required double fallbackTotalInRupees,
  }) {
    final fallbackInPaise = (fallbackTotalInRupees * 100).round();

    if (rawAmount == null) {
      return fallbackInPaise;
    }

    if (rawAmount is num) {
      final normalizedAmount = rawAmount.toDouble();

      // Razorpay expects the amount in the smallest currency unit (paise).
      // Some backends return rupees, others already return paise.
      if (normalizedAmount <= fallbackTotalInRupees + 1) {
        return (normalizedAmount * 100).round();
      }

      return normalizedAmount.round();
    }

    final parsedAmount = double.tryParse(rawAmount.toString());
    if (parsedAmount == null) {
      return fallbackInPaise;
    }

    if (parsedAmount <= fallbackTotalInRupees + 1) {
      return (parsedAmount * 100).round();
    }

    return parsedAmount.round();
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
        if (!mounted) return;
        final appState = AppStateScope.of(context);
        final verifiedOrderData = verifyResult['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
                verifyResult['data'] as Map<String, dynamic>,
              )
            : (_pendingOrderData ?? <String, dynamic>{});
        appState.registerBackendOrder(
          orderData: verifiedOrderData,
          cartSnapshot: _pendingCartSnapshot,
          deliveryAddress: _pendingDeliveryAddress,
        );

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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              // _buildCouponField(appState),
              // const SizedBox(height: 16),
              _buildFulfillmentType(),
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
            errorText: _blockError,
          ),
          const SizedBox(height: 12),
          _buildLocationTextField(
            controller: _roomController,
            label: 'Room Number',
            hint: 'e.g., 101',
            icon: Icons.meeting_room,
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
    // Use backend pricing only, no fallback
    final pricing = appState.backendPricing;
    final subtotal = (pricing?['itemSubtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (pricing?['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final platformFee = (pricing?['platformFee'] as num?)?.toDouble() ?? 0.0;
    final tax = (pricing?['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final discount = (pricing?['platformDiscount'] as num?)?.toDouble() ?? 0.0;
    final lateNightFee = (pricing?['lateNightFee'] as num?)?.toDouble() ?? 0.0;
    final total = (pricing?['finalPayableAmount'] as num?)?.toDouble() ?? 0.0;
    final hasDiscount = discount > 0;
    final hasLateNightFee = lateNightFee > 0;
    debugPrint(
      '🌙 Checkout - Late Night Fee: $lateNightFee, Has Late Night: $hasLateNightFee',
    );

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_isLoadingPricing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...appState.cartItems.map(_buildOrderItem),
          const Divider(height: 22),
          _summaryRow('Subtotal', subtotal),
          _summaryRow('Delivery Fee', deliveryFee),
          _summaryRow('Platform Fee', platformFee),
          _summaryRow('Tax (5%)', tax),
          if (hasLateNightFee) ...[
            _summaryRow(
              'Late Night Fee (11PM-5AM)',
              lateNightFee,
              isLateNight: true,
            ),
          ],
          if (hasDiscount) ...[
            _summaryRow(
              'Discount ${appState.appliedCoupon?['code'] ?? ''}',
              -discount,
              isDiscount: true,
            ),
          ],
          const Divider(height: 18),
          _summaryRow('Total', total, isTotal: true),
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
              color: AppColors.textPrimary,
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
                              ? AppColors.primary
                              : AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildCouponField(CampusAppState appState) {
  //   final hasAppliedCoupon = appState.hasActiveCoupon || _couponCode != null;
  //
  //   return _sectionCard(
  //     title: 'Coupon Code',
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: TextField(
  //                 controller: _couponController,
  //                 enabled: !hasAppliedCoupon,
  //                 decoration: InputDecoration(
  //                   hintText: hasAppliedCoupon
  //                       ? 'Coupon applied'
  //                       : 'Enter coupon code (e.g., SAVE10)',
  //                   prefixIcon: const Icon(
  //                     Icons.local_offer,
  //                     color: AppColors.textSecondary,
  //                   ),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                     borderSide: BorderSide(color: AppColors.textLight),
  //                   ),
  //                   enabledBorder: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                     borderSide: BorderSide(color: AppColors.textLight),
  //                   ),
  //                   focusedBorder: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                     borderSide: BorderSide(color: AppColors.primary),
  //                   ),
  //                   filled: true,
  //                   fillColor: AppColors.background,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             if (hasAppliedCoupon)
  //               ElevatedButton.icon(
  //                 onPressed: () {
  //                   setState(() {
  //                     _couponCode = null;
  //                     _couponController.clear();
  //                   });
  //                   appState.clearBackendPricing();
  //                   _fetchBackendPricing();
  //                 },
  //                 icon: const Icon(Icons.close, size: 18),
  //                 label: const Text('Remove'),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.red,
  //                   foregroundColor: Colors.white,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                 ),
  //               )
  //             else
  //               ElevatedButton(
  //                 onPressed: _isLoadingPricing
  //                     ? null
  //                     : () async {
  //                         final code = _couponController.text.trim();
  //                         if (code.isEmpty) return;
  //                         setState(() => _couponCode = code);
  //                         await _fetchBackendPricing();
  //                       },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppColors.primary,
  //                   foregroundColor: Colors.white,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                 ),
  //                 child: _isLoadingPricing
  //                     ? const SizedBox(
  //                         width: 20,
  //                         height: 20,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: Colors.white,
  //                         ),
  //                       )
  //                     : const Text('Apply'),
  //               ),
  //           ],
  //         ),
  //         if (hasAppliedCoupon) ...[
  //           const SizedBox(height: 8),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //             decoration: BoxDecoration(
  //               color: Colors.green.withValues(alpha: 0.1),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Icon(Icons.check_circle, color: Colors.green, size: 16),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   'Coupon ${appState.appliedCoupon?['code'] ?? _couponCode ?? ''} applied!',
  //                   style: const TextStyle(
  //                     color: Colors.green,
  //                     fontWeight: FontWeight.w600,
  //                     fontSize: 13,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFulfillmentType() {
    return _sectionCard(
      title: 'Order Type',
      child: Column(
        children: fulfillmentOptions.map((option) {
          final selected = fulfillmentType == option['id'];
          return GestureDetector(
            onTap: () async {
              setState(() {
                fulfillmentType = option['id'] as String;
                // Clear errors when switching order type
                if (fulfillmentType != 'delivery') {
                  _clearFieldErrors();
                }
              });
              // Refresh pricing when fulfillment type changes
              await _fetchBackendPricing();
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
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    option['icon'] as IconData,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    option['name'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
          child: _isLoadingPricing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Calculating...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Place Order - \u20B9${((appState.backendPricing?['finalPayableAmount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(CampusAppState appState) async {
    if (appState.cartItems.isEmpty) {
      return;
    }

    // Validate address fields for delivery
    if (!_validateAddressFields()) {
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
      final paymentMethodValue = (method['value'] ?? '').toString().trim();
      final cartSnapshot = appState.cartItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // Prepare order items
      final items = appState.cartItems.map((item) {
        return {
          'productId': (item['id'] ?? '').toString(),
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
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
      final addressString = addressParts.join(', ');

      final deliveryAddress = <String, dynamic>{
        'address': addressString.toString(),
        'type': 'campus',
        'building': _blockController.text.trim(),
        'room': _roomController.text.trim(),
      };
      if (_landmarkController.text.trim().isNotEmpty) {
        deliveryAddress['landmark'] = _landmarkController.text.trim();
      }

      // Create order via API
      debugPrint(
        '🧾 Create order payload: paymentMethod=$paymentMethodValue, '
        'deliveryAddressType=${deliveryAddress['type']}, items=${items.length}',
      );
      final result = await ApiService.createOrder(
        token: token,
        items: items,
        paymentMethod: paymentMethodValue,
        deliveryAddress: deliveryAddress,
        fulfillmentType: fulfillmentType,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final orderData = Map<String, dynamic>.from(
          (result['data'] as Map?) ?? const <String, dynamic>{},
        );
        final orderId = (orderData['orderNumber'] ?? orderData['_id'] ?? '')
            .toString();
        _currentOrderId = orderId;
        _pendingCartSnapshot = cartSnapshot;
        _pendingDeliveryAddress = Map<String, dynamic>.from(deliveryAddress);
        _pendingOrderData = orderData;

        // Handle Razorpay payment for online methods
        if (method['gateway'] == 'razorpay') {
          // Create Razorpay order
          final razorpayOrderResult = await ApiService.createRazorpayOrder(
            token: token,
            orderId: orderId,
          );

          if (razorpayOrderResult['success'] == true) {
            final razorpayData = razorpayOrderResult['data'];
            debugPrint('📦 Razorpay API Response: $razorpayData');
            final paymentData = razorpayData['payment'];
            final razorpayOrderId = paymentData?['orderId'];
            final razorpayAmount = _resolveRazorpayAmount(
              rawAmount: paymentData?['amount'],
              fallbackTotalInRupees: appState.total,
            );
            // Use key from API response or fallback to config
            final key = paymentData?['key'] ?? AppConfig.razorpayKey;

            // Validate required fields
            if (key == null || key.toString().isEmpty) {
              debugPrint(
                '❌ Razorpay key is missing from API response and config',
              );
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => isPlacingOrder = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment configuration error: Key not found'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            // Open Razorpay checkout
            final options = {
              'key': key,
              'amount': razorpayAmount,
              'name': 'UniNest',
              'description': 'Order #$orderId',
              'order_id': razorpayOrderId,
              'theme': {'color': '#FF6B6B'},
            };
            debugPrint('🚀 Razorpay Options: $options');

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
        appState.registerBackendOrder(
          orderData: orderData,
          cartSnapshot: cartSnapshot,
          deliveryAddress: _pendingDeliveryAddress,
        );

        // Show success dialog
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Order Placed'),
            content: const Text(
              'Your order has been placed successfully. You can track it from order history.',
            ),
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
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: hasError ? AppColors.error : AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.textLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.textLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
