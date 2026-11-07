import '../utils/user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
    this.photoUrl,
    this.role = 'student',
    this.campus = '',
  });

  final String uid, email, displayName;
  final String? photoUrl;
  final String role;
  final String campus;
  final bool emailVerified;

  bool get isAdmin => isAdminEmail(email);

  AppUser copyWith({
    bool? emailVerified,
    String? displayName,
    String? photoUrl,
    String? role,
    String? campus,
  }) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    emailVerified: emailVerified ?? this.emailVerified,
    photoUrl: photoUrl ?? this.photoUrl,
    role: role ?? this.role,
    campus: campus ?? this.campus,
  );
}
