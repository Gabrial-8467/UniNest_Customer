import 'dart:collection';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/utils.dart';

class CampusAppState extends ChangeNotifier {
  CampusAppState() {
    _restoreCartFromStorage();
    _restoreFavoritesFromStorage();
    _restoreOrdersFromStorage();
    _startStatusUpdateTimer();
    _initializeBackendData();
    startNotificationPolling();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  // Start periodic notification count fetch
  void startNotificationPolling() {
    _notificationTimer?.cancel();
    _fetchUnreadNotificationCount();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchUnreadNotificationCount(),
    );
  }

  // Fetch unread notification count
  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;

      final result = await ApiService.getNotifications(
        token: token,
        page: 1,
        limit: 1,
        isRead: false,
      );

      if (result['success'] == true) {
        final data = result['data'];
        // API returns unreadCount directly, or fallback to pagination.total
        final total = data['unreadCount'] ?? data['pagination']?['total'] ?? 0;

        if (_unreadNotificationCount != total) {
          _unreadNotificationCount = total;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  // Update notification count (called after viewing notifications)
  void updateNotificationCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }

  final List<Map<String, dynamic>> _canteens = [];
  final List<Map<String, dynamic>> _products = [];
  final List<String> _categories = [];
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _orderHistory = [];
  Timer? _statusUpdateTimer;
  Timer? _notificationTimer;

  // Backend pricing cache
  Map<String, dynamic>? _backendPricing;
  String? _currentVendorId;
  String? _currentOfferCode;
  String _currentFulfillmentType = 'delivery';

  int _unreadNotificationCount = 0;
  bool _hasConnectionError = false;
  String _errorMessage = '';
  bool _isLoadingProducts = false;
  bool _isLoadingOrders = false;
  bool _isLoadingCategories = false;
  bool _isLoadingCanteens = false;

  bool get hasConnectionError => _hasConnectionError;
  String get errorMessage => _errorMessage;
  int get unreadNotificationCount => _unreadNotificationCount;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingCanteens => _isLoadingCanteens;

  // Backend pricing getters (fallback to local calculation if no backend pricing)
  Map<String, dynamic>? get backendPricing => _backendPricing;
  String? get currentVendorId => _currentVendorId;
  String? get currentOfferCode => _currentOfferCode;
  String get currentFulfillmentType => _currentFulfillmentType;

  double get backendSubtotal =>
      (_backendPricing?['itemSubtotal'] as num?)?.toDouble() ?? subtotal;
  double get backendDeliveryFee =>
      (_backendPricing?['deliveryFee'] as num?)?.toDouble() ?? deliveryFee;
  double get backendPlatformFee =>
      (_backendPricing?['platformFee'] as num?)?.toDouble() ?? platformFee;
  double get backendTax =>
      (_backendPricing?['taxAmount'] as num?)?.toDouble() ?? tax;
  double get backendDiscount =>
      (_backendPricing?['platformDiscount'] as num?)?.toDouble() ?? 0.0;
  double get backendLateNightFee =>
      (_backendPricing?['lateNightFee'] as num?)?.toDouble() ?? 0.0;
  bool get hasLateNightFee => backendLateNightFee > 0;
  double get backendTotal =>
      (_backendPricing?['finalPayableAmount'] as num?)?.toDouble() ?? total;

  bool get hasActiveCoupon => _backendPricing?['appliedOffer'] != null;
  Map<String, dynamic>? get appliedCoupon =>
      _backendPricing?['appliedOffer'] as Map<String, dynamic>?;

  // Helper to extract URL string from Map or String
  String? _extractImageUrl(dynamic imageField) {
    if (imageField == null) return null;
    if (imageField is Map<String, dynamic>) {
      return imageField['url']?.toString();
    }
    return imageField.toString();
  }

  Future<void> _initializeBackendData() async {
    await refreshAllData();
    await _loadBackendOrders();
  }

  // Fetch products from backend API (all pages)
  Future<void> _fetchProductsFromBackend() async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      debugPrint('🔍 AppState: Fetching all products from backend...');
      final token = await AuthService.getToken();
      _products.clear();

      int page = 1;
      const int limit = 100;
      bool hasMorePages = true;

      while (hasMorePages) {
        final response = await ApiService.getProducts(
          token: token,
          page: page,
          limit: limit,
        );

        if (response['success'] == true) {
          final data = response['data'];
          final List<dynamic> productsData = data is Map<String, dynamic>
              ? (data['products'] as List<dynamic>? ?? const [])
              : (data as List<dynamic>? ?? const []);

          if (productsData.isEmpty) {
            hasMorePages = false;
            break;
          }

          for (final product in productsData) {
            if (product is Map<String, dynamic>) {
              final vendorData = product['vendor'];
              // Convert backend product format to app format
              final appProduct = {
                'id':
                    product['_id']?.toString() ??
                    product['id']?.toString() ??
                    '',
                'name': product['name'] ?? '',
                'description': product['description'] ?? '',
                'price': (product['price'] as num?)?.toDouble() ?? 0.0,
                'category': product['category'] ?? '',
                'imageUrl':
                    _extractImageUrl(product['image']) ??
                    _extractImageUrl(product['imageUrl']) ??
                    ((product['images'] is List &&
                            (product['images'] as List).isNotEmpty)
                        ? _extractImageUrl(product['images'][0])
                        : ''),
                'stock':
                    (product['inStock'] as num?)?.toInt() ??
                    (product['stock'] as num?)?.toInt() ??
                    0,
                'madeToOrder':
                    product['madeToOrder'] ?? true, // Default to made-to-order
                'availability': () {
                  final inStock =
                      (product['inStock'] as num?)?.toInt() ??
                      (product['stock'] as num?)?.toInt() ??
                      0;
                  // Made-to-order items are always available, pre-packaged need stock > 0
                  final isMadeToOrder = product['madeToOrder'] ?? true;
                  if (isMadeToOrder) {
                    return 'in_stock'; // Always available for made-to-order
                  } else {
                    return inStock >= 0 ? 'in_stock' : 'out_of_stock';
                  }
                }(),
                'canteenId': vendorData is Map<String, dynamic>
                    ? (vendorData['_id']?.toString() ?? '')
                    : '',
                'canteenName': vendorData is Map<String, dynamic>
                    ? (vendorData['businessName'] ?? 'Main Canteen')
                    : 'Main Canteen',
                'rating': (product['rating'] as num?)?.toDouble() ?? 0.0,
                'reviewCount': (product['reviewCount'] as num?)?.toInt() ?? 0,
                'isFavorite': false,
                'vendor': vendorData,
              };
              _products.add(appProduct);
            }
          }

          // Check if we've fetched all products
          final pagination = data is Map<String, dynamic>
              ? data['pagination']
              : null;
          final totalPages = pagination is Map<String, dynamic>
              ? (pagination['pages'] as num?)?.toInt() ?? 1
              : 1;

          if (page >= totalPages || productsData.length < limit) {
            hasMorePages = false;
          } else {
            page++;
          }
        } else {
          debugPrint(
            '❌ AppState: Failed to fetch products page $page: ${response['error']}',
          );
          hasMorePages = false;
        }
      }

      debugPrint(
        '✅ AppState: Loaded ${_products.length} total products from backend',
      );
      _hasConnectionError = false;
      _errorMessage = '';
    } catch (e) {
      debugPrint('💥 AppState: Error fetching products: $e');
      _hasConnectionError = true;
      _errorMessage = 'Network error. Please check your connection.';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // Public method to refresh products
  Future<void> refreshProducts() async {
    await _fetchProductsFromBackend();
  }

  // Public method to refresh canteens
  Future<void> refreshCanteens() async {
    await _fetchCanteensFromBackend();
  }

  // Public method to refresh all data
  Future<void> refreshAllData() async {
    // Fetch products first (canteens and categories depend on products)
    await _fetchProductsFromBackend();
    // Then extract canteens and categories from products
    await Future.wait([
      _fetchCanteensFromBackend(),
      _fetchCategoriesFromBackend(),
    ]);
  }

  // Public method to refresh orders from backend
  Future<void> refreshOrders() async {
    _isLoadingOrders = true;
    notifyListeners();
    await _loadBackendOrders();
    _isLoadingOrders = false;
    notifyListeners();
  }

  // Test backend connection
  Future<bool> testBackendConnection() async {
    return await ApiService.testConnection();
  }

  // Fetch categories from backend API
  Future<void> _fetchCategoriesFromBackend() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      debugPrint('🔍 AppState: Fetching categories from backend...');

      // Extract categories from products since there's no separate categories endpoint
      if (_products.isNotEmpty) {
        final Set<String> uniqueCategories = {};
        for (final product in _products) {
          final category = (product['category'] ?? '').toString();
          if (category.isNotEmpty) {
            uniqueCategories.add(category);
          }
        }

        _categories.clear();
        _categories.addAll(uniqueCategories.toList()..sort());
        debugPrint(
          '✅ AppState: Loaded ${_categories.length} categories from products',
        );
      } else {
        final token = await AuthService.getToken();
        final response = await ApiService.getProducts(token: token);
        if (response['success'] == true) {
          final data = response['data'];
          final List<dynamic> productsData = data is Map<String, dynamic>
              ? (data['products'] as List<dynamic>? ?? const [])
              : (data as List<dynamic>? ?? const []);
          final Set<String> uniqueCategories = {};

          for (final product in productsData) {
            if (product is Map<String, dynamic>) {
              final category = (product['category'] ?? '').toString();
              if (category.isNotEmpty) {
                uniqueCategories.add(category);
              }
            }
          }

          _categories.clear();
          _categories.addAll(uniqueCategories.toList()..sort());
          debugPrint(
            '✅ AppState: Loaded ${_categories.length} categories from backend',
          );
        }
      }
    } catch (e) {
      debugPrint('💥 AppState: Error fetching categories: $e');
      // Set default categories if backend fails
      _categories.clear();
      _categories.addAll([
        'All',
        'Burgers',
        'Pizza',
        'Drinks',
        'Desserts',
        'Snacks',
      ]);
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // Fetch canteens from backend API
  Future<void> _fetchCanteensFromBackend() async {
    _isLoadingCanteens = true;
    notifyListeners();

    _hasConnectionError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('🔍 AppState: Fetching canteens from backend...');

      final token = await AuthService.getToken();
      final response = await ApiService.getCanteens(token: token);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> vendorsData = data is Map<String, dynamic>
            ? (data['vendors'] as List<dynamic>? ?? const [])
            : (data as List<dynamic>? ?? const []);
        _canteens.clear();

        for (final vendor in vendorsData) {
          if (vendor is Map<String, dynamic>) {
            final location = vendor['location'];
            final rating = vendor['rating'];
            final user = vendor['user'];

            // Convert backend canteen format to app format
            final appCanteen = {
              'id': vendor['_id']?.toString() ?? vendor['id']?.toString() ?? '',
              'name': vendor['businessName'] ?? '',
              'location': location is Map<String, dynamic>
                  ? (location['address'] ??
                        location['city'] ??
                        location['landmark'] ??
                        '')
                  : (vendor['location'] ?? ''),
              'rating': rating is Map<String, dynamic>
                  ? (rating['average'] as num?)?.toDouble() ?? 0.0
                  : (vendor['rating'] as num?)?.toDouble() ?? 0.0,
              'reviewCount': rating is Map<String, dynamic>
                  ? (rating['count'] as num?)?.toInt() ?? 0
                  : (vendor['reviewCount'] as num?)?.toInt() ?? 0,
              'isOpen': vendor['status'] == 'active',
              'imageUrl': user is Map<String, dynamic>
                  ? (user['avatar'] ?? '')
                  : (vendor['image'] ?? vendor['imageUrl'] ?? ''),
              'description': vendor['description'] ?? '',
              'openingTime': '08:00',
              'closingTime': '20:00',
            };
            _canteens.add(appCanteen);
          }
        }

        debugPrint(
          '✅ AppState: Loaded ${_canteens.length} canteens from backend',
        );
        _hasConnectionError = false;
        _errorMessage = '';
      } else {
        debugPrint(
          '❌ AppState: Failed to fetch canteens: ${response['error']}',
        );
        _hasConnectionError = true;
        _errorMessage = response['error'] ?? 'Failed to load canteens';
      }
    } catch (e) {
      debugPrint('💥 AppState: Error fetching canteens: $e');
      _hasConnectionError = true;
      _errorMessage = 'Failed to load canteens from backend';
    } finally {
      _isLoadingCanteens = false;
      notifyListeners();
    }
  }

  // Load user orders from backend and sync with local state
  Future<void> _loadBackendOrders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return; // not logged in
    final result = await ApiService.getUserOrders(token: token);
    if (result['success'] == true) {
      final data = result['data'];
      final List<dynamic> orders = data is Map ? (data['orders'] ?? []) : [];
      _orderHistory
        ..clear()
        ..addAll(
          orders
              .whereType<Map<String, dynamic>>()
              .map((order) => _normalizeBackendOrder(orderData: order))
              .toList(),
        );
      await _persistOrdersToStorage();
      notifyListeners();
    } else {
      debugPrint('❌ Failed to fetch orders: ${result['error']}');
    }
  }

  UnmodifiableListView<Map<String, dynamic>> get canteens =>
      UnmodifiableListView(_canteens);

  UnmodifiableListView<Map<String, dynamic>> get products =>
      UnmodifiableListView(_products);

  UnmodifiableListView<String> get categories =>
      UnmodifiableListView(_categories);

  UnmodifiableListView<Map<String, dynamic>> get cartItems =>
      UnmodifiableListView(_cartItems);

  UnmodifiableListView<Map<String, dynamic>> get orderHistory =>
      UnmodifiableListView(_orderHistory);

  int get cartItemCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

  double get subtotal => _cartItems.fold<double>(
    0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );

  double get deliveryFee => _cartItems.isEmpty ? 0.0 : 2.99;

  double get platformFee => _cartItems.isEmpty ? 0.0 : 1.99;

  double get tax => subtotal * 0.08;

  double get total => subtotal + deliveryFee + platformFee + tax;

  List<Map<String, dynamic>> get favoriteProducts => _products
      .where((product) => product['isFavorite'] == true)
      .map((product) => Map<String, dynamic>.from(product))
      .toList();

  int get favoriteItemCount => favoriteProducts.length;

  List<Map<String, dynamic>> productsByCanteen(String canteenId) => _products
      .where((product) => product['canteenId'] == canteenId)
      .map((product) => Map<String, dynamic>.from(product))
      .toList();

  Map<String, dynamic>? getCanteenById(String canteenId) {
    for (final canteen in _canteens) {
      if (canteen['id'] == canteenId) {
        return Map<String, dynamic>.from(canteen);
      }
    }
    return null;
  }

  Map<String, dynamic>? getProductById(String productId) {
    for (final product in _products) {
      if (product['id'] == productId) {
        return Map<String, dynamic>.from(product);
      }
    }
    return null;
  }

  void setFavorite(String productId, bool isFavorite) {
    final product = _getProductRef(productId);
    if (product == null) {
      return;
    }
    product['isFavorite'] = isFavorite;
    notifyListeners();
    _persistFavoritesToStorage();
  }

  void toggleFavorite(String productId) {
    final product = _getProductRef(productId);
    if (product == null) {
      return;
    }
    product['isFavorite'] = !(product['isFavorite'] == true);
    notifyListeners();
    _persistFavoritesToStorage();
  }

  void addToCart(String productId, {int quantity = 1}) {
    if (quantity <= 0) {
      return;
    }

    final product = _getProductRef(productId);
    if (product == null) {
      return;
    }

    final existingItem = _getCartItemRef(productId);
    if (existingItem != null) {
      existingItem['quantity'] = (existingItem['quantity'] as int) + quantity;
      notifyListeners();
      _persistCartToStorage();
      return;
    }

    _cartItems.add({
      'id': product['id'],
      'name': product['name'],
      'price': product['price'],
      'imageUrl': product['imageUrl'],
      'canteenName': product['canteenName'],
      'quantity': quantity,
      'rating': product['rating'],
      'reviewCount': product['reviewCount'],
    });

    notifyListeners();
    _persistCartToStorage();
  }

  void updateCartQuantity(String productId, int quantity) {
    final item = _getCartItemRef(productId);
    if (item == null) {
      return;
    }

    if (quantity <= 0) {
      _cartItems.remove(item);
    } else {
      item['quantity'] = quantity;
    }

    notifyListeners();
    _persistCartToStorage();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['id'] == productId);
    notifyListeners();
    _persistCartToStorage();
  }

  void clearCart() {
    if (_cartItems.isEmpty) {
      return;
    }
    _cartItems.clear();
    _backendPricing = null;
    notifyListeners();
    _persistCartToStorage();
  }

  // Fetch pricing from backend for accurate pricing display
  Future<Map<String, dynamic>> fetchPricingFromBackend({
    required String vendorId,
    String? offerCode,
    String? fulfillmentType,
  }) async {
    if (_cartItems.isEmpty) {
      return {'success': false, 'error': 'Cart is empty'};
    }

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      _currentVendorId = vendorId;
      _currentOfferCode = offerCode;
      if (fulfillmentType != null) {
        _currentFulfillmentType = fulfillmentType;
      }

      final result = await ApiService.calculatePricingPreview(
        token: token,
        items: _cartItems.toList(),
        vendorId: vendorId,
        offerCode: offerCode,
        fulfillmentType: fulfillmentType ?? _currentFulfillmentType,
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map<String, dynamic>) {
          _backendPricing = data['pricing'] as Map<String, dynamic>?;
          debugPrint('💰 Backend pricing: $_backendPricing');
          debugPrint('🌙 Late night fee: ${_backendPricing?['lateNightFee']}');
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching pricing: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  void clearBackendPricing() {
    _backendPricing = null;
    notifyListeners();
  }

  void registerBackendOrder({
    required Map<String, dynamic> orderData,
    List<Map<String, dynamic>>? cartSnapshot,
    Map<String, dynamic>? deliveryAddress,
    bool clearCart = true,
  }) {
    final normalizedOrder = _normalizeBackendOrder(
      orderData: orderData,
      cartSnapshot: cartSnapshot,
      deliveryAddress: deliveryAddress,
    );
    final orderId = normalizedOrder['orderId'] as String;
    final existingIndex = _orderHistory.indexWhere(
      (order) => order['orderId'] == orderId,
    );

    if (existingIndex >= 0) {
      _orderHistory[existingIndex] = normalizedOrder;
    } else {
      _orderHistory.insert(0, normalizedOrder);
    }

    if (clearCart) {
      _cartItems.clear();
    }

    notifyListeners();
    _persistCartToStorage();
    _persistOrdersToStorage();
  }

  String placeOrder({
    required String paymentMethod,
    required String deliveryOption,
    String notes = '',
  }) {
    if (_cartItems.isEmpty) {
      return '';
    }

    final now = DateTime.now();
    final orderId = 'ORD${now.millisecondsSinceEpoch.toString().substring(6)}';

    _orderHistory.insert(0, {
      'orderId': orderId,
      'placedAt': now,
      'status': 'Placed',
      'paymentMethod': paymentMethod,
      'deliveryOption': deliveryOption,
      'notes': notes,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'tax': tax,
      'total': total,
      'itemCount': cartItemCount,
      'items': _cartItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      'estimatedDelivery': _calculateEstimatedDelivery(deliveryOption),
      'trackingSteps': _initializeTrackingSteps(),
    });

    _cartItems.clear();
    notifyListeners();
    _persistCartToStorage();
    _persistOrdersToStorage();
    return orderId;
  }

  Map<String, dynamic> _normalizeBackendOrder({
    required Map<String, dynamic> orderData,
    List<Map<String, dynamic>>? cartSnapshot,
    Map<String, dynamic>? deliveryAddress,
  }) {
    final placedAt = _parseDateTime(orderData['createdAt']) ?? DateTime.now();
    final estimatedDelivery =
        _parseDateTime(orderData['estimatedDeliveryTime']) ??
        _parseDateTime(orderData['updatedAt']) ??
        _calculateEstimatedDelivery('standard');
    final status = _normalizeOrderStatus(orderData['status']);
    final normalizedItems = _normalizeOrderItems(
      orderData['items'],
      cartSnapshot: cartSnapshot,
    );
    final resolvedDelivery =
        _normalizeDeliveryAddress(orderData['deliveryAddress']) ??
        _normalizeDeliveryAddress(deliveryAddress);
    final trackingSteps = _buildTrackingStepsForStatus(
      placedAt: placedAt,
      status: status,
    );
    final itemCount = normalizedItems.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
    final pricing = orderData['pricing'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(
            orderData['pricing'] as Map<String, dynamic>,
          )
        : <String, dynamic>{};
    final subtotal =
        _readAmount(pricing['subtotal']) ??
        _readAmount(orderData['totalAmount']) ??
        normalizedItems.fold<double>(
          0,
          (sum, item) =>
              sum +
              ((_readAmount(item['price']) ?? 0) *
                  ((item['quantity'] as num?)?.toInt() ?? 0)),
        );
    final deliveryFee =
        _readAmount(pricing['deliveryFee']) ??
        _readAmount(orderData['deliveryFee']) ??
        0.0;
    final platformFee =
        _readAmount(pricing['platformFee']) ??
        _readAmount(orderData['platformFee']) ??
        0.0;
    final tax =
        _readAmount(pricing['tax']) ??
        _readAmount(orderData['taxAmount']) ??
        0.0;
    final lateNightFee =
        _readAmount(pricing['lateNightFee']) ??
        _readAmount(orderData['lateNightFee']) ??
        0.0;
    final discount =
        _readAmount(pricing['platformDiscount']) ??
        _readAmount(pricing['discount']) ??
        _readAmount(orderData['platformDiscount']) ??
        _readAmount(orderData['discount']) ??
        0.0;
    final total =
        _readAmount(orderData['finalAmount']) ??
        _readAmount(pricing['total']) ??
        _readAmount(orderData['totalAmount']) ??
        (subtotal + deliveryFee + platformFee + tax + lateNightFee - discount);

    return {
      'orderId': (orderData['orderNumber'] ?? orderData['_id'] ?? '')
          .toString(),
      'backendOrderId': (orderData['_id'] ?? '').toString(),
      'placedAt': placedAt,
      'status': status,
      'paymentMethod': (orderData['paymentMethod'] ?? '').toString(),
      'deliveryOption': (orderData['fulfillmentType'] ?? 'delivery').toString(),
      'notes': (orderData['notes'] ?? '').toString(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'tax': tax,
      'lateNightFee': lateNightFee,
      'discount': discount,
      'total': total,
      'itemCount': itemCount,
      'items': normalizedItems,
      'delivery': resolvedDelivery,
      'estimatedDelivery': estimatedDelivery,
      'trackingSteps': trackingSteps,
    };
  }

  DateTime _calculateEstimatedDelivery(String deliveryOption) {
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

  List<Map<String, dynamic>> _initializeTrackingSteps({DateTime? startTime}) {
    final now = startTime ?? DateTime.now();
    return [
      {
        'title': 'Order Placed',
        'description': 'Your order has been received',
        'time': now,
        'completed': true,
      },
      {
        'title': 'Order Confirmed',
        'description': 'Restaurant is preparing your order',
        'time': now.add(const Duration(minutes: 5)),
        'completed': false,
      },
      {
        'title': 'Preparing',
        'description': 'Your food is being prepared',
        'time': now.add(const Duration(minutes: 15)),
        'completed': false,
      },
      {
        'title': 'Ready for Pickup',
        'description': 'Your order is ready and waiting',
        'time': now.add(const Duration(minutes: 25)),
        'completed': false,
      },
      {
        'title': 'Out for Delivery',
        'description': 'Your order is on the way',
        'time': now.add(const Duration(minutes: 30)),
        'completed': false,
      },
      {
        'title': 'Delivered',
        'description': 'Enjoy your meal!',
        'time': now.add(const Duration(minutes: 35)),
        'completed': false,
      },
    ];
  }

  List<Map<String, dynamic>> _buildTrackingStepsForStatus({
    required DateTime placedAt,
    required String status,
  }) {
    final trackingSteps = _initializeTrackingSteps(startTime: placedAt);
    final completedIndex = switch (status) {
      'Confirmed' => 1,
      'Preparing' => 2,
      'Ready for Pickup' => 3,
      'Out for Delivery' => 4,
      'Delivered' => 5,
      _ => 0,
    };

    _markStepsUpTo(trackingSteps, completedIndex);
    return trackingSteps;
  }

  List<Map<String, dynamic>> _normalizeOrderItems(
    dynamic rawItems, {
    List<Map<String, dynamic>>? cartSnapshot,
  }) {
    if (rawItems is List) {
      final normalizedItems = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
            final product = item['product'] is Map
                ? Map<String, dynamic>.from(item['product'] as Map)
                : <String, dynamic>{};
            final images = product['images'];
            String imageUrl = '';
            if (images is List && images.isNotEmpty) {
              imageUrl = _extractImageUrl(images.first) ?? '';
            } else {
              imageUrl =
                  _extractImageUrl(product['image']) ??
                  _extractImageUrl(product['imageUrl']) ??
                  '';
            }

            return {
              'id':
                  (item['productId'] ??
                          product['_id'] ??
                          product['id'] ??
                          item['_id'] ??
                          '')
                      .toString(),
              'name': (item['name'] ?? product['name'] ?? 'Item').toString(),
              'price':
                  _readAmount(item['price']) ??
                  _readAmount(item['unitPrice']) ??
                  0.0,
              'imageUrl': imageUrl,
              'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
            };
          })
          .toList();

      if (normalizedItems.isNotEmpty) {
        return normalizedItems;
      }
    }

    return (cartSnapshot ?? const <Map<String, dynamic>>[])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? _normalizeDeliveryAddress(dynamic rawAddress) {
    if (rawAddress is! Map) {
      return null;
    }

    final address = Map<String, dynamic>.from(rawAddress);
    final location = address['location'] is Map
        ? Map<String, dynamic>.from(address['location'] as Map)
        : <String, dynamic>{};

    final parts = <String>[
      (address['address'] ?? '').toString(),
      (address['landmark'] ?? '').toString(),
      (location['building'] ?? '').toString(),
      (location['room'] ?? '').toString().isEmpty
          ? ''
          : 'Room ${location['room']}',
      (location['floor'] ?? '').toString().isEmpty
          ? ''
          : '${location['floor']} Floor',
    ].where((part) => part.trim().isNotEmpty).toList();

    return {
      'address': (address['address'] ?? '').toString(),
      'type': (address['type'] ?? 'campus').toString(),
      'landmark': (address['landmark'] ?? '').toString(),
      'block': (location['building'] ?? '').toString(),
      'room': (location['room'] ?? '').toString(),
      'floor': (location['floor'] ?? '').toString(),
      'location': location,
      'displayAddress': parts.join(', '),
    };
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  double? _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _normalizeOrderStatus(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
      case 'ready_for_pickup':
      case 'ready for pickup':
        return 'Ready for Pickup';
      case 'out_for_delivery':
      case 'out for delivery':
      case 'on_the_way':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'pending':
      case 'placed':
      default:
        return 'Placed';
    }
  }

  void updateOrderStatus(String orderId) {
    final order = _getOrderById(orderId);
    if (order == null) return;

    final now = DateTime.now();
    final trackingSteps = (order['trackingSteps'] as List)
        .cast<Map<String, dynamic>>();

    // Update order status based on time elapsed
    final timeSincePlaced = now.difference(order['placedAt'] as DateTime);

    if (timeSincePlaced.inMinutes >= 35) {
      order['status'] = 'Delivered';
      _markAllStepsCompleted(trackingSteps);
    } else if (timeSincePlaced.inMinutes >= 30) {
      order['status'] = 'Out for Delivery';
      _markStepsUpTo(trackingSteps, 4);
    } else if (timeSincePlaced.inMinutes >= 25) {
      order['status'] = 'Ready for Pickup';
      _markStepsUpTo(trackingSteps, 3);
    } else if (timeSincePlaced.inMinutes >= 15) {
      order['status'] = 'Preparing';
      _markStepsUpTo(trackingSteps, 2);
    } else if (timeSincePlaced.inMinutes >= 5) {
      order['status'] = 'Confirmed';
      _markStepsUpTo(trackingSteps, 1);
    }

    notifyListeners();
  }

  void _markStepsUpTo(List<Map<String, dynamic>> steps, int index) {
    for (int i = 0; i <= index && i < steps.length; i++) {
      steps[i]['completed'] = true;
    }
  }

  void _markAllStepsCompleted(List<Map<String, dynamic>> steps) {
    for (final step in steps) {
      step['completed'] = true;
    }
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateAllOrderStatuses();
    });
  }

  void _updateAllOrderStatuses() {
    bool hasUpdates = false;
    for (final order in _orderHistory) {
      final orderId = order['orderId'] as String;
      final oldStatus = order['status'] as String;
      updateOrderStatus(orderId);
      if (oldStatus != order['status']) {
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      notifyListeners();
      _persistOrdersToStorage();
    }
  }

  Map<String, dynamic>? getOrderById(String orderId) {
    return _getOrderById(orderId);
  }

  Map<String, dynamic>? _getOrderById(String orderId) {
    for (final order in _orderHistory) {
      if (order['orderId'] == orderId) {
        return order;
      }
    }
    return null;
  }

  Map<String, dynamic>? _getProductRef(String productId) {
    for (final product in _products) {
      if (product['id'] == productId) {
        return product;
      }
    }
    return null;
  }

  Map<String, dynamic>? _getCartItemRef(String productId) {
    for (final item in _cartItems) {
      if (item['id'] == productId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _restoreFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.favoritesKey);

      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final favoriteIds = <String>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final id = (entry['id'] ?? '').toString();
        if (id.isNotEmpty) {
          favoriteIds.add(id);
        }
      }

      for (final product in _products) {
        if (favoriteIds.contains(product['id'])) {
          product['isFavorite'] = true;
        }
      }
      notifyListeners();
    } catch (_) {
      // Ignore invalid persisted favorites data.
    }
  }

  Future<void> _persistFavoritesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteProducts = _products
          .where((product) => product['isFavorite'] == true)
          .map((product) => {'id': product['id']})
          .toList();
      await prefs.setString(
        AppConstants.favoritesKey,
        jsonEncode(favoriteProducts),
      );
    } catch (_) {
      // Ignore persistence errors and keep in-memory behavior.
    }
  }

  Future<void> _restoreCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.cartKey);

      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final restoredItems = <Map<String, dynamic>>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(entry);
        final id = (item['id'] ?? '').toString();
        if (id.isEmpty) {
          continue;
        }

        restoredItems.add({
          'id': id,
          'name': (item['name'] ?? '').toString(),
          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
          'imageUrl': (item['imageUrl'] ?? '').toString(),
          'canteenName': (item['canteenName'] ?? '').toString(),
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
          'rating': (item['rating'] as num?)?.toDouble() ?? 0.0,
          'reviewCount': (item['reviewCount'] as num?)?.toInt() ?? 0,
        });
      }

      if (restoredItems.isEmpty) {
        return;
      }

      _cartItems
        ..clear()
        ..addAll(restoredItems);
      notifyListeners();
    } catch (_) {
      // Ignore invalid persisted cart data.
    }
  }

  Future<void> _persistCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cartKey, jsonEncode(_cartItems));
    } catch (_) {
      // Ignore persistence errors and keep in-memory behavior.
    }
  }

  Future<void> _restoreOrdersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('order_history');

      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final restoredOrders = <Map<String, dynamic>>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final order = Map<String, dynamic>.from(entry);

        // Convert DateTime strings back to DateTime objects
        if (order['placedAt'] is String) {
          order['placedAt'] = DateTime.parse(order['placedAt']);
        }
        if (order['estimatedDelivery'] is String) {
          order['estimatedDelivery'] = DateTime.parse(
            order['estimatedDelivery'],
          );
        }

        // Convert tracking steps DateTime strings back to DateTime objects
        if (order['trackingSteps'] is List) {
          final trackingSteps = (order['trackingSteps'] as List)
              .whereType<Map>()
              .map((step) => Map<String, dynamic>.from(step))
              .toList();

          for (final step in trackingSteps) {
            if (step['time'] is String) {
              step['time'] = DateTime.parse(step['time']);
            }
          }
          order['trackingSteps'] = trackingSteps;
        }

        restoredOrders.add(order);
      }

      if (restoredOrders.isNotEmpty) {
        _orderHistory
          ..clear()
          ..addAll(restoredOrders);
        notifyListeners();
      }
    } catch (_) {
      // Ignore invalid persisted orders data.
    }
  }

  Future<void> _persistOrdersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert DateTime objects to strings for JSON serialization
      final serializableOrders = _orderHistory.map((order) {
        final serializableOrder = Map<String, dynamic>.from(order);

        // Convert DateTime to string
        if (serializableOrder['placedAt'] is DateTime) {
          serializableOrder['placedAt'] =
              (serializableOrder['placedAt'] as DateTime).toIso8601String();
        }
        if (serializableOrder['estimatedDelivery'] is DateTime) {
          serializableOrder['estimatedDelivery'] =
              (serializableOrder['estimatedDelivery'] as DateTime)
                  .toIso8601String();
        }

        // Convert tracking steps DateTime to strings
        if (serializableOrder['trackingSteps'] is List) {
          final trackingSteps = (serializableOrder['trackingSteps'] as List)
              .whereType<Map>()
              .map((step) => Map<String, dynamic>.from(step))
              .toList();

          for (final step in trackingSteps) {
            if (step['time'] is DateTime) {
              step['time'] = (step['time'] as DateTime).toIso8601String();
            }
          }
          serializableOrder['trackingSteps'] = trackingSteps;
        }

        return serializableOrder;
      }).toList();

      await prefs.setString('order_history', jsonEncode(serializableOrders));
    } catch (_) {
      // Ignore persistence errors and keep in-memory behavior.
    }
  }
}

class AppStateScope extends InheritedNotifier<CampusAppState> {
  const AppStateScope({
    super.key,
    required CampusAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static CampusAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree.');
    return scope!.notifier!;
  }
}
