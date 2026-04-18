import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/product_card.dart';
import 'product_details.dart';

class WishlistScreen extends StatelessWidget {
  final bool showBackButton;

  const WishlistScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final favorites = appState.favoriteProducts;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Wishlist',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: showBackButton
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2D3436),
                    ),
                  )
                : null,
            automaticallyImplyLeading: showBackButton,
          ),
          body: favorites.isEmpty
              ? _buildEmptyState(context)
              : ProductGrid(
                  products: favorites,
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
                    appState.toggleFavorite(productId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        backgroundColor: isFavorite
                            ? Color(0xFF4CAF50)
                            : Color(0xFFFF6B6B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onAddToCart: (productId) {
                    final added = appState.addToCart(productId);
                    if (added) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                          backgroundColor: Color(0xFFFF6B6B),
                        ),
                      );
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 52,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
