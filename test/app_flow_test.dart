import 'package:cir/main.dart';
import 'package:cir/widgets/floating_nav.dart';
import 'package:cir/widgets/notifications_sheet.dart';
import 'package:cir/widgets/splash_screen.dart';
import 'package:cir/services/auth_service.dart';
import 'package:cir/services/incident_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late FakeFirebaseFirestore db;
late IncidentService incidents;

Future<Widget> app({MockUser? user, MockFirebaseAuth? auth}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (user != null) {
    await db.collection('users').doc(user.uid).set({
      'role': user.email == 'jordan@alueducation.com' ? 'staff' : 'student',
      'campus': 'Kigali Campus',
      'name': user.displayName ?? 'Student',
      'email': user.email ?? '',
    });
  }
  return CirApp(
    preferences: prefs,
    authService: AuthService(
      auth:
          auth ??
          MockFirebaseAuth(
            signedIn: user != null,
            mockUser: user,
            verifyEmailAutomatically: false,
          ),
      firestore: db,
    ),
    incidentService: incidents,
  );
}

MockUser student({bool verified = true}) => MockUser(
  uid: 'student1',
  email: 'aline@alustudent.com',
  displayName: 'Aline Student',
  isEmailVerified: verified,
);

MockUser staff() => MockUser(
  uid: 'staff1',
  email: 'jordan@alueducation.com',
  displayName: 'Jordan Staff',
  isEmailVerified: true,
);

Future<void> seed(String title, {String uid = 'other'}) => incidents.create(
  title: title,
  description: 'Description for $title that is long enough',
  category: 'Water',
  building: 'Residence',
  anonymous: false,
  reporterId: uid,
  reporterName: 'Someone',
);

void main() {
  setUp(() {
    db = FakeFirebaseFirestore();
    incidents = IncidentService(firestore: db);
  });

  testWidgets('signed out users land on the login screen', (tester) async {
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Student view'), findsNothing);
  });

  testWidgets('login rejects a non ALU email before calling Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'eve@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Campus1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use your @alueducation.com or @alustudent.com email'),
      findsOneWidget,
    );
  });

  testWidgets('spaces typed into the email field are dropped', (tester) async {
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'b. niyigena@alustudent.com ',
    );
    await tester.pump();
    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(field.controller!.text, 'b.niyigena@alustudent.com');
  });

  testWidgets('an unverified account is held on the verify screen', (
    tester,
  ) async {
    await tester.pumpWidget(await app(user: student(verified: false)));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('aline@alustudent.com'), findsWidgets);

    await tester.tap(find.text('I’ve verified my email'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('not verified yet'), findsOneWidget);
  });

  testWidgets('a verified student sees the dashboard and live reports', (
    tester,
  ) async {
    await seed('Light out near the library');
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    expect(find.text('Aline'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await tester.tap(find.byTooltip('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Campus reports'), findsOneWidget);
    expect(find.text('Light out near the library'), findsOneWidget);
    // The nav bar stays on screen when a tab changes.
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await seed('Broken chair in room 4');
    await tester.pumpAndSettle();
    expect(find.text('Broken chair in room 4'), findsOneWidget);
  });

  testWidgets('a student submits a report and it is saved to Firestore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New report'));
    await tester.pumpAndSettle();
    // The nav bar is still there on the report form.
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Title must be at least 5 characters'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Damaged lamp near library',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'The lamp beside the library entrance has stopped working.',
    );
    await tester.tap(find.text('Category').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Facilities').last);
    await tester.pumpAndSettle();
    final facilityField = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).at(1),
    );
    facilityField.onChanged!('Classrooms');
    await tester.pumpAndSettle();
    final areaField = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).at(2),
    );
    areaField.onChanged!('Room 101');
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    final saved = await db.collection('incidents').get();
    expect(saved.docs, hasLength(1));
    final data = saved.docs.single.data();
    expect(data['title'], 'Damaged lamp near library');
    expect(data['reporterId'], 'student1');
    expect(data['status'], 'Submitted');
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Damaged lamp near library'), findsOneWidget);
  });

  testWidgets('staff update a status and the history grows', (tester) async {
    await seed('Water pressure is low in Residence B');
    await tester.pumpWidget(await app(user: staff()));
    await tester.pumpAndSettle();
    expect(find.text('Staff overview'), findsOneWidget);

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water pressure is low in Residence B'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update status'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final doc = (await db.collection('incidents').get()).docs.single.data();
    expect(doc['status'], 'Resolved');
    expect(doc['history'], hasLength(2));
    expect(doc['history'][1]['changedBy'], 'Jordan Staff');
    expect(find.text('Status history'), findsOneWidget);
  });

  testWidgets('students never see the staff dashboard', (tester) async {
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    expect(find.text('Staff overview'), findsNothing);
    expect(find.text('Update status'), findsNothing);
  });

  testWidgets('alerts open as a popup and the nav bar stays visible', (
    tester,
  ) async {
    await seed('Broken tap in the gym', uid: 'student1');
    final id = (await db.collection('incidents').get()).docs.single.id;
    await incidents.updateStatus(
      id: id,
      status: 'In Progress',
      note: 'A plumber is on the way',
      changedBy: 'Jordan Staff',
    );
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Alerts'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPanel), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(
      find.text('Broken tap in the gym is now In Progress'),
      findsOneWidget,
    );
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await tester.tap(find.text('Broken tap in the gym is now In Progress'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPanel), findsNothing);
    expect(find.text('Report details'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('the nav bar shows on report details and tabs switch', (
    tester,
  ) async {
    await seed('Light out near the library');
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light out near the library'));
    await tester.pumpAndSettle();
    expect(find.text('Report details'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Report details'), findsNothing);
    expect(find.text('Account and preferences'), findsOneWidget);
  });

  testWidgets('staff get the facilities tab and no new report button', (
    tester,
  ) async {
    await tester.pumpWidget(await app(user: staff()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Facilities'), findsOneWidget);
    expect(find.byTooltip('New report'), findsNothing);
  });

  testWidgets('the splash shows the logo and a spinner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('swipe right marks an alert read and swipe left deletes it', (
    tester,
  ) async {
    await seed('Broken tap in the gym', uid: 'student1');
    final id = (await db.collection('incidents').get()).docs.single.id;
    await incidents.updateStatus(
      id: id,
      status: 'In Progress',
      note: 'A plumber is on the way',
      changedBy: 'Jordan Staff',
    );
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('1 new'), findsOneWidget);

    final tile = find.text('Broken tap in the gym is now In Progress');
    await tester.drag(tile, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(tile, findsOneWidget);
    expect(find.text('1 new'), findsNothing);

    await tester.drag(tile, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(tile, findsNothing);
    expect(find.textContaining('all caught up'), findsOneWidget);
  });

  testWidgets('log out appears in the nav bar on the account tab only', (
    tester,
  ) async {
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Log out'), findsNothing);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Log out'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
