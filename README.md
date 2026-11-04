# ALU Campus Care (cir)

Mobile app where ALU students report campus issues (water, electricity, facilities, furniture, sanitation, safety) and staff review them and update their status. Built with Flutter, Provider and Firebase (Auth, Cloud Firestore).

## How it works

- Sign up and sign in are limited to `@alustudent.com` (students) and `@alueducation.com` (staff). The app opens only after the email is verified.
- Students submit reports with a category, campus location, description and an optional anonymous flag, then browse, search, filter and upvote reports from others. They can delete their own report while it is still Submitted.
- Staff see every report, change its status (Submitted, Under Review, In Progress, Resolved, Rejected) and leave a note. Each change is kept in the status history. Rejecting needs a note.

## Project layout

```
lib/
  models/      AppUser, Incident, StatusEvent
  services/    AuthService, IncidentService (the only code that talks to Firebase)
  providers/   AuthProvider, IncidentProvider, ThemeProvider (state with Provider)
  screens/     auth, student, staff and shared incident screens
  widgets/     incident card
  utils/       validators, role from email
firestore.rules   security rules
rules-tests/      Firestore rules tests (Node, run on the emulator)
test/             unit and widget tests
```

UI talks to providers, providers talk to services, and only services use Firebase.

## Firestore data

```
users/{uid}        name, email, role, createdAt
incidents/{id}     title, description, category, building, status, reporterId,
                   reporterName, isAnonymous, upvoteCount, upvoters[], createdAt,
                   updatedAt, history[ {status, note, changedBy, at} ]
```

Role is derived from the email domain and enforced in `firestore.rules`, so the app cannot be tricked into showing staff features and a student cannot change a status or give themselves a role.

## Run it

```
flutter pub get
flutter run
```

`android/app/google-services.json` and `lib/firebase_options.dart` point at the project `incident-reporting-app-73901`.

## Tests

```
flutter test                       # validators, services, providers, widgets
cd rules-tests && npm install && npm test   # security rules on the Firestore emulator (needs Java)
```

Deploy rules with `firebase deploy --only firestore:rules`.
