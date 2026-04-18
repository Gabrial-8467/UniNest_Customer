import 'package:flutter/material.dart';

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
  String searchQuery = '';

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
      final description = (product['description'] ?? '')
          .toString()
          .toLowerCase();
      final query = searchQuery.trim().toLowerCase();

      if (query.isNotEmpty &&
          !name.contains(query) &&
          !description.contains(query)) {
        return false;
      }

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
          body: Column(
            children: [
              _buildCanteenHeader(canteen),
              _buildSearch(),
              _buildCategories(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ProductGrid(
                        products: filtered,
                        onProductTap: (productId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(productId: productId),
                            ),
                          );
                        },
                        onFavoriteToggle: (productId, isFavorite) {
                          appState.setFavorite(productId, isFavorite);
                        },
                        onAddToCart: (productId) {
                          appState.addToCart(productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              backgroundColor: Color(0xFFFF6B6B),
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

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search in this canteen...',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              'Try changing your search or category filter.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
