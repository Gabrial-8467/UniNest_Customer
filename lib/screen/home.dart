import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/product_card.dart';
import 'canteen_menu.dart';
import 'cart.dart';
import 'product_details.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, this.onOpenCart, this.onOpenProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String selectedCanteenChip = 'All';
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
        final products = _filteredProducts(appState.products.toList());

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(appState),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildCanteenSelector(appState),
              _buildCategories(),
              Expanded(
                child: ProductGrid(
                  products: products,
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
                    _showAddToCartSnackbar();
                  },
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
      actions: [
        IconButton(
          onPressed:
              widget.onOpenCart ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CartScreen(showBackButton: true),
                  ),
                );
              },
          icon: Badge(
            isLabelVisible: appState.cartItemCount > 0,
            label: Text('${appState.cartItemCount}'),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        IconButton(
          onPressed:
              widget.onOpenProfile ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfileScreen(showBackButton: true),
                  ),
                );
              },
          icon: const Icon(Icons.person_outline, color: Color(0xFF2D3436)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for food...',
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

  Widget _buildCanteenSelector(CampusAppState appState) {
    final canteens = appState.canteens;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: canteens.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCanteenChip(
              label: 'All Products',
              isSelected: selectedCanteenChip == 'All',
              isOpen: true,
              onTap: () {
                setState(() {
                  selectedCanteenChip = 'All';
                });
              },
            );
          }

          final canteen = canteens[index - 1];
          final canteenId = canteen['id'] as String;
          final isSelected = selectedCanteenChip == canteenId;

          return _buildCanteenChip(
            label: canteen['name'],
            isSelected: isSelected,
            isOpen: canteen['isOpen'] == true,
            onTap: () {
              setState(() {
                selectedCanteenChip = canteenId;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CanteenMenuScreen(canteenId: canteenId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCanteenChip({
    required String label,
    required bool isSelected,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 90),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF2D3436),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (label != 'All Products') ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 60),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
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
