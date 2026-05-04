import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';
import 'product_details.dart';

class CanteenMenuScreen extends StatefulWidget {
  final String canteenId;

  const CanteenMenuScreen({super.key, required this.canteenId});

  @override
  State<CanteenMenuScreen> createState() => _CanteenMenuScreenState();
}

class _CanteenMenuScreenState extends State<CanteenMenuScreen> {
  String selectedCategory = 'All';

  // Cached future for featured products to prevent rebuilds
  late Future<Map<String, dynamic>> _featuredProductsFuture;

  final List<String> categories = const [
    'All',
    'Burgers',
    'Pizza',
    'Drinks',
    'Desserts',
    'Snacks',
  ];

  List<Map<String, dynamic>> _filteredProducts(
    List<Map<String, dynamic>> products,
  ) {
    return products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();

      if (selectedCategory == 'All') {
        return true;
      }

      switch (selectedCategory) {
        case 'Burgers':
          return name.contains('burger');
        case 'Pizza':
          return name.contains('pizza');
        case 'Drinks':
          return name.contains('shake') || name.contains('coffee');
        case 'Desserts':
          return name.contains('ice cream') ||
              name.contains('sundae') ||
              name.contains('dessert');
        case 'Snacks':
          return name.contains('fries') ||
              name.contains('wings') ||
              name.contains('sandwich');
        default:
          return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize cached future for featured products
    _featuredProductsFuture = _fetchFeaturedProducts();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        Map<String, dynamic> canteen;
        try {
          canteen = appState.canteens.firstWhere(
            (c) => c['id'] == widget.canteenId,
          );
        } catch (e) {
          canteen = <String, dynamic>{};
        }
        final isCanteenOpen = canteen.isEmpty || canteen['isOpen'] == true;
        final products = appState.productsByCanteen(widget.canteenId);
        final filtered = _filteredProducts(products);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              canteen['name'] ?? 'Canteen Menu',
              style: const TextStyle(
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildCanteenHeader(canteen),
                if (!isCanteenOpen)
                  _buildClosedCanteenNotice(canteen)
                else ...[
                  _buildCategories(),
                  if (selectedCategory == 'All')
                    _buildFeaturedProductsSection(appState),
                  filtered.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: ProductGrid(
                            products: filtered,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onProductTap: (productId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(
                                    productId: productId,
                                  ),
                                ),
                              );
                            },
                            onFavoriteToggle: (productId, isFavorite) {
                              appState.setFavorite(productId, isFavorite);
                            },
                            getCartQuantity: (productId) =>
                                appState.getCartQuantity(productId),
                            onQuantityChanged: (productId, quantity) {
                              if (quantity <= 0) {
                                appState.removeFromCart(productId);
                              } else if (appState.getCartQuantity(productId) ==
                                  0) {
                                final added = appState.addToCart(
                                  productId,
                                  quantity: quantity,
                                );
                                if (added) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                      backgroundColor: Color(0xFFFF6B6B),
                                    ),
                                  );
                                }
                              } else {
                                appState.updateCartQuantity(
                                  productId,
                                  quantity,
                                );
                              }
                            },
                          ),
                        ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanteenHeader(Map<String, dynamic>? canteen) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront, color: Color(0xFFFF6B6B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canteen?['name'] ?? 'Canteen',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canteen?['location'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (canteen?['isOpen'] == true ? Colors.green : Colors.red)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              canteen?['isOpen'] == true ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: canteen?['isOpen'] == true ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 80),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF2D3436),
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_food, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No menu items found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your category filter.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedCanteenNotice(Map<String, dynamic>? canteen) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${canteen?['name'] ?? 'This canteen'} is closed',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menu items will be available when the canteen opens again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  bool _isFeaturedProductVisible(
    Map<dynamic, dynamic> product,
    CampusAppState appState,
  ) {
    final canteen = appState.getCanteenById(widget.canteenId);
    if (canteen != null) {
      return canteen['isOpen'] == true;
    }

    final vendor = product['vendor'];
    if (vendor is Map) {
      return _isVendorOpen(vendor);
    }

    return true;
  }

  bool _isVendorOpen(Map<dynamic, dynamic> vendor) {
    final explicitOpen = _readBoolField(vendor, const [
      'isOpen',
      'is_open',
      'open',
      'isCurrentlyOpen',
      'currentlyOpen',
      'isAvailable',
      'available',
      'isAcceptingOrders',
      'acceptingOrders',
      'canteenOpen',
    ]);
    if (explicitOpen != null) return explicitOpen;

    final businessDetails = vendor['businessDetails'];
    if (businessDetails is Map) {
      final businessOpen = _readBoolField(businessDetails, const [
        'isOpen',
        'isAvailable',
        'isAcceptingOrders',
        'acceptingOrders',
        'canteenOpen',
      ]);
      if (businessOpen != null) return businessOpen;
    }

    final explicitClosed = _readBoolField(vendor, const [
      'isClosed',
      'closed',
      'isCurrentlyClosed',
      'currentlyClosed',
    ]);
    if (explicitClosed != null) return !explicitClosed;

    final status = vendor['status']?.toString().trim().toLowerCase();
    if (status != null && status.isNotEmpty) {
      if (const {
        'closed',
        'inactive',
        'disabled',
        'offline',
        'unavailable',
        'temporarily_closed',
        'temporarily closed',
      }.contains(status)) {
        return false;
      }
      if (const {'open', 'online', 'available'}.contains(status)) return true;
    }

    return true;
  }

  bool? _readBoolField(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (const {
          'true',
          '1',
          'yes',
          'open',
          'available',
          'online',
        }.contains(normalized)) {
          return true;
        }
        if (const {
          'false',
          '0',
          'no',
          'closed',
          'unavailable',
          'offline',
        }.contains(normalized)) {
          return false;
        }
      }
    }
    return null;
  }

  Widget _buildFeaturedProductsSection(CampusAppState appState) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final result = snapshot.data!;
        if (result['success'] != true) {
          return const SizedBox.shrink();
        }

        final data = result['data'];
        final List<dynamic> allProducts = data is Map
            ? (data['products'] ?? [])
            : (data ?? []);

        // Filter only featured products
        final List<dynamic> featuredProducts = allProducts.where((p) {
          if (p is! Map) return false;
          final isFeatured = p['isFeatured'] == true || p['featured'] == true;
          return isFeatured && _isFeaturedProductVisible(p, appState);
        }).toList();

        if (featuredProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return _buildFeaturedProductCard(product, appState);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchFeaturedProducts() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getFeaturedProducts(
        token: token,
        vendor: widget.canteenId,
      );
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Widget _buildFeaturedProductCard(
    Map<String, dynamic> product,
    CampusAppState appState,
  ) {
    final productId = (product['id'] ?? product['_id'] ?? '').toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final images = product['images'];
    String imageUrl = '';
    if (images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map) {
        imageUrl = (firstImage['url'] ?? '').toString();
      } else {
        imageUrl = firstImage.toString();
      }
    } else {
      imageUrl = (product['imageUrl'] ?? product['image'] ?? '').toString();
    }

    // Extract vendor name
    String canteenName = 'Unknown';
    final vendor = product['vendor'];
    if (vendor is Map) {
      canteenName =
          (vendor['name'] ??
                  vendor['businessName'] ??
                  vendor['canteenName'] ??
                  'Unknown')
              .toString();
    } else {
      canteenName =
          (product['canteenName'] ??
                  product['vendorName'] ??
                  product['businessName'] ??
                  'Unknown')
              .toString();
    }

    // Extract rating
    final dynamic rawRatingData = product['rating'];
    double? rawRating;
    if (rawRatingData is num) {
      rawRating = rawRatingData.toDouble();
    } else if (rawRatingData is Map<String, dynamic>) {
      final avg = rawRatingData['average'];
      if (avg is num) {
        rawRating = avg.toDouble();
      }
    }
    final rating = (rawRating != null && rawRating > 0) ? rawRating : null;
    final cuisine = (product['category'] ?? '').toString();
    final deliveryTime = product['deliveryTime']?.toString();
    final distance = product['distance']?.toString();
    final offer = product['offer']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(productId: productId),
            ),
          );
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                            ),
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                            ),
                          ),
                  ),
                  if (rating != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteenName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cuisine.isNotEmpty
                          ? '$cuisine \u2022 \u20B9${price.toStringAsFixed(0)} for one'
                          : '\u20B9${price.toStringAsFixed(0)} for one',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (deliveryTime != null || distance != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (deliveryTime != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                deliveryTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (deliveryTime != null && distance != null)
                              const SizedBox(width: 12),
                            if (distance != null) ...[
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (offer != null && offer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 12,
                                color: const Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                offer,
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
