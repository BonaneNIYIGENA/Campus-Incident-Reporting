import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/user_role.dart';

export '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _sub = _service.userChanges().listen((user) {
      if (user?.uid != _user?.uid) _viewAs = null;
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  final AuthService _service;
  StreamSubscription<AppUser?>? _sub;
  AppUser? _user;
  UserRole? _viewAs;
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;

  // The role is fixed by the email domain; only an admin account can look at the other view.
  UserRole? get activeRole {
    final current = _user;
    if (current == null) return null;
    if (current.isAdmin && _viewAs != null) return _viewAs;
    return roleFromStoredValue(current.role);
  }

  void switchView(UserRole role) {
    if (_user?.isAdmin != true) return;
    _viewAs = role;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email, password));

  Future<bool> signUp(
    String name,
    String email,
    String password, {
    String campus = 'Kigali Campus',
  }) => _run(() => _service.signUp(name, email, password, campus: campus));

  Future<bool> refreshVerification() async {
    try {
      final verified = await _service.refreshVerification();
      final fresh = _service.currentUser;
      if (fresh != null && _user != null) {
        _user = _user!.copyWith(emailVerified: fresh.emailVerified);
      } else if (fresh != null) {
        _user = fresh;
      }
      notifyListeners();
      return verified;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resendCurrentVerification() async {
    try {
      await _service.resendVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not send the email. Wait a moment and try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() => _service.signOut();

  Future<bool> updateProfile({
    String? name,
    String? campus,
    File? photo,
  }) async {
    try {
      _user = await _service.updateProfile(
        name: name,
        campus: campus,
        photo: photo,
      );
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthFailure catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    }
    _busy = false;
    notifyListeners();
    return _error == null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
