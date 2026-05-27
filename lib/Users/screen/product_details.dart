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
  final PageController _imageController = PageController();
  int _currentImagePage = 0;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

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

        final imageUrls = _extractImageUrls(product);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(
                context: context,
                appState: appState,
                product: product,
                imageUrls: imageUrls,
                discountPercent: discountPercent,
                isNew: isNew,
                canteenName: canteenName,
                isCanteenOpen: isCanteenOpen,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildProductInfoCard(
                        product: product,
                        rating: rating,
                        reviewCount: reviewCount,
                        discountedPrice: discountedPrice,
                        originalPrice: originalPrice,
                        hasDiscount: hasDiscount,
                        savings: savings,
                      ),
                      const SizedBox(height: 28),
                      _buildHighlights(
                        rating: rating,
                        reviewCount: reviewCount,
                      ),
                      const SizedBox(height: 28),
                      _buildCanteenInfo(
                        canteenName: canteenName,
                        canteenLocation: canteenLocation,
                        isCanteenOpen: isCanteenOpen,
                      ),
                      const SizedBox(height: 28),
                      _buildDescription(description),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
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

  List<String> _extractImageUrls(Map<String, dynamic> product) {
    final List<String> urls = [];
    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      for (final img in images) {
        final url = img is Map ? img['url']?.toString() : img.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      }
    }
    if (urls.isEmpty) {
      final mainUrl = product['imageUrl'] is Map
          ? product['imageUrl']['url']?.toString() ?? ''
          : (product['imageUrl'] ?? '').toString();
      if (mainUrl.isNotEmpty) urls.add(mainUrl);
    }
    return urls;
  }

  Widget _buildSliverAppBar({
    required BuildContext context,
    required CampusAppState appState,
    required Map<String, dynamic> product,
    required List<String> imageUrls,
    required int discountPercent,
    required bool isNew,
    required String canteenName,
    required bool isCanteenOpen,
  }) {
    final isFavorite = product['isFavorite'] == true;
    final productName = (product['name'] ?? 'Product').toString();

    return SliverAppBar(
      pinned: true,
      expandedHeight: 420,
      backgroundColor: AppColors.surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: GestureDetector(
              onTap: () {
                appState.toggleFavorite(product['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? 'Removed from wishlist'
                          : 'Added to wishlist',
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.primary : AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CartScreen(showBackButton: true),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Badge(
                  isLabelVisible: appState.cartItemCount > 0,
                  label: Text('${appState.cartItemCount}'),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageCarousel(imageUrls),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              top: kToolbarHeight + 16,
              left: 16,
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
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        color: AppColors.textLight,
        child: const Center(
          child: Icon(Icons.restaurant_menu, size: 64, color: Colors.white),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _imageController,
          itemCount: imageUrls.length,
          onPageChanged: (index) => setState(() => _currentImagePage = index),
          itemBuilder: (context, index) {
            return Container(
              color: const Color(0xFFF5F5F5),
              alignment: Alignment.center,
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.textLight,
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            );
          },
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                final isActive = index == _currentImagePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: isActive ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBadge({
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
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

  Widget _buildProductInfoCard({
    required Map<String, dynamic> product,
    required double rating,
    required int reviewCount,
    required double discountedPrice,
    required double originalPrice,
    required bool hasDiscount,
    required double savings,
  }) {
    final productName = (product['name'] ?? 'Product').toString();
    final isVeg = product['foodType']?.toString() == 'veg';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, const Color(0xFFFFF8F8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            productName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Rating + reviews + veg tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$reviewCount reviews',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isVeg)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Veg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                        Text(
                          discountedPrice.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '.${(discountedPrice % 1 * 100).toInt().toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '₹${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 12,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${((savings / originalPrice) * 100).toStringAsFixed(0)}% OFF',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${savings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Limited time offer — save ₹${savings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlights({required double rating, required int reviewCount}) {
    return Row(
      children: [
        Expanded(
          child: _buildHighlightTile(
            icon: Icons.timer_outlined,
            label: 'Prep Time',
            value: '10-15 min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHighlightTile(
            icon: Icons.thumb_up_alt_outlined,
            label: 'Popularity',
            value: reviewCount >= 150 ? 'Top Pick' : 'Well Rated',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHighlightTile(
            icon: Icons.star_outline_rounded,
            label: 'Average',
            value: '${rating.toStringAsFixed(1)}/5',
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.background, width: 1.5),
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
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.background, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canteenName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (canteenLocation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    canteenLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.background, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: Text(
                  description,
                  maxLines: _showFullDescription ? null : 3,
                  overflow: _showFullDescription
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
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
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      _showFullDescription ? 'Show less' : 'Read more',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    CampusAppState appState,
    Map<String, dynamic> product,
    double discountedPrice,
  ) {
    final productId = product['id']?.toString() ?? '';
    final cartQuantity = appState.getCartQuantity(productId);
    final isInCart = cartQuantity > 0;
    final canOrder = product['availability'] == 'in_stock';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isInCart
            ? _buildInCartControls(
                appState: appState,
                productId: productId,
                cartQuantity: cartQuantity,
                discountedPrice: discountedPrice,
              )
            : _buildAddToCartButton(
                appState: appState,
                product: product,
                discountedPrice: discountedPrice,
                canOrder: canOrder,
              ),
      ),
    );
  }

  Widget _buildAddToCartButton({
    required CampusAppState appState,
    required Map<String, dynamic> product,
    required double discountedPrice,
    required bool canOrder,
  }) {
    final productId = product['id']?.toString() ?? '';
    final totalPrice = discountedPrice * quantity;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    final useCompactLayout = screenWidth < 360 || textScale > 1.1;

    final button = SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canOrder
            ? () {
                final added = appState.addToCart(productId, quantity: quantity);
                if (added) {
                  _showAddToCartSnackbar(
                    productName: (product['name'] ?? 'Item').toString(),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canOrder ? AppColors.primary : AppColors.textLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: canOrder
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Out of Stock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );

    if (useCompactLayout) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [button],
      );
    }
    return Row(children: [Expanded(child: button)]);
  }

  Widget _buildInCartControls({
    required CampusAppState appState,
    required String productId,
    required int cartQuantity,
    required double discountedPrice,
  }) {
    final totalPrice = discountedPrice * cartQuantity;

    return Row(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: cartQuantity > 1
                    ? () => appState.updateCartQuantity(
                        productId,
                        cartQuantity - 1,
                      )
                    : () => appState.removeFromCart(productId),
                icon: Icon(
                  cartQuantity > 1
                      ? Icons.remove_rounded
                      : Icons.delete_outline,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '$cartQuantity',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    appState.updateCartQuantity(productId, cartQuantity + 1),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '₹${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddToCartSnackbar({required String productName}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$quantity x $productName added to cart'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
