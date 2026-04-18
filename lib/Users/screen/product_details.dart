import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'cart.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final product = appState.getProductById(widget.productId);

        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Product'),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: const Center(child: Text('Product not found.')),
          );
        }

        final discountPercent =
            int.tryParse(product['discount']?.toString() ?? '') ?? 0;
        final hasDiscount = discountPercent > 0;
        final originalPrice = (product['price'] as num?)?.toDouble() ?? 0;
        final discountedPrice = hasDiscount
            ? originalPrice * (1 - discountPercent / 100)
            : originalPrice;
        final savings = originalPrice - discountedPrice;
        final rating = (product['rating'] as num?)?.toDouble() ?? 0;
        final reviewCount = (product['reviewCount'] as num?)?.toInt() ?? 0;
        final canteen = appState.getCanteenById(
          (product['canteenId'] ?? '').toString(),
        );
        final canteenName = (product['canteenName'] ?? 'Canteen').toString();
        final canteenLocation = (canteen?['location'] ?? '').toString();
        final isCanteenOpen = canteen?['isOpen'] == true;
        final description =
            (product['description'] ?? 'No description available.').toString();
        final isNew = product['isNew'] == true;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, appState, product),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildProductImage(
                product: product,
                discountPercent: discountPercent,
                isNew: isNew,
                canteenName: canteenName,
                isCanteenOpen: isCanteenOpen,
              ),
              _buildProductInfo(
                product: product,
                discountedPrice: discountedPrice,
                originalPrice: originalPrice,
                savings: savings,
                hasDiscount: hasDiscount,
                rating: rating,
                reviewCount: reviewCount,
              ),
              _buildHighlights(rating: rating, reviewCount: reviewCount),
              _buildCanteenInfo(
                canteenName: canteenName,
                canteenLocation: canteenLocation,
                isCanteenOpen: isCanteenOpen,
              ),
              _buildDescription(description),
              _buildDetails(),
              const SizedBox(height: 112),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            appState,
            product,
            discountedPrice,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CampusAppState appState,
    Map<String, dynamic> product,
  ) {
    final isFavorite = product['isFavorite'] == true;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        (product['name'] ?? 'Product').toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () {
            appState.toggleFavorite(product['id']);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFavorite ? 'Removed from wishlist' : 'Added to wishlist',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(showBackButton: true),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: appState.cartItemCount > 0,
            label: Text('${appState.cartItemCount}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage({
    required Map<String, dynamic> product,
    required int discountPercent,
    required bool isNew,
    required String canteenName,
    required bool isCanteenOpen,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            product['imageUrl'] is Map
                ? product['imageUrl']['url'] ?? ''
                : (product['imageUrl'] ?? '').toString(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.textLight,
              child: const Icon(
                Icons.restaurant_menu,
                size: 72,
                color: Colors.white,
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product['name'] ?? 'Product').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildOverlayTag(
                      icon: Icons.storefront_outlined,
                      text: canteenName,
                    ),
                    const SizedBox(width: 8),
                    _buildOverlayTag(
                      icon: isCanteenOpen
                          ? Icons.circle
                          : Icons.cancel_outlined,
                      text: isCanteenOpen ? 'Open now' : 'Closed now',
                      iconColor: isCanteenOpen
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              children: [
                if (isNew) ...[
                  _buildTopBadge(
                    text: 'NEW',
                    backgroundColor: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                ],
                if (discountPercent > 0)
                  _buildTopBadge(
                    text: '-$discountPercent%',
                    backgroundColor: AppColors.error,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge({
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOverlayTag({
    required IconData icon,
    required String text,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo({
    required Map<String, dynamic> product,
    required double discountedPrice,
    required double originalPrice,
    required double savings,
    required bool hasDiscount,
    required double rating,
    required int reviewCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (product['name'] ?? 'Product').toString(),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 21, color: Colors.amber[600]),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$reviewCount reviews',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '\u20B9${discountedPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                  height: 1,
                ),
              ),
              if (hasDiscount)
                Text(
                  '\u20B9${originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                    height: 1.2,
                  ),
                ),
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Save \u20B9${savings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights({required double rating, required int reviewCount}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildHighlightTile(
              icon: Icons.timer_outlined,
              label: 'Prep Time',
              value: '10-15 min',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildHighlightTile(
              icon: Icons.thumb_up_alt_outlined,
              label: 'Popularity',
              value: reviewCount >= 150 ? 'Top Pick' : 'Well Rated',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildHighlightTile(
              icon: Icons.star_outline_rounded,
              label: 'Average',
              value: '${rating.toStringAsFixed(1)}/5',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCanteenInfo({
    required String canteenName,
    required String canteenLocation,
    required bool isCanteenOpen,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canteenName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
                if (canteenLocation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    canteenLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isCanteenOpen ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isCanteenOpen ? 'Open' : 'Closed',
              style: TextStyle(
                color: isCanteenOpen ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String description) {
    final hasLongDescription = description.length > 130;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Text(
              description,
              maxLines: _showFullDescription ? null : 3,
              overflow: _showFullDescription
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Colors.grey[700],
              ),
            ),
          ),
          if (hasLongDescription)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: Text(
                  _showFullDescription ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _detailChip(Icons.local_fire_department, 'Freshly made'),
          _detailChip(Icons.verified_user_outlined, 'Quality checked'),
          _detailChip(Icons.favorite_outline, 'Student favorite'),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    CampusAppState appState,
    Map<String, dynamic> product,
    double discountedPrice,
  ) {
    final totalPrice = discountedPrice * quantity;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    final useCompactLayout = screenWidth < 360 || textScale > 1.1;
    final canOrder = product['availability'] == 'in_stock';

    final quantityControl = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textLight),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1
                ? () {
                    setState(() {
                      quantity--;
                    });
                  }
                : null,
            icon: Icon(
              Icons.remove_rounded,
              size: 20,
              color: quantity > 1 ? AppColors.textPrimary : AppColors.textLight,
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                quantity++;
              });
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 20,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );

    final addToCartButton = SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canOrder
            ? () {
                final added = appState.addToCart(
                  product['id'],
                  quantity: quantity,
                );
                if (added) {
                  _showAddToCartSnackbar(
                    productName: (product['name'] ?? 'Item').toString(),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canOrder
              ? const Color(0xFFFF6B6B)
              : AppColors.textLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.textLight,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: canOrder
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${totalPrice.toStringAsFixed(2)} total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Out of Stock',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.background)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: useCompactLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: quantityControl,
                  ),
                  const SizedBox(height: 12),
                  addToCartButton,
                ],
              )
            : Row(
                children: [
                  quantityControl,
                  const SizedBox(width: 12),
                  Expanded(child: addToCartButton),
                ],
              ),
      ),
    );
  }

  void _showAddToCartSnackbar({required String productName}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$quantity x $productName added to cart'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(showBackButton: true),
                ),
              );
            },
          ),
        ),
      );
  }
}
