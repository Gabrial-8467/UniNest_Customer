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
  final GlobalKey _searchFieldKey = GlobalKey();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _allCanteens = [];
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  String _errorMessage = '';
  bool _hasSearched = false;
  OverlayEntry? _suggestionsOverlay;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
    _fetchAllDataForSuggestions();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _suggestionsOverlay?.remove();
    super.dispose();
  }

  Future<void> _fetchAllDataForSuggestions() async {
    try {
      setState(() => _isLoadingSuggestions = true);
      final result = await ApiService.search(query: '');
      if (result['success'] == true && mounted) {
        final dynamic data = result['data'];
        List<dynamic> products = [];
        List<dynamic> canteens = [];

        if (data is List) {
          products = data;
        } else if (data is Map<String, dynamic>) {
          products = data['products'] ?? [];
          canteens = data['vendors'] ?? [];
        }

        setState(() {
          _allProducts = products.cast<Map<String, dynamic>>();
          _allCanteens = canteens.cast<Map<String, dynamic>>();
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching suggestions data: $e');
      setState(() => _isLoadingSuggestions = false);
    }
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

  void _showSuggestions(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty || _isLoadingSuggestions) {
      _suggestionsOverlay?.remove();
      _suggestionsOverlay = null;
      return;
    }

    final filteredProducts = _allProducts
        .where((product) {
          final name = (product['name'] ?? '').toString().toLowerCase();
          return name.contains(trimmedQuery);
        })
        .take(5)
        .toList();

    final filteredCanteens = _allCanteens
        .where((canteen) {
          final name = (canteen['name'] ?? canteen['businessName'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(trimmedQuery);
        })
        .take(3)
        .toList();

    if (filteredProducts.isEmpty && filteredCanteens.isEmpty) {
      _suggestionsOverlay?.remove();
      _suggestionsOverlay = null;
      return;
    }

    _suggestionsOverlay?.remove();

    _suggestionsOverlay = OverlayEntry(
      builder: (context) {
        final renderBox =
            _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
        final position = renderBox?.localToGlobal(Offset.zero);
        final size = renderBox?.size;

        return Positioned(
          left: 0,
          top: (position?.dy ?? 0) + (size?.height ?? 48),
          width: MediaQuery.of(context).size.width,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filteredCanteens.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Canteens',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...filteredCanteens.map((canteen) {
                        final name =
                            (canteen['name'] ??
                                    canteen['businessName'] ??
                                    'Canteen')
                                .toString();
                        final rating = (canteen['rating']?['average'] ?? 0.0)
                            .toDouble();
                        final isOpen = _isVendorOpen(canteen);
                        return InkWell(
                          onTap: () {
                            _suggestionsOverlay?.remove();
                            _suggestionsOverlay = null;
                            _searchController.text = name;
                            _searchFocusNode.requestFocus();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (rating > 0) ...[
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (isOpen
                                                          ? AppColors.success
                                                          : AppColors.error)
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isOpen ? 'Open' : 'Closed',
                                              style: TextStyle(
                                                color: isOpen
                                                    ? AppColors.success
                                                    : AppColors.error,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                      }),
                    ],
                    if (filteredProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...filteredProducts.map((product) {
                        final name = (product['name'] ?? 'Product').toString();
                        final price =
                            (product['price'] as num?)?.toDouble() ?? 0;
                        final images = product['images'];
                        String imageUrl = '';
                        if (images is List && images.isNotEmpty) {
                          final firstImage = images[0];
                          if (firstImage is Map) {
                            imageUrl = (firstImage['url'] ?? '').toString();
                          } else {
                            imageUrl = firstImage.toString();
                          }
                        } else {
                          imageUrl =
                              (product['imageUrl'] ?? product['image'] ?? '')
                                  .toString();
                        }
                        String canteenName = 'Unknown';
                        final vendor = product['vendor'];
                        if (vendor is Map) {
                          canteenName =
                              (vendor['businessName'] ??
                                      vendor['name'] ??
                                      'Unknown')
                                  .toString();
                        } else {
                          canteenName =
                              (product['canteenName'] ??
                                      product['vendorName'] ??
                                      'Unknown')
                                  .toString();
                        }
                        return InkWell(
                          onTap: () {
                            _suggestionsOverlay?.remove();
                            _suggestionsOverlay = null;
                            _searchController.text = name;
                            _searchFocusNode.requestFocus();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.restaurant,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.restaurant,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        canteenName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_suggestionsOverlay!);
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
          key: _searchFieldKey,
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: _showSuggestions,
          onSubmitted: (value) {
            _suggestionsOverlay?.remove();
            _suggestionsOverlay = null;
            _performSearch(value);
          },
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
                      _suggestionsOverlay?.remove();
                      _suggestionsOverlay = null;
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
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
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

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _searchResults.length - 1 ? 12 : 0,
                  ),
                  child: ProductCard(
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
