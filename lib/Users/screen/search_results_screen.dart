import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'canteen_menu.dart';
import 'product_details.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  double _extractRating(Map<String, dynamic> product) {
    final ratingData = product['rating'];
    if (ratingData is Map<String, dynamic>) {
      final average = ratingData['average'];
      if (average is num) return average.toDouble();
    } else if (ratingData is num) {
      return ratingData.toDouble();
    }
    // Also check vendor rating
    final vendor = product['vendor'];
    if (vendor is Map<String, dynamic>) {
      final vendorRating = vendor['rating'];
      if (vendorRating is num) return vendorRating.toDouble();
      if (vendorRating is Map<String, dynamic>) {
        final average = vendorRating['average'];
        if (average is num) return average.toDouble();
      }
    }
    return 0.0;
  }

  bool _isVendorOpen(Map<dynamic, dynamic> vendor) {
    final explicitOpen = _readBoolField(vendor, const [
      'isOpen',
      'is_open',
      'open',
      'isCurrentlyOpen',
      'currentlyOpen',
      'isAvailable',
      'available',
      'isAcceptingOrders',
      'acceptingOrders',
      'canteenOpen',
    ]);
    if (explicitOpen != null) return explicitOpen;

    final businessDetails = vendor['businessDetails'];
    if (businessDetails is Map) {
      final businessOpen = _readBoolField(businessDetails, const [
        'isOpen',
        'isAvailable',
        'isAcceptingOrders',
        'acceptingOrders',
        'canteenOpen',
      ]);
      if (businessOpen != null) return businessOpen;
    }

    final explicitClosed = _readBoolField(vendor, const [
      'isClosed',
      'closed',
      'isCurrentlyClosed',
      'currentlyClosed',
    ]);
    if (explicitClosed != null) return !explicitClosed;

    final status = vendor['status']?.toString().trim().toLowerCase();
    if (status != null && status.isNotEmpty) {
      if (const {
        'closed',
        'inactive',
        'disabled',
        'offline',
        'unavailable',
        'temporarily_closed',
        'temporarily closed',
      }.contains(status)) {
        return false;
      }
      if (const {'open', 'online', 'available'}.contains(status)) return true;
    }

    return true;
  }

  bool? _readBoolField(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (const {
          'true',
          '1',
          'yes',
          'open',
          'available',
          'online',
        }.contains(normalized)) {
          return true;
        }
        if (const {
          'false',
          '0',
          'no',
          'closed',
          'unavailable',
          'offline',
        }.contains(normalized)) {
          return false;
        }
      }
    }
    return null;
  }

  bool _isProductFromOpenVendor(Map<String, dynamic> product) {
    final vendor = product['vendor'];
    if (vendor is Map) {
      return _isVendorOpen(vendor);
    }

    final isOpen = product['isCanteenOpen'] ?? product['vendorIsOpen'];
    if (isOpen is bool) return isOpen;

    final status = (product['vendorStatus'] ?? product['status'])
        ?.toString()
        .toLowerCase();
    if (status != null && status.isNotEmpty) {
      return status == 'active' || status == 'open';
    }

    return true;
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
    });

    try {
      final trimmedQuery = query.trim();

      debugPrint('🔍 Search query: "$trimmedQuery"');

      // Use q parameter only - backend handles smart detection
      final result = await ApiService.search(query: trimmedQuery);

      if (!mounted) return;

      if (result['success'] == true) {
        // Handle different API response formats
        final dynamic data = result['data'];
        List<dynamic> products = [];
        List<dynamic> vendors = [];

        if (data is List) {
          products = data;
        } else if (data is Map<String, dynamic>) {
          // API returns {products: [...], vendors: [...]}
          products = data['products'] ?? [];
          vendors = data['vendors'] ?? [];
        }

        // Frontend workaround: Extract vendors from products if not provided by API
        if (vendors.isEmpty && products.isNotEmpty) {
          final vendorMap = <String, Map<String, dynamic>>{};
          for (final product in products) {
            if (product is Map<String, dynamic>) {
              final vendorData = product['vendor'];
              if (vendorData is Map<String, dynamic>) {
                final vendorId =
                    vendorData['_id']?.toString() ??
                    vendorData['id']?.toString();
                if (vendorId != null && !vendorMap.containsKey(vendorId)) {
                  vendorMap[vendorId] = vendorData;
                }
              }
            }
          }
          vendors = vendorMap.values.toList();
        }

        setState(() {
          _searchResults = products
              .cast<Map<String, dynamic>>()
              .where(_isProductFromOpenVendor)
              .toList();
          _vendors = vendors.cast<Map<String, dynamic>>();

          // Sort products by rating (highest first)
          _searchResults.sort((a, b) {
            final ratingA = _extractRating(a);
            final ratingB = _extractRating(b);
            return ratingB.compareTo(ratingA);
          });

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to search products';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 100,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: 'Search food, canteen...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                        _errorMessage = '';
                      });
                      _searchFocusNode.requestFocus();
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.search, color: AppColors.primary),
              onPressed: () => _performSearch(_searchController.text),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for food, canteens...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show vendors/canteens if any
          if (_vendors.isNotEmpty) ...[
            Text(
              '${_vendors.length} canteen(s) found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vendors.length,
                itemBuilder: (context, index) {
                  final vendor = _vendors[index];
                  final vendorId = (vendor['_id'] ?? vendor['id'] ?? '')
                      .toString();
                  final vendorName =
                      (vendor['businessName'] ?? vendor['name'] ?? 'Unknown')
                          .toString();
                  final rating = (vendor['rating']?['average'] ?? 0.0)
                      .toDouble();
                  final isOpen = _isVendorOpen(vendor);

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CanteenMenuScreen(canteenId: vendorId),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.textLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vendorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isOpen
                                                ? AppColors.success
                                                : AppColors.error)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isOpen ? 'Open' : 'Closed',
                                    style: TextStyle(
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '${_searchResults.length} product(s) found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];

                // Extract product ID - API returns _id
                final productId = (product['_id'] ?? product['id'] ?? '')
                    .toString();

                // Extract image URL - API returns images array
                String imageUrl = '';
                final images = product['images'];
                if (images is List && images.isNotEmpty) {
                  final firstImage = images[0];
                  if (firstImage is Map) {
                    imageUrl = (firstImage['url'] ?? '').toString();
                  } else {
                    imageUrl = firstImage.toString();
                  }
                } else if (product['imageUrl'] is Map) {
                  imageUrl = product['imageUrl']['url'] ?? '';
                } else {
                  imageUrl = (product['imageUrl'] ?? product['image'] ?? '')
                      .toString();
                }

                // Extract vendor/canteen name - API returns nested vendor object
                String canteenName = 'Unknown';
                final vendor = product['vendor'];
                if (vendor is Map) {
                  canteenName =
                      (vendor['businessName'] ?? vendor['name'] ?? 'Unknown')
                          .toString();
                } else {
                  canteenName =
                      (product['canteenName'] ??
                              product['vendorName'] ??
                              'Unknown')
                          .toString();
                }

                // Extract rating - API returns rating in vendor object or at product level
                double rating = 0.0;
                final dynamic ratingData = product['rating'];
                if (ratingData is num) {
                  rating = ratingData.toDouble();
                } else if (ratingData is Map<String, dynamic>) {
                  final avg = ratingData['average'];
                  if (avg is num) rating = avg.toDouble();
                } else if (vendor is Map && vendor['rating'] is num) {
                  rating = vendor['rating'].toDouble();
                }

                // Extract review count
                int reviewCount = 0;
                final dynamic reviewCountData = product['reviewCount'];
                if (reviewCountData is num) {
                  reviewCount = reviewCountData.toInt();
                } else if (ratingData is Map<String, dynamic>) {
                  final count = ratingData['count'];
                  if (count is num) reviewCount = count.toInt();
                }

                return ProductCard(
                  productId: productId,
                  name: (product['name'] ?? 'Product Name').toString(),
                  price: (product['price'] as num?)?.toDouble() ?? 0,
                  imageUrl: imageUrl,
                  canteenName: canteenName,
                  rating: rating,
                  reviewCount: reviewCount,
                  isFavorite: product['isFavorite'] == true,
                  discount: product['discount']?.toString(),
                  isNew: product['isNew'] == true,
                  availability: product['availability']?.toString(),
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
                    // Handle favorite
                  },
                  onAddToCart: () {
                    // Handle add to cart
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart'),
                        duration: const Duration(seconds: 2),
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
}
