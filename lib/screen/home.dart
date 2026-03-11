import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/canteen_card.dart';
import '../widgets/product_card.dart';
import 'all_canteens.dart';
import 'canteen_menu.dart';
import 'product_details.dart';

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

  final List<_CategoryOption> categories = const [
    _CategoryOption(label: 'All', icon: Icons.grid_view_rounded),
    _CategoryOption(label: 'Burgers', icon: Icons.lunch_dining_rounded),
    _CategoryOption(label: 'Pizza', icon: Icons.local_pizza_rounded),
    _CategoryOption(label: 'Drinks', icon: Icons.local_cafe_rounded),
    _CategoryOption(label: 'Desserts', icon: Icons.icecream_rounded),
    _CategoryOption(label: 'Snacks', icon: Icons.fastfood_rounded),
  ];

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

      return _matchesCategory(name, description);
    }).toList();
  }

  bool _matchesCategory(String name, String description) {
    if (selectedCategory == 'All') {
      return true;
    }

    final text = '$name $description';

    switch (selectedCategory) {
      case 'Burgers':
        return text.contains('burger');
      case 'Pizza':
        return text.contains('pizza');
      case 'Drinks':
        return text.contains('shake') ||
            text.contains('coffee') ||
            text.contains('drink');
      case 'Desserts':
        return text.contains('ice cream') ||
            text.contains('sundae') ||
            text.contains('dessert');
      case 'Snacks':
        return text.contains('fries') ||
            text.contains('wings') ||
            text.contains('sandwich') ||
            text.contains('snack');
      default:
        return true;
    }
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

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(appState),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildCategories(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildCanteenSection(canteens)),
                    if (products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyProductsState(),
                      )
                    else
                      _buildProductsSliver(appState, products),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CampusAppState appState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Campus Eats',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products or canteens...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
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
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.label == selectedCategory;

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      selectedCategory = category.label;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B6B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3436),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2D3436),
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
  }

  Widget _buildCanteenSection(List<Map<String, dynamic>> canteens) {
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
                    color: Color(0xFF2D3436),
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
                      color: Color(0xFF636E72),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'No canteens found for this search.',
                    style: TextStyle(color: Colors.grey[600]),
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
                        onTap: () {
                          if (isSelected) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CanteenMenuScreen(canteenId: canteenId),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            selectedCanteenId = canteenId;
                          });
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
            imageUrl: (product['imageUrl'] ?? '').toString(),
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

  Widget _buildEmptyProductsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No matching items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another product, canteen, or category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
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

class _CategoryOption {
  final String label;
  final IconData icon;

  const _CategoryOption({required this.label, required this.icon});
}
