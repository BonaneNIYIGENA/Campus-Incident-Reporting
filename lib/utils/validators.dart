import 'package:flutter/services.dart';

class Validators {
  // Keyboards can slip a space in after a typed dot, which breaks the email check.
  static final noSpaces = FilteringTextInputFormatter.deny(RegExp(r'\s'));

  // Only ALU domains are allowed, matched case-insensitively.
  static final _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@(alueducation\.com|alustudent\.com)$',
    caseSensitive: false,
  );
  static final _password = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
  static final _name = RegExp(r"^[A-Za-z][A-Za-z\s'.\-]{1,49}$");

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!_email.hasMatch(value)) {
      return 'Use your @alueducation.com or @alustudent.com email';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!_password.hasMatch(v)) {
      return 'Min 8 characters with uppercase, lowercase and a number';
    }
    return null;
  }

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (!_name.hasMatch(value)) return 'Enter a valid name (2-50 letters)';
    return null;
  }

  static String? title(String? v) {
    final value = v?.trim() ?? '';
    if (value.length < 5) return 'Title must be at least 5 characters';
    if (value.length > 80) return 'Title must be under 80 characters';
    return null;
  }

  static String? description(String? v) {
    final value = v?.trim() ?? '';
    if (value.length < 10) {
      return 'Describe the issue in at least 10 characters';
    }
    if (value.length > 500) return 'Description must be under 500 characters';
    return null;
  }

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }
}
