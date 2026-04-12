// lib/core/utils/validators.dart
//
// All form validators used across the app.

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 10 || n > 100) return 'Age must be between 10 and 100';
    return null;
  }

  static String? tournamentName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Tournament name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (value.trim().length > 60) return 'Name must be under 60 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }
}
