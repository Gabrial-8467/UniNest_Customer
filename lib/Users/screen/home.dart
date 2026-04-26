import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/canteen_card.dart';
import '../widgets/product_card.dart';
import 'all_canteens.dart';
import 'canteen_menu.dart';
import 'product_details.dart';
import 'search_results_screen.dart';
import 'secret_signature_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, this.onOpenCart, this.onOpenProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String selectedCanteenId = 'All';

  // Cached future for featured products to prevent rebuilds
  late Future<Map<String, dynamic>> _featuredProductsFuture;

  // Memoized filtered results to avoid recomputation
  List<Map<String, dynamic>>? _cachedFilteredCanteens;
  List<Map<String, dynamic>>? _cachedFilteredProducts;
  String _lastSelectedCategory = '';
  int _lastProductCount = 0;
  int _lastCanteenCount = 0;

  // Active order toast variables
  bool _showOrderToast = false;
  String? _activeOrderId;
  String _orderStatus = 'preparing';
  String? _orderVendorName;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    // Initialize cached future for featured products
    _featuredProductsFuture = _fetchFeaturedProducts();
    // Check for active orders when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveOrders();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // Check for active orders and show toast if found
  Future<void> _checkForActiveOrders() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;

      final result = await ApiService.getUserOrders(
        token: token,
        page: 1,
        limit: 1,
      );

      if (result['success'] == true) {
        final orders = result['data']['orders'] as List<dynamic>?;
        if (orders != null && orders.isNotEmpty) {
          final latestOrder = orders.first;
          final status = latestOrder['status']?.toString() ?? 'preparing';

          // Only show toast for active orders (not delivered/cancelled)
          if (!['delivered', 'cancelled', 'rejected'].contains(status)) {
            final orderId =
                latestOrder['_id']?.toString() ??
                latestOrder['id']?.toString() ??
                '';
            final vendorName =
                latestOrder['vendorName']?.toString() ??
                latestOrder['canteenName']?.toString() ??
                'Campus Eats';

            if (orderId.isNotEmpty) {
              _showOrderStatusToast(orderId, vendorName, status);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for active orders: $e');
    }
  }

  // Secret signature screen variables
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const int _requiredTaps = 5;
  static const Duration _tapTimeWindow = Duration(seconds: 2);

  // Icon mapping for categories
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'burgers':
        return Icons.lunch_dining_rounded;
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'drinks':
        return Icons.local_cafe_rounded;
      case 'desserts':
        return Icons.icecream_rounded;
      case 'snacks':
        return Icons.fastfood_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  // Secret signature screen logic
  void _onLogoTap() {
    final now = DateTime.now();

    // Reset tap count if too much time has passed
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > _tapTimeWindow) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Check if secret sequence is completed
    if (_tapCount >= _requiredTaps) {
      _tapCount = 0;
      _lastTapTime = null;
      _showSecretSignatureScreen();
    }
  }

  Widget _buildOrderToast() {
    final statusColors = {
      'preparing': Colors.orange,
      'ready': Colors.green,
      'out_for_delivery': Colors.blue,
      'delivered': Colors.grey,
    };

    final statusIcons = {
      'preparing': Icons.restaurant,
      'ready': Icons.check_circle,
      'out_for_delivery': Icons.delivery_dining,
      'delivered': Icons.done_all,
    };

    final statusText = {
      'preparing': 'Preparing your order',
      'ready': 'Ready for pickup',
      'out_for_delivery': 'Out for delivery',
      'delivered': 'Delivered',
    };

    return GestureDetector(
      onTap: () {
        if (_activeOrderId != null) {
          Navigator.pushNamed(
            context,
            '/order-tracking',
            arguments: _activeOrderId,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColors[_orderStatus] ?? AppColors.primary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (statusColors[_orderStatus] ?? AppColors.primary)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcons[_orderStatus] ?? Icons.restaurant,
                color: statusColors[_orderStatus] ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText[_orderStatus] ?? 'Order in progress',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _orderVendorName ?? 'Campus Eats',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showOrderToast = false;
                  _toastTimer?.cancel();
                });
              },
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderStatusToast(String orderId, String vendorName, String status) {
    _toastTimer?.cancel();
    setState(() {
      _showOrderToast = true;
      _activeOrderId = orderId;
      _orderVendorName = vendorName;
      _orderStatus = status;
    });

    // Start real-time polling for order status updates
    _startOrderStatusPolling(orderId);
  }

  void _startOrderStatusPolling(String orderId) {
    _toastTimer?.cancel();
    _toastTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final token = await AuthService.getToken();
        if (token == null || token.isEmpty) return;

        final result = await ApiService.getUserOrders(
          token: token,
          page: 1,
          limit: 1,
        );
        if (result['success'] == true) {
          final orders = result['data']['orders'] as List<dynamic>?;
          if (orders != null && orders.isNotEmpty) {
            final latestOrder = orders.firstWhere(
              (o) => o['_id'] == orderId || o['id'] == orderId,
              orElse: () => null,
            );

            if (latestOrder != null) {
              final newStatus =
                  latestOrder['status']?.toString() ?? _orderStatus;
              if (newStatus != _orderStatus) {
                setState(() => _orderStatus = newStatus);
              }

              // Stop polling if order is delivered or cancelled
              if (['delivered', 'cancelled', 'rejected'].contains(newStatus)) {
                timer.cancel();
                // Auto-hide after 5 seconds for final states
                Timer(const Duration(seconds: 5), () {
                  if (mounted) {
                    setState(() => _showOrderToast = false);
                  }
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error polling order status: $e');
      }
    });

    // Initial delay before first poll
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      try {
        final token = await AuthService.getToken();
        if (token == null || token.isEmpty) return;

        final result = await ApiService.getUserOrders(
          token: token,
          page: 1,
          limit: 1,
        );
        if (result['success'] == true) {
          final orders = result['data']['orders'] as List<dynamic>?;
          if (orders != null && orders.isNotEmpty) {
            final latestOrder = orders.firstWhere(
              (o) => o['_id'] == orderId || o['id'] == orderId,
              orElse: () => null,
            );
            if (latestOrder != null && mounted) {
              setState(
                () => _orderStatus =
                    latestOrder['status']?.toString() ?? _orderStatus,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error in initial order status fetch: $e');
      }
    });
  }

  void _showSecretSignatureScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SecretSignatureScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredCanteens(
    List<Map<String, dynamic>> canteens,
  ) {
    // Sort canteens by rating score (highest first)
    final sortedCanteens = canteens.toList()
      ..sort((a, b) {
        final ratingA = _extractRating(a);
        final ratingB = _extractRating(b);
        return ratingB.compareTo(ratingA); // Descending order
      });
    return sortedCanteens;
  }

  double _extractRating(Map<String, dynamic> canteen) {
    final ratingData = canteen['rating'];
    if (ratingData is Map<String, dynamic>) {
      final average = ratingData['average'];
      if (average is num) return average.toDouble();
    } else if (ratingData is num) {
      return ratingData.toDouble();
    }
    return 0.0;
  }

  List<Map<String, dynamic>> _filteredProducts(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> canteens,
  ) {
    // Only filter by category and canteen on home screen
    // Search filtering happens on separate search results page
    final filtered = products.where((product) {
      final canteenId = (product['canteenId'] ?? '').toString();

      if (selectedCanteenId != 'All' && canteenId != selectedCanteenId) {
        return false;
      }

      if (selectedCategory != 'All') {
        final productCategory = (product['category'] ?? '')
            .toString()
            .toLowerCase();
        return productCategory == selectedCategory.toLowerCase();
      }

      return true;
    }).toList();

    // Sort products by rating (highest first)
    filtered.sort((a, b) {
      final ratingA = _extractProductRating(a);
      final ratingB = _extractProductRating(b);
      return ratingB.compareTo(ratingA);
    });

    return filtered;
  }

  double _extractProductRating(Map<String, dynamic> product) {
    final ratingData = product['rating'];
    if (ratingData is Map<String, dynamic>) {
      final average = ratingData['average'];
      if (average is num) return average.toDouble();
    } else if (ratingData is num) {
      return ratingData.toDouble();
    }
    // Also check vendor rating
    final vendor = product['vendor'];
    if (vendor is Map<String, dynamic>) {
      final vendorRating = vendor['rating'];
      if (vendorRating is num) return vendorRating.toDouble();
      if (vendorRating is Map<String, dynamic>) {
        final average = vendorRating['average'];
        if (average is num) return average.toDouble();
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allCanteens = appState.canteens.toList();
        final allProducts = appState.products.toList();

        // Use memoized results if inputs haven't changed
        final bool shouldRecalculateCanteens =
            _cachedFilteredCanteens == null ||
            _lastCanteenCount != allCanteens.length;

        final bool shouldRecalculateProducts =
            _cachedFilteredProducts == null ||
            _lastSelectedCategory != selectedCategory ||
            _lastProductCount != allProducts.length;

        if (shouldRecalculateCanteens) {
          _cachedFilteredCanteens = _filteredCanteens(allCanteens);
          _lastCanteenCount = allCanteens.length;
        }

        if (shouldRecalculateProducts) {
          _cachedFilteredProducts = _filteredProducts(allProducts, allCanteens);
          _lastSelectedCategory = selectedCategory;
          _lastProductCount = allProducts.length;
        }

        final canteens = _cachedFilteredCanteens!.take(4).toList();
        final products = _cachedFilteredProducts!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(appState),
          body: RefreshIndicator(
            onRefresh: () async {
              await appState.refreshAllData();
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar()),
                if (_showOrderToast)
                  SliverToBoxAdapter(child: _buildOrderToast()),
                SliverToBoxAdapter(child: _buildCategories()),
                if (appState.hasConnectionError)
                  SliverToBoxAdapter(
                    child: _buildErrorBanner(appState.errorMessage),
                  ),
                if (appState.isLoadingProducts ||
                    appState.isLoadingCanteens ||
                    appState.isLoadingCategories)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                  )
                else
                  ..._buildMainContent(appState, canteens, products),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CampusAppState appState) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: GestureDetector(
        onTap: _onLogoTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/uninest.jpeg',
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'UNINEST',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchResultsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textLight),
              const SizedBox(width: 12),
              Text(
                'Search products or canteens...',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return AnimatedBuilder(
      animation: AppStateScope.of(context),
      builder: (context, _) {
        final appState = AppStateScope.of(context);
        final categories = ['All', ...appState.categories];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: appState.isLoadingCategories
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == selectedCategory;

                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMainContent(
    CampusAppState appState,
    List<Map<String, dynamic>> canteens,
    List<Map<String, dynamic>> products,
  ) {
    return [
      SliverToBoxAdapter(
        child: _buildCanteenSection(canteens, appState.isLoadingCanteens),
      ),
      SliverToBoxAdapter(child: _buildFeaturedProductsSection(appState)),
      if (products.isEmpty && !appState.isLoadingProducts)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            'No products available',
            'Connect to backend to load products',
          ),
        )
      else
        _buildProductsSliver(appState, products),
    ];
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
          return p['isFeatured'] == true || p['featured'] == true;
        }).toList();

        if (featuredProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical List of Featured Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return _buildFeaturedProductCard(product, appState);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchFeaturedProducts() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.getFeaturedProducts(token: token);
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
    // Extract vendor name - check nested vendor object first
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

    // Only show rating if it's greater than 0
    // Handle both num and Map<String, dynamic> formats
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
              // Image Section
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
                  // Rating Badge
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
                  // Favorite Icon
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
              // Info Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
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
                    // Cuisine and Price
                    Text(
                      cuisine.isNotEmpty
                          ? '$cuisine \u2022 \u20B9${price.toStringAsFixed(0)} for one'
                          : '\u20B9${price.toStringAsFixed(0)} for one',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    // Delivery Info (only if data exists)
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
                    // Offer Badge (only if data exists)
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
                                  color: Color(0xFF2E7D32),
                                  fontSize: 11,
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

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentDark,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.accentDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final appState = AppStateScope.of(context);
                await appState.refreshAllData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanteenSection(
    List<Map<String, dynamic>> canteens,
    bool isLoadingCanteens,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Canteens',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (selectedCanteenId != 'All')
                  IconButton(
                    tooltip: 'Clear canteen filter',
                    onPressed: () {
                      setState(() {
                        selectedCanteenId = 'All';
                      });
                    },
                    icon: const Icon(
                      Icons.filter_alt_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllCanteensScreen(initialSearchQuery: ''),
                      ),
                    );
                  },
                  child: const Text('Show More'),
                ),
              ],
            ),
          ),
          canteens.isEmpty
              ? Container(
                  height: 86,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.textLight),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.textLight,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No canteens available',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 146,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: canteens.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final canteen = canteens[index];
                      final canteenId = (canteen['id'] ?? '').toString();
                      final isSelected = selectedCanteenId == canteenId;

                      return CanteenCard(
                        name: (canteen['name'] ?? 'Canteen').toString(),
                        location: (canteen['location'] ?? '').toString(),
                        rating: (canteen['rating'] as num?)?.toDouble() ?? 0,
                        isOpen: canteen['isOpen'] == true,
                        isSelected: isSelected,
                        imageUrl: canteen['imageUrl']?.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CanteenMenuScreen(canteenId: canteenId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  SliverPadding _buildProductsSliver(
    CampusAppState appState,
    List<Map<String, dynamic>> products,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];

          // Extract rating with proper type handling
          final dynamic ratingData = product['rating'];
          double rating = 0.0;
          if (ratingData is num) {
            rating = ratingData.toDouble();
          } else if (ratingData is Map<String, dynamic>) {
            final avg = ratingData['average'];
            if (avg is num) rating = avg.toDouble();
          }

          // Extract review count
          final dynamic reviewCountData = product['reviewCount'];
          int reviewCount = 0;
          if (reviewCountData is num) {
            reviewCount = reviewCountData.toInt();
          } else if (ratingData is Map<String, dynamic>) {
            final count = ratingData['count'];
            if (count is num) reviewCount = count.toInt();
          }

          return ProductCard(
            productId: (product['id'] ?? '').toString(),
            name: (product['name'] ?? 'Product Name').toString(),
            price: (product['price'] as num?)?.toDouble() ?? 0,
            imageUrl: product['imageUrl'] is Map
                ? product['imageUrl']['url'] ?? ''
                : (product['imageUrl'] ?? '').toString(),
            canteenName: (product['canteenName'] ?? 'Unknown').toString(),
            rating: rating,
            reviewCount: reviewCount,
            isFavorite: product['isFavorite'] == true,
            discount: product['discount']?.toString(),
            isNew: product['isNew'] == true,
            availability: product['availability']?.toString(),
            onTap: () {
              final productId = (product['id'] ?? '').toString();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailsScreen(productId: productId),
                ),
              );
            },
            onFavoriteTap: () {
              final productId = (product['id'] ?? '').toString();
              final nextValue = !(product['isFavorite'] == true);
              appState.setFavorite(productId, nextValue);
            },
            onAddToCart: () {
              final added = appState.addToCart(
                (product['id'] ?? '').toString(),
              );
              if (added) {
                _showAddToCartSnackbar();
              }
            },
          );
        }, childCount: products.length),
      ),
    );
  }

  void _showAddToCartSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Item added to cart!'),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
