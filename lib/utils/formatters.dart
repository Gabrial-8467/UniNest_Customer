class Formatters {
  // Format price with currency symbol
  static String formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  // Format price without currency symbol
  static String formatPriceRaw(double price) {
    return price.toStringAsFixed(2);
  }

  // Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Format full date
  static String formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format time
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Format order status
  static String formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Capitalize the first letter of each word with support for acronyms and hyphenated words
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.contains('-')) {
        return word.split('-').map((subWord) => _capitalizeWord(subWord)).join('-');
      }
      return _capitalizeWord(word);
    }).join(' ');
  }

  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    // If the word is entirely uppercase and longer than 1 character (acronyms like KFC, VEG), preserve it
    if (word == word.toUpperCase() && word.length > 1) {
      return word;
    }
    // Otherwise, capitalize the first letter and convert the rest to lowercase ONLY if the rest was all uppercase (e.g. "BURGER" -> "Burger")
    final firstChar = word[0].toUpperCase();
    final remainder = word.substring(1);
    if (remainder == remainder.toUpperCase() && remainder.isNotEmpty) {
      return firstChar + remainder.toLowerCase();
    }
    return firstChar + remainder;
  }

  // Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
