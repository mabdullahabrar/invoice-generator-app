/// Reusable form validators, kept consistent across every form in the app.
class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return optional ? null : 'Email is required';
    }
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return optional ? null : 'Phone number is required';
    }
    final regex = RegExp(r'^[\d\+\-\s\(\)]{7,20}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null) {
      return 'Enter a valid number';
    }
    if (n <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null) {
      return 'Enter a valid number';
    }
    if (n < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? percentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // discount/tax percentage may be left as 0
    }
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid percentage';
    if (n < 0 || n > 100) return 'Must be between 0 and 100';
    return null;
  }
}
