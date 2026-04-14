import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/canteen_card.dart';
import '../widgets/product_card.dart';
import 'all_canteens.dart';
import 'canteen_menu.dart';
import 'product_details.dart';
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
  String searchQuery = '';

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
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return canteens;
    }

    return canteens.where((canteen) {
      final name = (canteen['name'] ?? '').toString().toLowerCase();
      final location = (canteen['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _filteredProducts(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> canteens,
  ) {
    final query = searchQuery.trim().toLowerCase();
    final matchingCanteenIds = canteens
        .where((canteen) {
          final name = (canteen['name'] ?? '').toString().toLowerCase();
          final location = (canteen['location'] ?? '').toString().toLowerCase();
          return query.isNotEmpty &&
              (name.contains(query) || location.contains(query));
        })
        .map((canteen) => (canteen['id'] ?? '').toString())
        .toSet();

    return products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final description = (product['description'] ?? '')
          .toString()
          .toLowerCase();
      final canteenName = (product['canteenName'] ?? '')
          .toString()
          .toLowerCase();
      final canteenId = (product['canteenId'] ?? '').toString();

      if (selectedCanteenId != 'All' && canteenId != selectedCanteenId) {
        return false;
      }

      final matchesSearch = query.isEmpty
          ? true
          : name.contains(query) ||
                description.contains(query) ||
                canteenName.contains(query) ||
                matchingCanteenIds.contains(canteenId);

      if (!matchesSearch) {
        return false;
      }

      return _matchesCategory(product['category']);
    }).toList();
  }

  bool _matchesCategory(String? productCategory) {
    if (selectedCategory == 'All') {
      return true;
    }

    return productCategory?.toLowerCase() == selectedCategory.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allCanteens = appState.canteens.toList();
        final filteredCanteens = _filteredCanteens(allCanteens);
        final canteens = filteredCanteens.take(4).toList();
        final products = _filteredProducts(
          appState.products.toList(),
          allCanteens,
        );

        debugPrint(
          '📊 Home: ${appState.products.length} total products, ${products.length} after filtering',
        );
        debugPrint('📊 Categories: ${appState.categories}');
        debugPrint('📊 Selected category: $selectedCategory');

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 24,
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
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products or canteens...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
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
                        builder: (context) => const AllCanteensScreen(),
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

          return ProductCard(
            productId: (product['id'] ?? '').toString(),
            name: (product['name'] ?? 'Product Name').toString(),
            price: (product['price'] as num?)?.toDouble() ?? 0,
            imageUrl: product['imageUrl'] is Map
                ? product['imageUrl']['url'] ?? ''
                : (product['imageUrl'] ?? '').toString(),
            canteenName: (product['canteenName'] ?? 'Unknown').toString(),
            rating: (product['rating'] as num?)?.toDouble() ?? 0,
            reviewCount: (product['reviewCount'] as num?)?.toInt() ?? 0,
            isFavorite: product['isFavorite'] == true,
            discount: product['discount']?.toString(),
            isNew: product['isNew'] == true,
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
              appState.addToCart((product['id'] ?? '').toString());
              _showAddToCartSnackbar();
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
