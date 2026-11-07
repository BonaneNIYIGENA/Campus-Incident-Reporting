import 'package:cir/main.dart';
import 'package:cir/models/incident.dart';
import 'package:cir/widgets/floating_nav.dart';
import 'package:cir/widgets/notifications_sheet.dart';
import 'package:cir/widgets/reports_filter.dart';
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
    firestore: db,
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

    await tester.tap(find.byTooltip('Records'));
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
    await tester.tap(find.byTooltip('Report'));
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
    Future<void> choose(String field, String option) async {
      await tester.ensureVisible(find.text(field).last);
      await tester.tap(find.text(field).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await choose('Category', 'Facilities');
    await choose('Facility', 'Classrooms');
    await choose('Specific area', 'Room 101');
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
    await tester.tap(find.text('Status').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final doc = (await db.collection('incidents').get()).docs.single.data();
    expect(doc['status'], 'Resolved');
    expect(doc['history'], hasLength(2));
    expect(doc['history'][1]['changedBy'], 'Jordan Staff');
    expect(find.text('Progress'), findsOneWidget);
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
    await tester.tap(find.byTooltip('Records'));
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
    expect(find.byTooltip('Report'), findsNothing);
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

  testWidgets('log out is always in the nav bar and asks first', (
    tester,
  ) async {
    await tester.pumpWidget(await app(user: student()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Log out'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
    expect(find.text('Aline'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets(
    'every nav item shows its name and the Report button is centred',
    (tester) async {
      await tester.pumpWidget(await app(user: student()));
      await tester.pumpAndSettle();
      for (final name in ['Home', 'Records', 'Report', 'Account', 'Log out']) {
        expect(
          find.descendant(
            of: find.byType(FloatingNavBar),
            matching: find.text(name),
          ),
          findsOneWidget,
          reason: '$name label',
        );
      }
      expect(find.byTooltip('Campus'), findsNothing);
      final bar = tester.getRect(find.byType(FloatingNavBar));
      final report = tester.getCenter(find.byTooltip('Report'));
      expect((report.dx - bar.center.dx).abs() < 2, isTrue);
    },
  );

  test('reports saved with a blank campus show a clean location', () {
    final incident = Incident.fromMap('r1', {
      'building': ' · Library · Restrooms',
      'title': 'Tap',
    });
    expect(incident.location, 'Library · Restrooms');
    expect(
      Incident.fromMap('r2', {'building': 'Kigali Campus · Library'}).location,
      'Kigali Campus · Library',
    );
  });

  group('forms', () {
    Future<void> openSignUp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
    }

    testWidgets('each problem shows under its own field', (tester) async {
      await openSignUp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'A');
      await tester.enterText(fields.at(1), 'x@gmail.com');
      await tester.enterText(fields.at(2), 'abc');
      await tester.enterText(fields.at(3), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Enter at least 2 letters'), findsOneWidget);
      expect(
        find.text('Use your @alueducation.com or @alustudent.com email'),
        findsOneWidget,
      );
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords don’t match'), findsOneWidget);
    });

    testWidgets('characters a field does not allow cannot be typed', (
      tester,
    ) async {
      await openSignUp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jean3 Paul<>');
      await tester.enterText(fields.at(1), 'a b@alustudent.com');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'Jean Paul',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'ab@alustudent.com',
      );

      await tester.enterText(fields.at(0), 'a' * 80);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(0))
            .controller!
            .text
            .length,
        50,
      );
    });

    testWidgets('the password meter and checklist follow what is typed', (
      tester,
    ) async {
      await openSignUp(tester);
      final password = find.byType(TextFormField).at(2);
      await tester.enterText(password, 'abc');
      await tester.pumpAndSettle();
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('An uppercase letter'), findsOneWidget);

      await tester.enterText(password, 'Abcdefg1');
      await tester.pumpAndSettle();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('forgot password checks the email before sending', (
      tester,
    ) async {
      await tester.pumpWidget(await app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'aline@alustudent.com',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('reset link'), findsOneWidget);
    });

    testWidgets('reports can be filtered from the filter sheet', (
      tester,
    ) async {
      await seed('Leaking tap in the gym');
      await seed('Broken lamp in hallway');
      final id = (await db.collection('incidents').get()).docs
          .firstWhere((d) => d.data()['title'] == 'Broken lamp in hallway')
          .id;
      await incidents.updateStatus(
        id: id,
        status: 'Resolved',
        note: 'Fixed',
        changedBy: 'Jordan Staff',
      );
      await tester.pumpWidget(await app(user: student()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Records'));
      await tester.pumpAndSettle();
      expect(find.text('2 reports'), findsOneWidget);

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Filter reports'), findsOneWidget);
      await tester.tap(find.text('Resolved').last);
      await tester.pumpAndSettle();
      expect(find.text('Show 1 report'), findsOneWidget);
      await tester.tap(find.text('Show 1 report'));
      await tester.pumpAndSettle();

      expect(find.text('Broken lamp in hallway'), findsOneWidget);
      expect(find.text('Leaking tap in the gym'), findsNothing);
      expect(find.text('1 report'), findsOneWidget);

      // The filter shows as a chip and can be removed again.
      await tester.tap(
        find.descendant(
          of: find.byType(ActiveFilters),
          matching: find.text('Resolved'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 reports'), findsOneWidget);
    });
  });

  group('report details and sheets', () {
    testWidgets('the roadmap greys unreached steps and names who did each', (
      tester,
    ) async {
      await seed('Leaking tap in the gym');
      final id = (await db.collection('incidents').get()).docs.single.id;
      await incidents.updateStatus(
        id: id,
        status: 'In Progress',
        note: 'Plumber booked for Monday',
        changedBy: 'Jordan Staff',
      );
      await tester.pumpWidget(await app(user: student()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Records'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leaking tap in the gym'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Progress'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Reported by Someone'), findsWidgets);
      expect(find.text('Taken on by Jordan Staff'), findsOneWidget);
      expect(find.text('Plumber booked for Monday'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Not reached yet'), findsOneWidget);
      expect(find.text('Resolved'), findsWidgets);
    });

    testWidgets('a resolved report shows who resolved it', (tester) async {
      await seed('Broken lamp in hallway');
      final id = (await db.collection('incidents').get()).docs.single.id;
      await incidents.updateStatus(
        id: id,
        status: 'Resolved',
        note: 'Bulb replaced',
        changedBy: 'Jordan Staff',
      );
      await tester.pumpWidget(await app(user: student()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Records'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Broken lamp in hallway'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Progress'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Resolved by Jordan Staff'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Not reached yet'), findsNothing);
    });

    testWidgets('staff add a facility in the sheet, with areas as chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await app(user: staff()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Facilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add facility'));
      await tester.pumpAndSettle();
      expect(find.text('Add a facility'), findsOneWidget);

      // Saving with nothing filled in explains what is missing.
      await tester.tap(find.text('Add facility').last);
      await tester.pumpAndSettle();
      expect(find.text('Facility name is required'), findsOneWidget);
      expect(find.text('Add at least one area'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sports Hall');
      await tester.enterText(fields.at(1), 'Court A');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'Court B');
      await tester.tap(find.byTooltip('Add area'));
      await tester.pumpAndSettle();
      expect(find.text('Court A'), findsOneWidget);
      expect(find.text('Court B'), findsOneWidget);

      await tester.tap(find.text('Add facility').last);
      await tester.pumpAndSettle();
      final saved = await db
          .collection('campusFacilities')
          .doc('Kigali Campus')
          .collection('facilities')
          .get();
      expect(saved.docs.single.data()['name'], 'Sports Hall');
      expect(saved.docs.single.data()['areas'], ['Court A', 'Court B']);
    });

    testWidgets('the staff alerts panel fits a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await seed('Leaking tap in the gym');
      await seed('Broken lamp in hallway');
      await tester.pumpWidget(await app(user: staff()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Alerts'));
      await tester.pumpAndSettle();
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('2 new'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
