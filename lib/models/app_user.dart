class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
  });

  final String uid, email, displayName;
  final bool emailVerified;

  AppUser copyWith({bool? emailVerified}) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}
