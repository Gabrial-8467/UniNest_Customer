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
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> _canteens = [];
  final List<Map<String, dynamic>> _products = [];
  final List<String> _categories = [];
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _orderHistory = [];
  Timer? _statusUpdateTimer;
  bool _isLoadingProducts = false;
  bool _isLoadingCanteens = false;
  bool _isLoadingCategories = false;
  bool _hasConnectionError = false;
  String _errorMessage = '';

  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingCanteens => _isLoadingCanteens;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get hasConnectionError => _hasConnectionError;
  String get errorMessage => _errorMessage;

  Future<void> _initializeBackendData() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      _setGuestModeDefaults();
      return;
    }

    await refreshAllData();
  }

  void _setGuestModeDefaults() {
    _hasConnectionError = false;
    _errorMessage = '';
    _categories
      ..clear()
      ..addAll(['All', 'Burgers', 'Pizza', 'Drinks', 'Desserts', 'Snacks']);
    notifyListeners();
  }

  // Fetch products from backend API
  Future<void> _fetchProductsFromBackend() async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      debugPrint('🔍 AppState: Fetching products from backend...');
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        _products.clear();
        _hasConnectionError = false;
        _errorMessage = '';
        return;
      }

      final response = await ApiService.getProducts(token: token);

      if (response['success'] == true) {
        final List<dynamic> productsData = response['data'];
        _products.clear();

        for (final product in productsData) {
          if (product is Map<String, dynamic>) {
            // Convert backend product format to app format
            final appProduct = {
              'id':
                  product['_id']?.toString() ?? product['id']?.toString() ?? '',
              'name': product['name'] ?? '',
              'description': product['description'] ?? '',
              'price': (product['price'] as num?)?.toDouble() ?? 0.0,
              'category': product['category'] ?? '',
              'imageUrl': product['image'] ?? product['imageUrl'] ?? '',
              'stock': product['stock'] ?? 0,
              'canteenId': 'default', // Add default canteen ID
              'canteenName': 'Main Canteen', // Add default canteen name
              'rating': 4.0, // Add default rating
              'reviewCount': 10, // Add default review count
              'isFavorite': false, // Add default favorite status
            };
            _products.add(appProduct);
          }
        }

        debugPrint(
          '✅ AppState: Loaded ${_products.length} products from backend',
        );
        _hasConnectionError = false;
        _errorMessage = '';
      } else {
        debugPrint(
          '❌ AppState: Failed to fetch products: ${response['error']}',
        );
        _hasConnectionError = true;
        _errorMessage = response['error'] ?? 'Failed to load products';
      }
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
    await Future.wait([
      _fetchProductsFromBackend(),
      _fetchCanteensFromBackend(),
      _fetchCategoriesFromBackend(),
    ]);
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
        // If no products, try to fetch categories from products endpoint
        final token = await AuthService.getToken();
        if (token == null || token.isEmpty) {
          _setGuestModeDefaults();
          return;
        }

        final response = await ApiService.getProducts(token: token);
        if (response['success'] == true) {
          final List<dynamic> productsData = response['data'];
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
    _hasConnectionError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('🔍 AppState: Fetching canteens from backend...');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        _canteens.clear();
        _hasConnectionError = false;
        _errorMessage = '';
        return;
      }

      final response = await ApiService.getCanteens(token: token);

      if (response['success'] == true) {
        final List<dynamic> canteensData = response['data'];
        _canteens.clear();

        for (final canteen in canteensData) {
          if (canteen is Map<String, dynamic>) {
            // Convert backend canteen format to app format
            final appCanteen = {
              'id':
                  canteen['_id']?.toString() ?? canteen['id']?.toString() ?? '',
              'name': canteen['name'] ?? '',
              'location': canteen['location'] ?? '',
              'rating': (canteen['rating'] as num?)?.toDouble() ?? 0.0,
              'reviewCount': (canteen['reviewCount'] as num?)?.toInt() ?? 0,
              'isOpen': canteen['isOpen'] ?? true,
              'imageUrl': canteen['image'] ?? canteen['imageUrl'] ?? '',
              'description': canteen['description'] ?? '',
              'openingTime': canteen['openingTime'] ?? '08:00',
              'closingTime': canteen['closingTime'] ?? '20:00',
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
    notifyListeners();
    _persistCartToStorage();
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

  List<Map<String, dynamic>> _initializeTrackingSteps() {
    final now = DateTime.now();
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
