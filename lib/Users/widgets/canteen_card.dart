import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class CanteenCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final bool isOpen;
  final bool isSelected;
  final VoidCallback onTap;
  final String? imageUrl;
  final bool isDisabled;

  const CanteenCard({
    super.key,
    required this.name,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.isSelected,
    required this.onTap,
    this.imageUrl,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 228,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : (isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isSelected ? AppColors.primary : AppColors.textLight),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColorFiltered(
                    colorFilter: isDisabled
                        ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          ),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            // Enable HTTP caching for better performance
                            headers: const {'Cache-Control': 'max-age=3600'},
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultIcon(),
                          )
                        : _buildDefaultIcon(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDisabled
                          ? Colors.grey[600]
                          : const Color(0xFF2D3436),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey[300]
                        : (isOpen ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? Colors.grey[600]
                          : (isOpen ? AppColors.success : AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDisabled ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: isDisabled ? Colors.grey[500] : Colors.amber[600],
                ),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDisabled
                        ? Colors.grey[600]
                        : const Color(0xFF2D3436),
                  ),
                ),
                const Spacer(),
                Text(
                  isDisabled
                      ? 'Clear cart'
                      : (isSelected ? 'Selected' : 'Tap to filter'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? Colors.grey[600]
                        : (isSelected
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF636E72)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}
