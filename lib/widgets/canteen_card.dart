import 'package:flutter/material.dart';

class CanteenCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final bool isOpen;
  final bool isSelected;
  final VoidCallback onTap;

  const CanteenCard({
    super.key,
    required this.name,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 228,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B6B).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const Spacer(),
                Text(
                  isSelected ? 'Selected' : 'Tap to filter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
