import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../state/app_state.dart';
import 'canteen_menu.dart';

class AllCanteensScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const AllCanteensScreen({super.key, this.initialSearchQuery});

  @override
  State<AllCanteensScreen> createState() => _AllCanteensScreenState();
}

class _AllCanteensScreenState extends State<AllCanteensScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery ?? '';
  }

  List<Map<String, dynamic>> _filteredCanteens(
    List<Map<String, dynamic>> canteens,
  ) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      // Sort by rating when no search query
      final sorted = canteens.toList()
        ..sort((a, b) {
          final ratingA = _extractRating(a);
          final ratingB = _extractRating(b);
          return ratingB.compareTo(ratingA);
        });
      return sorted;
    }

    final filtered = canteens.where((canteen) {
      final name = (canteen['name'] ?? '').toString().toLowerCase();
      final location = (canteen['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();

    // Sort by rating even when searching
    filtered.sort((a, b) {
      final ratingA = _extractRating(a);
      final ratingB = _extractRating(b);
      return ratingB.compareTo(ratingA);
    });

    return filtered;
  }

  double _extractRating(Map<String, dynamic> canteen) {
    final ratingData = canteen['rating'];
    if (ratingData is Map<String, dynamic>) {
      final average = ratingData['average'];
      if (average is num) return average.toDouble();
    } else if (ratingData is num) {
      return ratingData.toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final allCanteens = appState.canteens.toList();
        final canteens = _filteredCanteens(allCanteens);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'All Canteens',
              style: TextStyle(
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
              // Search Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  controller: TextEditingController(text: searchQuery)
                    ..selection = TextSelection.collapsed(
                      offset: searchQuery.length,
                    ),
                  decoration: InputDecoration(
                    hintText: 'Search canteens by name or location...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              // Results count
              if (searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${canteens.length} result${canteens.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Canteen List
              Expanded(
                child: canteens.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No canteens available'
                                  : 'No canteens found',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              Text(
                                'Try a different search term',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: canteens.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final canteen = canteens[index];
                          final canteenId = (canteen['id'] ?? '').toString();

                          return _AllCanteenTile(
                            name: (canteen['name'] ?? 'Canteen').toString(),
                            location: (canteen['location'] ?? '').toString(),
                            rating:
                                (canteen['rating'] as num?)?.toDouble() ?? 0,
                            isOpen: canteen['isOpen'] == true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CanteenMenuScreen(canteenId: canteenId),
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
      },
    );
  }
}

class _AllCanteenTile extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final bool isOpen;
  final VoidCallback onTap;

  const _AllCanteenTile({
    required this.name,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isOpen ? Colors.green : Colors.red).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF636E72),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
