import 'package:cir/providers/auth_provider.dart';
import 'package:cir/services/auth_service.dart';
import 'package:cir/utils/user_role.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AuthProvider> signedIn(String email) async {
  final auth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'u1', email: email, displayName: 'Test User'),
  );
  final provider = AuthProvider(
    AuthService(auth: auth, firestore: FakeFirebaseFirestore()),
  );
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return provider;
}

void main() {
  test('the domain decides the role', () {
    expect(roleFromAluEmail('jordan@alueducation.com'), UserRole.staff);
    expect(roleFromAluEmail('Aline@AluStudent.com'), UserRole.student);
    expect(roleFromAluEmail('someone@gmail.com'), isNull);
    expect(roleFromAluEmail(null), isNull);
  });

  test('only the listed email counts as admin', () {
    expect(isAdminEmail('b.niyigena@alustudent.com'), isTrue);
    expect(isAdminEmail('B.Niyigena@alustudent.com'), isTrue);
    expect(isAdminEmail('b.niyigena@gmail.com'), isFalse);
    expect(isAdminEmail('aline@alustudent.com'), isFalse);
  });

  group('view switching', () {
    test('a student cannot switch to the staff view', () async {
      final provider = await signedIn('aline@alustudent.com');
      provider.switchView(UserRole.staff);
      expect(provider.activeRole, UserRole.student);
    });

    test('staff stay staff even if they ask for the student view', () async {
      final provider = await signedIn('jordan@alueducation.com');
      provider.switchView(UserRole.student);
      expect(provider.activeRole, UserRole.staff);
    });

    test('the admin starts as a student and can switch both ways', () async {
      final provider = await signedIn('b.niyigena@alustudent.com');
      expect(provider.activeRole, UserRole.student);
      provider.switchView(UserRole.staff);
      expect(provider.activeRole, UserRole.staff);
      provider.switchView(UserRole.student);
      expect(provider.activeRole, UserRole.student);
    });
  });
}
