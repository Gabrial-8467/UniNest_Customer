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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String selectedCategory = 'All';
  String selectedCanteenId = 'All';

  // Memoized filtered results to avoid recomputation
  List<Map<String, dynamic>>? _cachedFilteredCanteens;
  List<Map<String, dynamic>>? _cachedFilteredProducts;
  String _lastSelectedCategory = '';
  int _lastProductCount = 0;
  int _lastCanteenCount = 0;
  String _lastCanteenFingerprint = '';
  String _lastProductFingerprint = '';
  bool _lastVegMode = false;

  // Active order toast variables
  bool _showOrderToast = false;
  String? _activeOrderId;
  String _orderStatus = 'preparing';
  String? _orderVendorName;
  Timer? _toastTimer;

  // Polling optimization
  int _pollingAttemptCount = 0;
  static const int _maxPollingAttempts = 30; // Stop after 30 minutes of polling
  static const Duration _orderPollingInterval = Duration(
    minutes: 1,
  ); // Was 30 seconds

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Check for active orders when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveOrders();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Pause polling when app goes to background
      _toastTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && _activeOrderId != null) {
      // Resume polling when app comes back if there's an active order
      if (_showOrderToast && _activeOrderId != null) {
        _startOrderStatusPolling(_activeOrderId!);
      }
    }
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
                'UniNest';

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
                    _orderVendorName ?? 'UniNest',
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
    _pollingAttemptCount = 0;

    _toastTimer = Timer.periodic(_orderPollingInterval, (timer) async {
      // Check max attempts to prevent indefinite polling
      _pollingAttemptCount++;
      if (_pollingAttemptCount >= _maxPollingAttempts) {
        debugPrint('⏹️ Max polling attempts reached, stopping order polling');
        timer.cancel();
        return;
      }

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

  String _canteenFingerprint(List<Map<String, dynamic>> canteens) {
    return canteens
        .map((canteen) {
          final id = (canteen['id'] ?? '').toString();
          final isOpen = canteen['isOpen'] == true;
          return '$id:$isOpen';
        })
        .join('|');
  }

  String _productFingerprint(List<Map<String, dynamic>> products) {
    return products
        .map((product) {
          final id = (product['id'] ?? '').toString();
          final canteenId = (product['canteenId'] ?? '').toString();
          return '$id:$canteenId';
        })
        .join('|');
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allCanteens = appState.canteens.toList();
        final allProducts = appState.products.toList();
        final canteenFingerprint = _canteenFingerprint(allCanteens);
        final productFingerprint = _productFingerprint(allProducts);

        // Use memoized results if inputs haven't changed
        final bool shouldRecalculateCanteens =
            _cachedFilteredCanteens == null ||
            _lastCanteenCount != allCanteens.length ||
            _lastCanteenFingerprint != canteenFingerprint;

        final bool shouldRecalculateProducts =
            _cachedFilteredProducts == null ||
            _lastSelectedCategory != selectedCategory ||
            _lastProductCount != allProducts.length ||
            _lastProductFingerprint != productFingerprint ||
            _lastVegMode != appState.vegMode;

        if (shouldRecalculateCanteens) {
          _cachedFilteredCanteens = _filteredCanteens(allCanteens);
          _lastCanteenCount = allCanteens.length;
          _lastCanteenFingerprint = canteenFingerprint;
        }

        if (shouldRecalculateProducts) {
          _cachedFilteredProducts = _filteredProducts(allProducts, allCanteens);
          _lastSelectedCategory = selectedCategory;
          _lastProductCount = allProducts.length;
          _lastProductFingerprint = productFingerprint;
          _lastVegMode = appState.vegMode;
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
                SliverToBoxAdapter(child: _buildSearchBar(appState)),
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
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: GestureDetector(
        onTap: _onLogoTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/uninest.png',
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

  Widget _buildSearchBar(CampusAppState appState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textLight),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Search...',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _VegModeToggle(appState: appState),
        ],
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
    final appState = AppStateScope.of(context);
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
                      final cartCanteenId = appState.cartCanteenId;
                      final isDisabled =
                          cartCanteenId != null && cartCanteenId != canteenId;

                      return CanteenCard(
                        name: (canteen['name'] ?? 'Canteen').toString(),
                        location: (canteen['location'] ?? '').toString(),
                        rating: (canteen['rating'] as num?)?.toDouble() ?? 0,
                        isOpen: canteen['isOpen'] == true,
                        isSelected: isSelected,
                        imageUrl: canteen['imageUrl']?.toString(),
                        isDisabled: isDisabled,
                        onTap: () {
                          if (isDisabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Clear cart to add items from this canteen',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
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
      sliver: SliverList(
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

          final productId = (product['id'] ?? '').toString();
          final cartQuantity = appState.getCartQuantity(productId);
          final canAddToCart = appState.canAddToCart(productId);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < products.length - 1 ? 12 : 0,
            ),
            child: ProductCard(
              productId: productId,
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
              cartQuantity: cartQuantity,
              canAddToCart: canAddToCart,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(productId: productId),
                  ),
                );
              },
              onFavoriteTap: () {
                final nextValue = !(product['isFavorite'] == true);
                appState.setFavorite(productId, nextValue);
              },
              onQuantityChanged: (quantity) {
                if (quantity <= 0) {
                  appState.removeFromCart(productId);
                } else if (cartQuantity == 0) {
                  // Item not in cart yet - add it
                  final added = appState.addToCart(
                    productId,
                    quantity: quantity,
                  );
                  if (added) {
                    _showAddToCartSnackbar();
                  }
                } else {
                  // Item already in cart - update quantity
                  appState.updateCartQuantity(productId, quantity);
                }
              },
            ),
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

class _VegModeToggle extends StatelessWidget {
  final CampusAppState appState;

  const _VegModeToggle({required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isVegMode = appState.vegMode;
        return GestureDetector(
          onTap: () => appState.toggleVegMode(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isVegMode
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVegMode ? Colors.green : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 16,
                  color: isVegMode ? Colors.green : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Veg',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isVegMode ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
