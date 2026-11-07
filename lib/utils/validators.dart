import 'package:flutter/services.dart';

// One place for every field rule: what is allowed, how long it can be, and what to tell the person.
class Validators {
  // Longest allowed values. The same numbers limit typing and the checks below.
  static const nameMax = 50;
  static const emailMax = 64;
  static const passwordMax = 64;
  static const titleMax = 80;
  static const descriptionMax = 500;
  static const noteMax = 200;
  static const facilityMax = 40;
  static const areasMax = 20;

  // Keyboards can slip a space in after a typed dot, which breaks the email check.
  static final noSpaces = FilteringTextInputFormatter.deny(RegExp(r'\s'));

  // Letters from any language, spaces, apostrophes, dots and hyphens; nothing else can be typed.
  static final _nameChars = RegExp(r"[\p{L} '’.\-]", unicode: true);
  static final _name = RegExp(r"^\p{L}[\p{L} '’.\-]*$", unicode: true);
  static final _emailLocal = RegExp(r'^[A-Za-z0-9._%+\-]+$');
  static final _emailDomain = RegExp(
    r'^(alueducation\.com|alustudent\.com)$',
    caseSensitive: false,
  );
  static final _textBlocked = RegExp(r'[<>{}\\|^~`]');
  static final _facilityChars = RegExp(
    r"^[\p{L}\p{N} &'’.,\-/()]+$",
    unicode: true,
  );

  static final nameFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(_nameChars),
    LengthLimitingTextInputFormatter(nameMax),
  ];
  static final emailFormatters = <TextInputFormatter>[
    noSpaces,
    LengthLimitingTextInputFormatter(emailMax + 20),
  ];
  static final passwordFormatters = <TextInputFormatter>[
    noSpaces,
    LengthLimitingTextInputFormatter(passwordMax),
  ];
  static final titleFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_textBlocked),
    LengthLimitingTextInputFormatter(titleMax),
  ];
  static final descriptionFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_textBlocked),
    LengthLimitingTextInputFormatter(descriptionMax),
  ];
  static final noteFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_textBlocked),
    LengthLimitingTextInputFormatter(noteMax),
  ];
  static final facilityFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_textBlocked),
    LengthLimitingTextInputFormatter(facilityMax),
  ];

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    final at = value.indexOf('@');
    if (at < 0) return 'Add an @ to your email, like name@alustudent.com';
    if (value.indexOf('@', at + 1) >= 0) return 'Use only one @ in the email';
    final local = value.substring(0, at);
    final domain = value.substring(at + 1);
    if (local.isEmpty) return 'Add the part of your email before the @';
    if (local.length > emailMax) {
      return 'The part before the @ can’t be longer than $emailMax characters';
    }
    if (!_emailLocal.hasMatch(local) ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return 'Use only letters, numbers and . _ % + - before the @';
    }
    if (!_emailDomain.hasMatch(domain)) {
      return 'Use your @alueducation.com or @alustudent.com email';
    }
    return null;
  }

  // Each rule has a short label so forms can show a live checklist.
  static final passwordRules = <(String, bool Function(String))>[
    ('8 or more characters', (p) => p.length >= 8),
    ('An uppercase letter', (p) => p.contains(RegExp(r'[A-Z]'))),
    ('A lowercase letter', (p) => p.contains(RegExp(r'[a-z]'))),
    ('A number', (p) => p.contains(RegExp(r'\d'))),
  ];

  static int passwordScore(String? v) =>
      passwordRules.where((rule) => rule.$2(v ?? '')).length;

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length > passwordMax) {
      return 'Password can’t be longer than $passwordMax characters';
    }
    if (v.contains(RegExp(r'\s'))) return 'Password can’t contain spaces';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
    if (!v.contains(RegExp(r'\d'))) return 'Add a number';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Re-enter your password';
    if (v != original) return 'Passwords don’t match';
    return null;
  }

  static String? name(String? v) {
    final value = (v ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return 'Name is required';
    if (value.length > nameMax) {
      return 'Name can’t be longer than $nameMax characters';
    }
    if (!_name.hasMatch(value)) {
      return 'Use letters only, with spaces, apostrophes, dots or hyphens';
    }
    if (value.replaceAll(RegExp(r"[ '’.\-]"), '').length < 2) {
      return 'Enter at least 2 letters';
    }
    return null;
  }

  static String? title(String? v) {
    final value = v?.trim() ?? '';
    if (value.length < 5) return 'Title must be at least 5 characters';
    if (value.length > titleMax) return 'Title must be under 80 characters';
    if (_textBlocked.hasMatch(value)) {
      return 'Title can’t contain < > { } | \\ ^ ~ or `';
    }
    return null;
  }

  static String? description(String? v) {
    final value = v?.trim() ?? '';
    if (value.length < 10) {
      return 'Describe the issue in at least 10 characters';
    }
    if (value.length > descriptionMax) {
      return 'Description must be under 500 characters';
    }
    if (_textBlocked.hasMatch(value)) {
      return 'Description can’t contain < > { } | \\ ^ ~ or `';
    }
    return null;
  }

  // Staff must explain a rejection; other notes are optional.
  static String? updateNote(String? v, {required bool mandatory}) {
    final value = v?.trim() ?? '';
    if (mandatory && value.isEmpty) return 'Say why this report is rejected';
    if (value.length > noteMax) {
      return 'Keep the note under $noteMax characters';
    }
    if (_textBlocked.hasMatch(value)) {
      return 'The note can’t contain < > { } | \\ ^ ~ or `';
    }
    return null;
  }

  static String? facilityName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Facility name is required';
    if (value.length < 2) return 'Use at least 2 characters';
    if (value.length > facilityMax) {
      return 'Keep the name under $facilityMax characters';
    }
    if (!_facilityChars.hasMatch(value)) {
      return 'Use letters, numbers and & . , - / ( ) only';
    }
    return null;
  }

  // One area per line.
  static String? areas(String? v) {
    final lines = (v ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length > areasMax) return 'Add at most $areasMax areas';
    for (final line in lines) {
      if (line.length > facilityMax) {
        return 'Each area must be under $facilityMax characters';
      }
      if (!_facilityChars.hasMatch(line)) {
        return 'Areas can use letters, numbers and & . , - / ( ) only';
      }
    }
    return null;
  }

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }
}
