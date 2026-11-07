enum UserRole { staff, student }

// Accounts allowed to switch between the student and staff views; firestore.rules lists the same emails.
const adminEmails = {'b.niyigena@alustudent.com'};

UserRole? roleFromAluEmail(String? email) {
  final address = email?.trim().toLowerCase() ?? '';
  if (address.endsWith('@alueducation.com')) return UserRole.staff;
  if (address.endsWith('@alustudent.com')) return UserRole.student;
  return null;
}

UserRole? roleFromStoredValue(String? role) => switch (role) {
  'staff' => UserRole.staff,
  'student' => UserRole.student,
  _ => null,
};

bool isAdminEmail(String? email) =>
    adminEmails.contains(email?.trim().toLowerCase());
