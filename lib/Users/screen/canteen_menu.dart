import 'package:flutter/material.dart';

import '../../utils/utils.dart';
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

  List<Map<String, dynamic>> _filteredProducts(
    List<Map<String, dynamic>> products,
    String category,
  ) {
    return products.where((product) {
      if (category == 'All') {
        return true;
      }

      final productCategory = (product['category'] ?? '')
          .toString()
          .toLowerCase();
      return productCategory == category.toLowerCase();
    }).toList();
  }

  List<String> _menuCategories(
    CampusAppState appState,
    List<Map<String, dynamic>> products,
  ) {
    final productCategories = products
        .map((product) => (product['category'] ?? '').toString().trim())
        .where((category) => category.isNotEmpty)
        .toSet();

    final backendCategories = appState.categories
        .where((category) => productCategories.contains(category))
        .toList();

    if (backendCategories.isNotEmpty) {
      return ['All', ...backendCategories];
    }

    return ['All', ...(productCategories.toList()..sort())];
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
        final categories = _menuCategories(appState, products);
        final activeCategory = categories.contains(selectedCategory)
            ? selectedCategory
            : 'All';
        final filtered = _filteredProducts(products, activeCategory);

        // Check if cart has items from a different canteen
        final cartCanteenId = appState.cartCanteenId;
        final isDifferentCanteen =
            cartCanteenId != null && cartCanteenId != widget.canteenId;

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
                  if (isDifferentCanteen)
                    _buildDifferentCanteenNotice(appState),
                  _buildCategories(appState, categories, activeCategory),
                  filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildProductList(appState, filtered),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(
    CampusAppState appState,
    List<Map<String, dynamic>> products,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(products.length, (index) {
          final product = products[index];

          final dynamic ratingData = product['rating'];
          double rating = 0.0;
          if (ratingData is num) {
            rating = ratingData.toDouble();
          } else if (ratingData is Map<String, dynamic>) {
            final avg = ratingData['average'];
            if (avg is num) rating = avg.toDouble();
          }

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
              foodType: product['foodType']?.toString() ?? 'veg',
              rating: rating,
              reviewCount: reviewCount,
              isFavorite: product['isFavorite'] == true,
              discount: product['discount']?.toString(),
              isNew: product['isNew'] == true,
              availability: product['availability']?.toString(),
              madeToOrder: product['madeToOrder'] == true,
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Clear cart to add items from this canteen',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else {
                  appState.updateCartQuantity(productId, quantity);
                }
              },
            ),
          );
        }),
      ),
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

  Widget _buildCategories(
    CampusAppState appState,
    List<String> categories,
    String activeCategory,
  ) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: appState.isLoadingCategories
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = activeCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B6B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        Formatters.capitalize(category),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3436),
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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

  Widget _buildDifferentCanteenNotice(CampusAppState appState) {
    final cartCanteen = appState.getCanteenById(appState.cartCanteenId ?? '');
    final cartCanteenName = cartCanteen?['name'] ?? 'another canteen';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
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
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cart has items from $cartCanteenName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You can only order from one canteen at a time. Clear your cart to add items from this canteen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              appState.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}
