# Campus Incident Reporting (cir)

An Android app where ALU students report problems on campus (water, electricity, facilities, furniture, sanitation, safety) and campus staff review them and move them from **Submitted** to **In progress** to **Resolved** (or **Rejected** with a reason). Built with Flutter, Provider, Firebase Authentication, Cloud Firestore and Cloudinary (for photos).

The full write-up, with the architecture, data model, security design, design decisions, testing and the story of how it was built, is in [`docs/TECHNICAL_REPORT.md`](docs/TECHNICAL_REPORT.md).

## What it does

- **Sign in with an ALU email only.** `@alustudent.com` is a student, `@alueducation.com` is staff. The app opens only after the email is verified, and the rules check the domain again on the server.
- **Report an issue** with a title, description, category, the facility and area on your campus, an optional photo, and an optional anonymous switch.
- **Browse and filter** reports with a search bar and a filter sheet (status and category).
- **Follow progress** on a roadmap in the report details: each step shows who did it and when, and steps not reached yet stay grey.
- **Staff update status** with a note (a note is required to reject), manage the facilities and areas of each campus, and see new reports as notifications.
- **Notifications** drop down from the top bar: swipe right to mark read, left to delete.
- **Profile** with a photo, name and campus, kept in Firestore so it is the same after a restart.
- Light and dark themes, and one navigation bar that is on every screen.

My own address is allow-listed as an admin so one account can switch between the student and staff views in the demo. Everyone else gets only the role their email gives them.

## Project layout

```
lib/
  main.dart            loading screen first, then Firebase and the providers
  config/              Cloudinary settings (public identifiers only)
  models/              AppUser, Incident (+ StatusEvent), CampusFacility
  services/            AuthService, IncidentService, FacilityService, image upload
  providers/           Auth, Incident, Facility, Alerts, Theme (state with Provider)
  screens/             auth, account, shell (navigation), student, staff, incident screens
  widgets/             nav bar, cards, roadmap, form fields and sheets, splash
  theme/               colours, icons, status styles
  utils/               validators (one rule per field), role from email
firestore.rules        security rules
rules-tests/           security-rules tests (Node, Firestore emulator)
test/                  Dart unit, service, provider and widget tests
docs/                  technical report and screenshots
```

Screens talk to providers, providers talk to services, and only services talk to Firebase or Cloudinary.

## Firestore data

```
users/{uid}                        name, email, role, campus, photoUrl, createdAt
users/{uid}/alertStates/{key}      read, deleted, updatedAt
incidents/{id}                     title, description, category, building, status,
                                   reporterId, reporterName, isAnonymous, upvoteCount,
                                   upvoters[], imageUrl, createdAt, updatedAt,
                                   history[ {status, note, changedBy, at} ]
campusFacilities/{campus}/facilities/{id}   name, areas[]
```

The role comes from the email domain and is enforced by `firestore.rules`, so a student cannot change a status, give themselves a role, or attach an image link from anywhere except this project's Cloudinary account.

## Run it

```
flutter pub get
flutter run
```

`android/app/google-services.json` and `lib/firebase_options.dart` point at the Firebase project `incident-reporting-app-73901`.

Photos need one **unsigned** Cloudinary upload preset named `cir_uploads` in the `dgxaazbuq` cloud (images only; leave its folder empty, because the app sets `cir/incidents` and `cir/profiles`).

For a fast build to show on a phone use `flutter build apk --release`; the debug build starts slowly.

## Tests

```
flutter analyze
flutter test                                 # 113 Dart tests
cd rules-tests && npm install && npm test    # 54 security-rules tests (needs Java for the emulator)
```

Publish the rules after changing them: `firebase deploy --only firestore:rules --project incident-reporting-app-73901`.
