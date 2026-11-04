import 'package:cir/providers/auth_provider.dart';
import 'package:cir/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

AuthProvider build({MockFirebaseAuth? auth}) => AuthProvider(
  AuthService(
    auth: auth ?? MockFirebaseAuth(verifyEmailAutomatically: false),
    firestore: FakeFirebaseFirestore(),
  ),
);

void main() {
  test('starts initializing and settles with no user', () async {
    final provider = build();
    expect(provider.initializing, isTrue);
    await pumpEventQueue();
    expect(provider.initializing, isFalse);
    expect(provider.user, isNull);
  });

  test('restores an existing session on start', () async {
    final provider = build(
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'aline@alustudent.com'),
      ),
    );
    await pumpEventQueue();
    expect(provider.user?.uid, 'u1');
  });

  test('sign up leaves the user unverified and not busy', () async {
    final provider = build();
    final ok = await provider.signUp(
      'Aline Student',
      'aline@alustudent.com',
      'Campus1234',
    );
    expect(ok, isTrue);
    expect(provider.busy, isFalse);
    expect(provider.error, isNull);
    expect(provider.user?.emailVerified, isFalse);
    expect(provider.user?.displayName, 'Aline Student');
  });

  test('sign up with a non ALU email sets a readable error', () async {
    final provider = build();
    final ok = await provider.signUp('Eve', 'eve@gmail.com', 'Campus1234');
    expect(ok, isFalse);
    expect(provider.error, contains('@alueducation.com'));
    expect(provider.user, isNull);
  });

  test('notifies while busy and when done', () async {
    final provider = build();
    final busyStates = <bool>[];
    provider.addListener(() => busyStates.add(provider.busy));
    await provider.signUp('Aline', 'aline@alustudent.com', 'Campus1234');
    expect(busyStates.first, isTrue);
    expect(busyStates.last, isFalse);
  });

  test('sign in then sign out clears the user', () async {
    final provider = build(
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'u1',
          email: 'aline@alustudent.com',
          isEmailVerified: true,
        ),
      ),
    );
    expect(await provider.signIn('aline@alustudent.com', 'Campus1234'), isTrue);
    await pumpEventQueue();
    expect(provider.user?.emailVerified, isTrue);

    await provider.signOut();
    await pumpEventQueue();
    expect(provider.user, isNull);
  });

  test('refreshVerification and resend need a signed in user', () async {
    final provider = build();
    expect(await provider.refreshVerification(), isFalse);
    expect(await provider.resendCurrentVerification(), isFalse);
  });

  test('resend works once signed up', () async {
    final provider = build();
    await provider.signUp('Aline', 'aline@alustudent.com', 'Campus1234');
    expect(await provider.resendCurrentVerification(), isTrue);
  });
}
