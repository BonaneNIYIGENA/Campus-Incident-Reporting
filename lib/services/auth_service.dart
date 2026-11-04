import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../utils/user_role.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUser);

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  Future<AppUser> signUp(String name, String email, String password) async {
    final address = email.trim().toLowerCase();
    final role = roleFromAluEmail(address);
    if (role == null) throw const AuthFailure(_domainMessage);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: address,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': address,
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
      await user.reload();
      return _toAppUser(_auth.currentUser)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } on FirebaseException {
      throw const AuthFailure('Could not save your profile. Try again.');
    }
  }

  Future<AppUser> signIn(String email, String password) async {
    final address = email.trim().toLowerCase();
    if (roleFromAluEmail(address) == null) {
      throw const AuthFailure(_domainMessage);
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: address,
        password: password,
      );
      return _toAppUser(_auth.currentUser)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  // Reloading and refreshing the token makes the new email_verified claim reach the rules.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Sign in again to continue.');
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final email = user.email ?? '';
    return AppUser(
      uid: user.uid,
      email: email,
      displayName: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : email.split('@').first,
      emailVerified: user.emailVerified,
    );
  }

  static const _domainMessage =
      'Use an @alueducation.com or @alustudent.com address.';

  String _messageFor(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Choose a stronger password.',
    'invalid-email' => 'Enter a valid email address.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'No connection. Check your internet and retry.',
    'user-disabled' => 'This account has been disabled.',
    _ => 'Something went wrong. Please try again.',
  };
}
