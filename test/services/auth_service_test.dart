import 'package:cir/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAuth extends MockFirebaseAuth {
  _FailingAuth(this.code);
  final String code;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw FirebaseAuthException(code: code);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw FirebaseAuthException(code: code);
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('signUp', () {
    test('creates the account, profile document and unverified user', () async {
      final auth = MockFirebaseAuth(verifyEmailAutomatically: false);
      final service = AuthService(auth: auth, firestore: db);

      final user = await service.signUp(
        '  Aline Student ',
        'Aline@AluStudent.com',
        'Campus1234',
      );

      expect(user.email, 'aline@alustudent.com');
      expect(user.displayName, 'Aline Student');
      expect(user.emailVerified, isFalse);

      final profile = await db.collection('users').doc(user.uid).get();
      expect(profile.data()!['role'], 'student');
      expect(profile.data()!['email'], 'aline@alustudent.com');
      expect(profile.data()!['name'], 'Aline Student');
    });

    test('@alueducation.com accounts are staff and @alustudent.com are students', () async {
      final service = AuthService(auth: MockFirebaseAuth(), firestore: db);
      final user = await service.signUp(
        'Jordan Staff',
        'jordan@alueducation.com',
        'Campus1234',
      );
      final profile = await db.collection('users').doc(user.uid).get();
      expect(profile.data()!['role'], 'staff');
      expect(profile.data()!['campus'], 'Kigali Campus');
      expect(user.role, 'staff');

      final other = await AuthService(
        auth: MockFirebaseAuth(),
        firestore: db,
      ).signUp('Aline Student', 'aline@alustudent.com', 'Campus1234');
      final saved = await db.collection('users').doc(other.uid).get();
      expect(saved.data()!['role'], 'student');
      expect(other.isAdmin, isFalse);
    });

    test('rejects non ALU emails before calling Firebase', () async {
      final service = AuthService(auth: MockFirebaseAuth(), firestore: db);
      await expectLater(
        service.signUp('Eve', 'eve@gmail.com', 'Campus1234'),
        throwsA(isA<AuthFailure>()),
      );
      expect((await db.collection('users').get()).docs, isEmpty);
    });

    test('maps an existing account to a readable message', () async {
      final service = AuthService(
        auth: _FailingAuth('email-already-in-use'),
        firestore: db,
      );
      await expectLater(
        service.signUp('Aline', 'aline@alustudent.com', 'Campus1234'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'An account already exists for this email.',
          ),
        ),
      );
    });
  });

  group('signIn', () {
    test('signs in a valid ALU account', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'u1',
          email: 'aline@alustudent.com',
          displayName: 'Aline',
          isEmailVerified: true,
        ),
      );
      final service = AuthService(auth: auth, firestore: db);
      final user = await service.signIn('aline@alustudent.com', 'Campus1234');
      expect(user.uid, 'u1');
      expect(user.emailVerified, isTrue);
    });

    test('rejects a non ALU email without contacting Firebase', () async {
      final service = AuthService(auth: MockFirebaseAuth(), firestore: db);
      await expectLater(
        service.signIn('eve@alueducation.com.evil.io', 'Campus1234'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('wrong password gives a generic message', () async {
      final service = AuthService(
        auth: _FailingAuth('wrong-password'),
        firestore: db,
      );
      await expectLater(
        service.signIn('aline@alustudent.com', 'nope'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Email or password is incorrect.',
          ),
        ),
      );
    });
  });

  group('session', () {
    test('userChanges follows sign in and sign out', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'aline@alustudent.com'),
      );
      final service = AuthService(auth: auth, firestore: db);
      final seen = <String?>[];
      final sub = service.userChanges().listen((u) => seen.add(u?.uid));

      await service.signIn('aline@alustudent.com', 'Campus1234');
      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, contains('u1'));
      expect(seen.last, isNull);
      expect(service.currentUser, isNull);
    });

    test('refreshVerification is false when nobody is signed in', () async {
      final service = AuthService(auth: MockFirebaseAuth(), firestore: db);
      expect(await service.refreshVerification(), isFalse);
    });

    test('resendVerification needs a signed in user', () async {
      final service = AuthService(auth: MockFirebaseAuth(), firestore: db);
      await expectLater(
        service.resendVerification(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
