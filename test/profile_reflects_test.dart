import 'dart:io';

import 'package:cir/providers/auth_provider.dart';
import 'package:cir/services/auth_service.dart';
import 'package:cir/services/image_upload_service.dart';
import 'package:cir/widgets/user_avatar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo =
    'https://res.cloudinary.com/dgxaazbuq/image/upload/v1/cir/profiles/me.jpg';

class _FakeUploader implements ImageUploader {
  String? folder;
  @override
  Future<String> upload(File file, {required String folder}) async {
    this.folder = folder;
    return _photo;
  }
}

void main() {
  test('a saved name and photo reach the signed in user', () async {
    final db = FakeFirebaseFirestore();
    final uploader = _FakeUploader();
    await db.collection('users').doc('u1').set({
      'name': 'Aline',
      'email': 'aline@alustudent.com',
      'role': 'student',
      'campus': 'Kigali Campus',
    });
    final provider = AuthProvider(
      AuthService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            uid: 'u1',
            email: 'aline@alustudent.com',
            displayName: 'Aline',
          ),
        ),
        firestore: db,
        uploader: uploader,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.user?.photoUrl, isNot(_photo));

    final file = File('${Directory.systemTemp.path}/cir_profile_test.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => file.deleteSync());
    final ok = await provider.updateProfile(
      name: 'Aline Niyonsenga',
      photo: file,
    );

    expect(ok, isTrue);
    expect(uploader.folder, 'cir/profiles');
    expect(provider.user?.displayName, 'Aline Niyonsenga');
    expect(provider.user?.photoUrl, _photo);
    final saved = await db.collection('users').doc('u1').get();
    expect(saved.data()!['photoUrl'], _photo);
  });

  testWidgets('the avatar falls back to initials until a photo loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserAvatar(user: null, size: 40))),
    );
    expect(find.text('?'), findsOneWidget);
  });
}
