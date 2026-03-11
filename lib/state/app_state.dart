import 'dart:collection';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class CampusAppState extends ChangeNotifier {
  CampusAppState()
    : _canteens = _cloneList(kRegisteredCanteens),
      _products = _cloneList(kCatalogProducts);

  final List<Map<String, dynamic>> _canteens;
  final List<Map<String, dynamic>> _products;
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _orderHistory = [];

  UnmodifiableListView<Map<String, dynamic>> get canteens =>
      UnmodifiableListView(_canteens);

  UnmodifiableListView<Map<String, dynamic>> get products =>
      UnmodifiableListView(_products);

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

  double get tax => subtotal * 0.08;

  double get total => subtotal + deliveryFee + tax;

  List<Map<String, dynamic>> get favoriteProducts => _products
      .where((product) => product['isFavorite'] == true)
      .map((product) => Map<String, dynamic>.from(product))
      .toList();

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
  }

  void toggleFavorite(String productId) {
    final product = _getProductRef(productId);
    if (product == null) {
      return;
    }
    product['isFavorite'] = !(product['isFavorite'] == true);
    notifyListeners();
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
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }

  void clearCart() {
    if (_cartItems.isEmpty) {
      return;
    }
    _cartItems.clear();
    notifyListeners();
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
      'tax': tax,
      'total': total,
      'itemCount': cartItemCount,
      'items': _cartItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    });

    _cartItems.clear();
    notifyListeners();
    return orderId;
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

  static List<Map<String, dynamic>> _cloneList(
    List<Map<String, dynamic>> source,
  ) {
    return source
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
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
