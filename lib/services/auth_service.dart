import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';
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

  // The profile document in Firestore is the source of truth: it is streamed live, so a
  // saved name, photo or campus shows up everywhere and survives a restart.
  Stream<AppUser?> userChanges() {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;
    Timer? fallback;

    void stopProfile() {
      fallback?.cancel();
      profileSub?.cancel();
      profileSub = null;
    }

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.userChanges().listen((user) {
          stopProfile();
          if (user == null) {
            controller.add(null);
            return;
          }
          var emitted = false;
          void emit(Map<String, dynamic>? data) {
            emitted = true;
            controller.add(_compose(user, data));
          }

          // If the database is unreachable, still let the person in with the sign-in details.
          fallback = Timer(const Duration(seconds: 5), () {
            if (!emitted) emit(null);
          });
          profileSub = _db
              .collection('users')
              .doc(user.uid)
              .snapshots()
              .listen(
                (snapshot) => emit(snapshot.data()),
                onError: (_) {
                  if (!emitted) emit(null);
                },
              );
        });
      },
      onCancel: () {
        stopProfile();
        return authSub?.cancel();
      },
    );
    return controller.stream;
  }

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

  // Says the same thing whether or not the account exists, so addresses can't be probed.
  Future<void> sendPasswordReset(String email) async {
    final address = email.trim().toLowerCase();
    if (roleFromAluEmail(address) == null) {
      throw const AuthFailure(_domainMessage);
    }
    try {
      await _auth.sendPasswordResetEmail(email: address);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
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
      final fields = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) fields['name'] = name.trim();
      if (campus != null && campus.trim().isNotEmpty) fields['campus'] = campus;
      if (photo != null) {
        fields['photoUrl'] = await _uploader.upload(
          photo,
          folder: CloudinaryConfig.profileFolder,
        );
      }
      if (fields.isNotEmpty) await _saveProfile(user, fields);
      // The copy kept by sign-in is best effort; the database already has the change.
      try {
        if (fields['name'] != null) {
          await user.updateDisplayName(fields['name']);
        }
        if (fields['photoUrl'] != null) {
          await user.updatePhotoURL(fields['photoUrl']);
        }
      } on FirebaseAuthException {
        // Ignored on purpose.
      }
      return (await _loadAppUser(_auth.currentUser))!;
    } on ImageUploadFailure catch (e) {
      throw AuthFailure(e.message);
    } on FirebaseException catch (e) {
      throw AuthFailure(
        e.code == 'permission-denied'
            ? 'The database refused the change. The latest security rules need to be published, then try again.'
            : e.message ?? 'Could not update your profile.',
      );
    }
  }

  Future<void> _saveProfile(User user, Map<String, dynamic> fields) async {
    final ref = _db.collection('users').doc(user.uid);
    try {
      await ref.update(fields);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      // Accounts made before profiles were stored get their document now.
      final email = (user.email ?? '').toLowerCase();
      await ref.set({
        'name': fields['name'] ?? user.displayName ?? email.split('@').first,
        'email': email,
        'role': roleFromAluEmail(email)?.name ?? 'student',
        'campus': fields['campus'] ?? 'Kigali Campus',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (fields['photoUrl'] != null) {
        await ref.update({'photoUrl': fields['photoUrl']});
      }
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

  // Sign-in details plus whatever the profile document says; the document wins.
  AppUser _compose(User user, Map<String, dynamic>? data) {
    final basic = _toAppUser(user)!;
    final name = (data?['name'] as String?)?.trim() ?? '';
    final campus = data?['campus'] as String? ?? '';
    return basic.copyWith(
      displayName: name.isEmpty ? null : name,
      photoUrl: data?['photoUrl'] as String?,
      // Accounts made before campuses existed default to Kigali.
      campus: campus.isEmpty ? 'Kigali Campus' : campus,
    );
  }

  Future<AppUser?> _loadAppUser(User? user) async {
    if (user == null) return null;
    try {
      final profile = await _db.collection('users').doc(user.uid).get();
      return _compose(user, profile.data());
    } on FirebaseException {
      return _compose(user, null);
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
