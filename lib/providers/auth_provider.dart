import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

export '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _sub = _service.userChanges().listen((user) {
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  final AuthService _service;
  StreamSubscription<AppUser?>? _sub;
  AppUser? _user;
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email, password));

  Future<bool> signUp(String name, String email, String password) =>
      _run(() => _service.signUp(name, email, password));

  Future<bool> refreshVerification() async {
    try {
      final verified = await _service.refreshVerification();
      final fresh = _service.currentUser;
      if (fresh != null) {
        _user = fresh.copyWith(role: _user?.role, campus: _user?.campus);
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

  Future<void> signOut() => _service.signOut();

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
