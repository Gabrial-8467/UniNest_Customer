class CurrencyFormatter {
  // Format Indian Rupee with proper formatting
  static String formatRupee(double amount) {
    return '₹${_formatIndianNumber(amount)}';
  }

  // Format Indian Rupee without symbol
  static String formatRupeeRaw(double amount) {
    return _formatIndianNumber(amount);
  }

  // Indian number formatting (lakhs, crores)
  static String _formatIndianNumber(double amount) {
    final String amountStr = amount.toStringAsFixed(2);
    final List<String> parts = amountStr.split('.');
    String wholePart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Handle negative numbers
    bool isNegative = wholePart.startsWith('-');
    if (isNegative) {
      wholePart = wholePart.substring(1);
    }

    // Format according to Indian system
    if (wholePart.length <= 3) {
      // Less than 1000
      wholePart = wholePart.padLeft(3, '0');
    } else if (wholePart.length <= 5) {
      // Thousands
      wholePart = '${wholePart.substring(0, wholePart.length - 3)},${wholePart.substring(wholePart.length - 3)}';
    } else if (wholePart.length <= 7) {
      // Lakhs
      wholePart = '${wholePart.substring(0, wholePart.length - 5)},${wholePart.substring(wholePart.length - 5, wholePart.length - 3)},${wholePart.substring(wholePart.length - 3)}';
    } else {
      // Crores and above
      wholePart = '${wholePart.substring(0, wholePart.length - 7)},${wholePart.substring(wholePart.length - 7, wholePart.length - 5)},${wholePart.substring(wholePart.length - 5, wholePart.length - 3)},${wholePart.substring(wholePart.length - 3)}';
    }

    // Remove leading zeros and add negative sign if needed
    wholePart = wholePart.replaceFirst(RegExp(r'^0+'), '');
    if (wholePart.startsWith(',')) {
      wholePart = wholePart.substring(1);
    }
    if (isNegative && wholePart.isNotEmpty) {
      wholePart = '-$wholePart';
    }

    return '$wholePart.$decimalPart';
  }

  // Format with short notation (K, L, Cr)
  static String formatRupeeShort(double amount) {
    if (amount < 1000) {
      return '₹${amount.toStringAsFixed(0)}';
    } else if (amount < 100000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount < 10000000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
  }

  // Parse string to double safely
  static double parseAmount(String? amount) {
    if (amount == null || amount.isEmpty) return 0.0;
    
    // Remove currency symbols and commas
    String cleanAmount = amount
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    
    return double.tryParse(cleanAmount) ?? 0.0;
  }

  // Validate amount
  static bool isValidAmount(String? amount) {
    if (amount == null || amount.isEmpty) return false;
    
    String cleanAmount = amount
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    
    return double.tryParse(cleanAmount) != null && 
           double.parse(cleanAmount) >= 0;
  }

  // Round to nearest rupee
  static double roundToRupee(double amount) {
    return (amount).roundToDouble();
  }

  // Round to paise (2 decimal places)
  static double roundToPaise(double amount) {
    return (amount * 100).roundToDouble() / 100;
  }

  // Calculate tax amount
  static double calculateTax(double amount, double taxRate) {
    return roundToPaise(amount * taxRate);
  }

  // Calculate total with tax
  static double calculateTotalWithTax(double amount, double taxRate) {
    return roundToPaise(amount + calculateTax(amount, taxRate));
  }

  // Calculate discount amount
  static double calculateDiscount(double amount, double discountPercent) {
    return roundToPaise(amount * (discountPercent / 100));
  }

  // Calculate price after discount
  static double calculatePriceAfterDiscount(double amount, double discountPercent) {
    return roundToPaise(amount - calculateDiscount(amount, discountPercent));
  }
}
