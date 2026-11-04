import 'package:flutter/foundation.dart';

import '../utils/user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
  });
  final String uid, email, displayName;
  final bool emailVerified;
  AppUser copyWith({bool? emailVerified}) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _busy = false;
  String? _error;
  final Map<String, String> _accounts = {
    'student@alustudent.com': 'Campus1234',
    'staff@alueducation.com': 'Campus1234',
  };
  final Map<String, String> _names = {
    'student@alustudent.com': 'Aline Student',
    'staff@alueducation.com': 'Jordan Staff',
  };
  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final address = email.trim().toLowerCase();
    if (roleFromAluEmail(address) == null) {
      _error = 'Use an @alueducation.com or @alustudent.com address.';
    } else if (!_accounts.containsKey(address)) {
      _error =
          'No demo account exists yet. Create an account to preview the flow.';
    } else if (_accounts[address] != password) {
      _error = 'Email or password is incorrect.';
    } else {
      _user = AppUser(
        uid: address,
        email: address,
        displayName: _names[address] ?? _nameFromEmail(address),
        emailVerified: true,
      );
    }
    _busy = false;
    notifyListeners();
    return _error == null;
  }

  Future<bool> signUp(String name, String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final address = email.trim().toLowerCase();
    if (roleFromAluEmail(address) == null) {
      _error = 'Use an @alueducation.com or @alustudent.com address.';
    } else if (_accounts.containsKey(address)) {
      _error = 'An account already exists for this email.';
    } else {
      _accounts[address] = password;
      _names[address] = name.trim();
      _user = AppUser(uid: address, email: address, displayName: name.trim());
    }
    _busy = false;
    notifyListeners();
    return _error == null;
  }

  Future<bool> refreshVerification() async {
    if (_user == null) return false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _user = _user!.copyWith(emailVerified: true);
    notifyListeners();
    return true;
  }

  Future<bool> resendCurrentVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _user != null;
  }

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  String _nameFromEmail(String email) => email
      .split('@')
      .first
      .split(RegExp(r'[._-]'))
      .map(
        (part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
      )
      .join(' ');
}
