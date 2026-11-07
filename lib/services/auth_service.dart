import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';

import '../config/cloudinary_config.dart';
import '../models/app_user.dart';
import '../utils/user_role.dart';
import 'image_upload_service.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ImageUploader? uploader,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _uploader = uploader ?? CloudinaryUploader();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final ImageUploader _uploader;

  Stream<AppUser?> userChanges() => _auth.userChanges().asyncMap(_loadAppUser);

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  Future<AppUser> signUp(
    String name,
    String email,
    String password, {
    String campus = 'Kigali Campus',
  }) async {
    final address = email.trim().toLowerCase();
    final allowed = roleFromAluEmail(address);
    if (allowed == null) throw const AuthFailure(_domainMessage);
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
        'role': allowed.name,
        'campus': campus,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
      await user.reload();
      return (await _loadAppUser(_auth.currentUser))!;
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
      return (await _loadAppUser(_auth.currentUser))!;
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

  Future<AppUser> updateProfile({
    String? name,
    String? campus,
    File? photo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Sign in again to continue.');
    try {
      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
        await _db.collection('users').doc(user.uid).update({
          'name': name.trim(),
        });
      }
      if (campus != null && campus.trim().isNotEmpty) {
        await _db.collection('users').doc(user.uid).update({'campus': campus});
      }
      if (photo != null) {
        final url = await _uploader.upload(
          photo,
          folder: CloudinaryConfig.profileFolder,
        );
        await user.updatePhotoURL(url);
        await _db.collection('users').doc(user.uid).update({'photoUrl': url});
      }
      await user.reload();
      return (await _loadAppUser(_auth.currentUser))!;
    } on ImageUploadFailure catch (e) {
      throw AuthFailure(e.message);
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Could not update your profile.');
    }
  }

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
      photoUrl: user.photoURL,
      role: roleFromAluEmail(email)?.name ?? '',
    );
  }

  Future<AppUser?> _loadAppUser(User? user) async {
    final basic = _toAppUser(user);
    if (basic == null) return null;
    try {
      final profile = await _db.collection('users').doc(user!.uid).get();
      final data = profile.data() ?? const <String, dynamic>{};
      final saved = data['campus'] as String? ?? '';
      // Accounts made before campuses existed default to Kigali.
      final savedPhoto = data['photoUrl'] as String?;
      return basic.copyWith(
        campus: saved.isEmpty ? 'Kigali Campus' : saved,
        photoUrl: basic.photoUrl ?? savedPhoto,
      );
    } on FirebaseException {
      return basic;
    }
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
