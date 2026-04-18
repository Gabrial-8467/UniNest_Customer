import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/utils.dart';

class ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final String canteenName;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final String? discount;
  final bool isNew;
  final String? availability;
  final bool? madeToOrder;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.canteenName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
    this.discount,
    this.isNew = false,
    this.availability,
    this.madeToOrder,
  });

  bool get canOrder {
    // Made-to-order items are always available
    if (madeToOrder == true) return true;
    // Pre-packaged items need to be in stock
    return availability == 'in_stock';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 3),
                      _buildCanteenInfo(),
                      const SizedBox(height: 5),
                      _buildPriceAndRatingRow(),
                      const SizedBox(height: 6),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return AspectRatio(
      // Slightly wider ratio leaves enough height for card content in small grids.
      aspectRatio: 16 / 11,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.textLight, AppColors.textSecondary],
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.white,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.background, AppColors.textLight],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (discount != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: onFavoriteTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isFavorite
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCanteenInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        canteenName,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFFF6B6B),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriceAndRatingRow() {
    final hasDiscount = discount != null;
    final originalPrice = price;
    final discountedPrice = hasDiscount
        ? price * (1 - int.parse(discount!) / 100)
        : price;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Text(
                      '\u20B9',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      CurrencyFormatter.formatRupeeRaw(discountedPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDiscount)
                Text(
                  CurrencyFormatter.formatRupee(originalPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: AppColors.accent),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (reviewCount > 0) ...[
              const SizedBox(width: 2),
              Text(
                '($reviewCount)',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: FittedBox(
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: canOrder ? onAddToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canOrder
                    ? AppColors.primary
                    : AppColors.textLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                disabledBackgroundColor: AppColors.textLight,
              ),
              child: canOrder
                  ? const Icon(Icons.add_shopping_cart, size: 14)
                  : const FittedBox(
                      child: Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// Grid view widget for displaying multiple product cards
class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(String)? onProductTap;
  final Function(String, bool)? onFavoriteToggle;
  final Function(String)? onAddToCart;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.62,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          productId: product['id'] ?? '',
          name: product['name'] ?? 'Product Name',
          price: (product['price'] ?? 0.0).toDouble(),
          imageUrl: product['imageUrl'] is Map
              ? product['imageUrl']['url'] ?? ''
              : (product['imageUrl'] ?? '').toString(),
          canteenName: product['canteenName'] ?? 'Unknown',
          rating: (product['rating'] ?? 0.0).toDouble(),
          reviewCount: product['reviewCount'] ?? 0,
          isFavorite: product['isFavorite'] ?? false,
          discount: product['discount'],
          isNew: product['isNew'] ?? false,
          availability: product['availability']?.toString(),
          madeToOrder: product['madeToOrder'] ?? false,
          onTap: () => onProductTap?.call(product['id']),
          onFavoriteTap: () => onFavoriteToggle?.call(
            product['id'],
            !(product['isFavorite'] ?? false),
          ),
          onAddToCart: () => onAddToCart?.call(product['id']),
        );
      },
    );
  }
}

// List view widget for displaying products
class ProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(String)? onProductTap;
  final Function(String, bool)? onFavoriteToggle;
  final Function(String)? onAddToCart;

  const ProductList({
    super.key,
    required this.products,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          productId: product['id'] ?? '',
          name: product['name'] ?? 'Product Name',
          price: (product['price'] ?? 0.0).toDouble(),
          imageUrl: product['imageUrl'] is Map
              ? product['imageUrl']['url'] ?? ''
              : (product['imageUrl'] ?? '').toString(),
          canteenName: product['canteenName'] ?? 'Unknown',
          rating: (product['rating'] ?? 0.0).toDouble(),
          reviewCount: product['reviewCount'] ?? 0,
          isFavorite: product['isFavorite'] ?? false,
          discount: product['discount'],
          isNew: product['isNew'] ?? false,
          availability: product['availability']?.toString(),
          madeToOrder: product['madeToOrder'] ?? false,
          onTap: () => onProductTap?.call(product['id']),
          onFavoriteTap: () => onFavoriteToggle?.call(
            product['id'],
            !(product['isFavorite'] ?? false),
          ),
          onAddToCart: () => onAddToCart?.call(product['id']),
        );
      },
    );
  }
}
