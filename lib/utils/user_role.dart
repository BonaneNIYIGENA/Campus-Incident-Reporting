enum UserRole { staff, student }

UserRole? roleFromAluEmail(String? email) {
  final address = email?.trim().toLowerCase() ?? '';
  if (address.endsWith('@alueducation.com')) return UserRole.staff;
  if (address.endsWith('@alustudent.com')) return UserRole.student;
  return null;
}
