import 'dart:convert';
import '../utils/secure_logger.dart';

/// Input validation utility for secure data handling
class InputValidator {
  // Password requirements
  static const int minPasswordLength = 12;
  static const int maxPasswordLength = 128;
  static const int minUppercase = 1;
  static const int minLowercase = 1;
  static const int minNumbers = 1;
  static const int minSpecialChars = 1;

  // Email validation regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password strength regex patterns
  static final RegExp uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp numberRegex = RegExp(r'[0-9]');
  static final RegExp specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp whitespaceRegex = RegExp(r'\s');

  // Name validation
  static final RegExp nameRegex = RegExp(r'^[a-zA-Z\s\\-]+$');
  static const int maxNameLength = 50;
  static const int minNameLength = 2;

  // Phone validation (basic pattern)
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

  /// Validate email address
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(false, 'Email is required');
    }

    if (email.length > 254) {
      return ValidationResult(false, 'Email is too long');
    }

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(false, 'Invalid email format');
    }

    // Check for common email issues
    if (email.contains('..')) {
      return ValidationResult(false, 'Email contains invalid characters');
    }

    if (email.startsWith('.') || email.endsWith('.')) {
      return ValidationResult(false, 'Email cannot start or end with a dot');
    }

    return ValidationResult(true, 'Valid email');
  }

  /// Validate password strength
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }

    if (password.length < minPasswordLength) {
      return ValidationResult(
        false,
        'Password must be at least $minPasswordLength characters long',
      );
    }

    if (password.length > maxPasswordLength) {
      return ValidationResult(
        false,
        'Password must be less than $maxPasswordLength characters',
      );
    }

    if (whitespaceRegex.hasMatch(password)) {
      return ValidationResult(false, 'Password cannot contain whitespace');
    }

    // Count character types
    final uppercaseCount = password
        .split('')
        .where((char) => uppercaseRegex.hasMatch(char))
        .length;
    final lowercaseCount = password
        .split('')
        .where((char) => lowercaseRegex.hasMatch(char))
        .length;
    final numberCount = password
        .split('')
        .where((char) => numberRegex.hasMatch(char))
        .length;
    final specialCharCount = password
        .split('')
        .where((char) => specialCharRegex.hasMatch(char))
        .length;

    if (uppercaseCount < minUppercase) {
      return ValidationResult(
        false,
        'Password must contain at least $minUppercase uppercase letter',
      );
    }

    if (lowercaseCount < minLowercase) {
      return ValidationResult(
        false,
        'Password must contain at least $minLowercase lowercase letter',
      );
    }

    if (numberCount < minNumbers) {
      return ValidationResult(
        false,
        'Password must contain at least $minNumbers number',
      );
    }

    if (specialCharCount < minSpecialChars) {
      return ValidationResult(
        false,
        'Password must contain at least $minSpecialChars special character',
      );
    }

    // Check for common weak patterns
    if (_isCommonPassword(password)) {
      return ValidationResult(
        false,
        'Password is too common. Please choose a stronger password',
      );
    }

    return ValidationResult(true, 'Password is strong');
  }

  /// Validate name field
  static ValidationResult validateName(String name) {
    if (name.isEmpty) {
      return ValidationResult(false, 'Name is required');
    }

    if (name.length < minNameLength) {
      return ValidationResult(
        false,
        'Name must be at least $minNameLength characters long',
      );
    }

    if (name.length > maxNameLength) {
      return ValidationResult(
        false,
        'Name must be less than $maxNameLength characters',
      );
    }

    if (!nameRegex.hasMatch(name)) {
      return ValidationResult(
        false,
        'Name can only contain letters, spaces, and hyphens',
      );
    }

    return ValidationResult(true, 'Valid name');
  }

  /// Validate phone number
  static ValidationResult validatePhone(String phone) {
    if (phone.isEmpty) {
      return ValidationResult(false, 'Phone number is required');
    }

    if (!phoneRegex.hasMatch(phone)) {
      return ValidationResult(false, 'Invalid phone number format');
    }

    return ValidationResult(true, 'Valid phone number');
  }

  /// Sanitize input string
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous characters
    String sanitized = input;

    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove script tags specifically
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      '',
    );

    // Remove SQL injection patterns
    sanitized = sanitized.replaceAll(
      RegExp(
        r'(union|select|insert|update|delete|drop|create|alter|exec|execute)',
        caseSensitive: false,
      ),
      '',
    );

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }

  /// Validate and sanitize JSON data
  static Map<String, dynamic> validateAndSanitizeJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final sanitized = <String, dynamic>{};

      data.forEach((key, value) {
        if (value is String) {
          sanitized[sanitizeInput(key)] = sanitizeInput(value);
        } else if (value is Map<String, dynamic>) {
          sanitized[sanitizeInput(key)] = validateAndSanitizeJson(
            jsonEncode(value),
          );
        } else if (value is List) {
          sanitized[sanitizeInput(key)] = value.map((item) {
            if (item is String) return sanitizeInput(item);
            return item;
          }).toList();
        } else {
          sanitized[sanitizeInput(key)] = value;
        }
      });

      return sanitized;
    } catch (e) {
      SecureLogger.error('JSON validation failed', error: e);
      return {};
    }
  }

  /// Check if password is commonly used
  static bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
      '1234567890',
      'password1',
      '123123',
      'qwerty123',
      'password!',
      'admin123',
      'root',
      'toor',
      'passw0rd',
    ];

    final lowerPassword = password.toLowerCase();
    return commonPasswords.any((common) => lowerPassword.contains(common));
  }

  /// Generate password strength score
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;

    int score = 0;

    // Length bonus
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character variety bonus
    if (uppercaseRegex.hasMatch(password)) score++;
    if (lowercaseRegex.hasMatch(password)) score++;
    if (numberRegex.hasMatch(password)) score++;
    if (specialCharRegex.hasMatch(password)) score++;

    // Deductions
    if (whitespaceRegex.hasMatch(password)) score--;
    if (_isCommonPassword(password)) score -= 2;

    // Map score to strength
    if (score <= 2) return PasswordStrength.veryWeak;
    if (score <= 4) return PasswordStrength.weak;
    if (score <= 6) return PasswordStrength.medium;
    if (score <= 8) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult(this.isValid, this.message);
}

/// Password strength enum
enum PasswordStrength { veryWeak, weak, medium, strong, veryStrong }
