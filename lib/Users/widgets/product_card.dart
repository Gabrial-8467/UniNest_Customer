import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/utils.dart';

class ProductCard extends StatefulWidget {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final String canteenName;
  final String foodType;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final Function(int)? onQuantityChanged;
  final String? discount;
  final bool isNew;
  final String? availability;
  final bool? madeToOrder;
  final int cartQuantity;
  final bool canAddToCart;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.canteenName,
    this.foodType = 'veg',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
    this.onQuantityChanged,
    this.discount,
    this.isNew = false,
    this.availability,
    this.madeToOrder,
    this.cartQuantity = 0,
    this.canAddToCart = true,
  });

  bool get canOrder {
    // Check if can add based on canteen restriction
    if (!canAddToCart) return false;
    // Made-to-order items are always available
    if (madeToOrder == true) return true;
    // Pre-packaged items need to be in stock
    return availability == 'in_stock';
  }

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.canAddToCart;
    final hasDiscount = widget.discount != null;
    final discountedPrice = hasDiscount
        ? widget.price * (1 - int.parse(widget.discount!) / 100)
        : widget.price;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Card(
        elevation: 0,
        color: isDisabled ? Colors.grey[200] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: Image with badges
                _buildImageSection(isDisabled),
                const SizedBox(width: 10),
                // Middle: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(isDisabled),
                      const SizedBox(height: 6),
                      _buildCanteenInfo(isDisabled),
                      const SizedBox(height: 8),
                      _buildPriceAndRatingRow(
                        isDisabled,
                        discountedPrice,
                        hasDiscount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right: Action button
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDisabled) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.background, AppColors.textLight],
                ),
              ),
              child: ColorFiltered(
                colorFilter: isDisabled
                    ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.srcOver,
                      ),
                child: Image.network(
                  widget.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  headers: const {'Cache-Control': 'max-age=3600'},
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textLight,
                            AppColors.textSecondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 32,
                        color: Colors.white,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.discount != null) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${widget.discount}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: widget.onFavoriteTap,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 14,
                  color: widget.isFavorite
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

  Widget _buildHeader(bool isDisabled) {
    return Text(
      widget.name,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: isDisabled ? Colors.grey[600] : const Color(0xFF2D3436),
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCanteenInfo(bool isDisabled) {
    final isVeg = widget.foodType == 'veg';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isVeg ? Colors.green : Colors.red,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Icon(
              Icons.circle,
              size: 6,
              color: isVeg ? Colors.green : Colors.red,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey[300]
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.canteenName,
            style: TextStyle(
              fontSize: 10,
              color: isDisabled ? Colors.grey[600] : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndRatingRow(
    bool isDisabled,
    double discountedPrice,
    bool hasDiscount,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '\u20B9${CurrencyFormatter.formatRupeeRaw(discountedPrice)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDisabled
                      ? Colors.grey[600]
                      : const Color(0xFFFF6B6B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  CurrencyFormatter.formatRupee(widget.price),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDisabled
                        ? Colors.grey[500]
                        : AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 13,
              color: isDisabled ? Colors.grey[500] : AppColors.accent,
            ),
            const SizedBox(width: 2),
            Text(
              widget.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey[600] : AppColors.textPrimary,
              ),
            ),
            if (widget.reviewCount > 0) ...[
              const SizedBox(width: 2),
              Text(
                '(${widget.reviewCount})',
                style: TextStyle(
                  fontSize: 10,
                  color: isDisabled
                      ? Colors.grey[500]
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // If item is in cart, show quantity selector
    if (widget.cartQuantity > 0) {
      return Container(
        height: 38,
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () =>
                  widget.onQuantityChanged?.call(widget.cartQuantity - 1),
              child: Container(
                width: 30,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(7),
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              '${widget.cartQuantity}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            InkWell(
              onTap: () =>
                  widget.onQuantityChanged?.call(widget.cartQuantity + 1),
              child: Container(
                width: 30,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(7),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Not in cart - show Add button
    return SizedBox(
      width: 90,
      height: 38,
      child: ElevatedButton(
        onPressed: widget.canOrder
            ? () => widget.onQuantityChanged?.call(1)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.canOrder
              ? AppColors.primary
              : AppColors.textLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Add',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// Grid view widget for displaying multiple product cards
class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(String)? onProductTap;
  final Function(String, bool)? onFavoriteToggle;
  final Function(String, int)? onQuantityChanged;
  final int Function(String)? getCartQuantity;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool Function(String)? canAddToCart;

  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onQuantityChanged,
    this.getCartQuantity,
    this.crossAxisCount = 1,
    this.childAspectRatio = 3.2,
    this.spacing = 16,
    this.shrinkWrap = false,
    this.physics,
    this.canAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productId = product['id'] ?? '';
        final cartQty = getCartQuantity?.call(productId) ?? 0;
        final canAdd = canAddToCart?.call(productId) ?? true;
        return ProductCard(
          productId: productId,
          name: product['name'] ?? 'Product Name',
          price: (product['price'] ?? 0.0).toDouble(),
          imageUrl: product['imageUrl'] is Map
              ? product['imageUrl']['url'] ?? ''
              : (product['imageUrl'] ?? '').toString(),
          canteenName: product['canteenName'] ?? 'Unknown',
          foodType: product['foodType']?.toString() ?? 'veg',
          rating: (product['rating'] ?? 0.0).toDouble(),
          reviewCount: product['reviewCount'] ?? 0,
          isFavorite: product['isFavorite'] ?? false,
          discount: product['discount'],
          isNew: product['isNew'] ?? false,
          availability: product['availability']?.toString(),
          madeToOrder: product['madeToOrder'] ?? false,
          cartQuantity: cartQty,
          canAddToCart: canAdd,
          onTap: () => onProductTap?.call(productId),
          onFavoriteTap: () => onFavoriteToggle?.call(
            productId,
            !(product['isFavorite'] ?? false),
          ),
          onQuantityChanged: (qty) => onQuantityChanged?.call(productId, qty),
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
  final Function(String, int)? onQuantityChanged;
  final int Function(String)? getCartQuantity;
  final bool Function(String)? canAddToCart;

  const ProductList({
    super.key,
    required this.products,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onQuantityChanged,
    this.getCartQuantity,
    this.canAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        final productId = product['id'] ?? '';
        final cartQty = getCartQuantity?.call(productId) ?? 0;
        final canAdd = canAddToCart?.call(productId) ?? true;
        return ProductCard(
          productId: productId,
          name: product['name'] ?? 'Product Name',
          price: (product['price'] ?? 0.0).toDouble(),
          imageUrl: product['imageUrl'] is Map
              ? product['imageUrl']['url'] ?? ''
              : (product['imageUrl'] ?? '').toString(),
          canteenName: product['canteenName'] ?? 'Unknown',
          foodType: product['foodType']?.toString() ?? 'veg',
          rating: (product['rating'] ?? 0.0).toDouble(),
          reviewCount: product['reviewCount'] ?? 0,
          isFavorite: product['isFavorite'] ?? false,
          discount: product['discount'],
          isNew: product['isNew'] ?? false,
          availability: product['availability']?.toString(),
          madeToOrder: product['madeToOrder'] ?? false,
          cartQuantity: cartQty,
          canAddToCart: canAdd,
          onTap: () => onProductTap?.call(productId),
          onFavoriteTap: () => onFavoriteToggle?.call(
            productId,
            !(product['isFavorite'] ?? false),
          ),
          onQuantityChanged: (qty) => onQuantityChanged?.call(productId, qty),
        );
      },
    );
  }
}
