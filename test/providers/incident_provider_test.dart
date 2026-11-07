import 'dart:io';

import 'package:cir/models/app_user.dart';
import 'package:cir/providers/incident_provider.dart';
import 'package:cir/services/incident_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const aline = AppUser(
  uid: 'u1',
  email: 'aline@alustudent.com',
  displayName: 'Aline Student',
  emailVerified: true,
);
const jordan = AppUser(
  uid: 'staff1',
  email: 'jordan@alueducation.com',
  displayName: 'Jordan Staff',
  emailVerified: true,
);

class _BrokenService extends IncidentService {
  _BrokenService() : super(firestore: FakeFirebaseFirestore());

  @override
  Stream<List<Never>> watchAll() => Stream.error(
    FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
  );

  @override
  Future<String> create({
    required String title,
    required String description,
    required String category,
    required String building,
    required bool anonymous,
    required String reporterId,
    required String reporterName,
    File? photo,
    String? imageUrl,
  }) => Future.error(
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
  );
}

void main() {
  late FakeFirebaseFirestore db;
  late IncidentService service;
  late IncidentProvider provider;

  Future<void> submit(String title, {String category = 'Water'}) =>
      provider.create(
        title: title,
        description: 'Description long enough for $title',
        category: category,
        building: 'Library',
        anonymous: false,
        reporterId: aline.uid,
        reporterName: aline.displayName,
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    service = IncidentService(firestore: db);
    provider = IncidentProvider(service);
  });

  tearDown(() => provider.dispose());

  group('binding to the signed in user', () {
    test('unverified or signed out users get no data', () async {
      provider.bind(
        const AppUser(uid: 'x', email: 'x@alustudent.com', displayName: 'X'),
      );
      await pumpEventQueue();
      expect(provider.loading, isFalse);
      expect(provider.items, isEmpty);

      provider.bind(null);
      await pumpEventQueue();
      expect(provider.items, isEmpty);
    });

    test('a verified user sees loading, then the reports', () async {
      await service.create(
        title: 'Seed report',
        description: 'Something is wrong in the library',
        category: 'Safety',
        building: 'Library',
        anonymous: false,
        reporterId: 'other',
        reporterName: 'Other',
      );
      provider.bind(aline);
      expect(provider.loading, isTrue);
      await pumpEventQueue();
      expect(provider.loading, isFalse);
      expect(provider.items.single.title, 'Seed report');
    });

    test('signing out clears the reports', () async {
      provider.bind(aline);
      await submit('Leaking tap');
      await pumpEventQueue();
      expect(provider.items, hasLength(1));

      provider.bind(null);
      await pumpEventQueue();
      expect(provider.items, isEmpty);
    });
  });

  group('creating and updating', () {
    setUp(() async {
      provider.bind(aline);
      await pumpEventQueue();
    });

    test('a new report shows up live and not busy afterwards', () async {
      await submit('Leaking tap');
      await pumpEventQueue();
      expect(provider.busy, isFalse);
      expect(provider.items.single.status, 'Submitted');
      expect(provider.items.single.reporterId, 'u1');
    });

    test(
      'staff status changes record the staff member in the history',
      () async {
        await submit('Leaking tap');
        await pumpEventQueue();
        provider.bind(jordan);
        await pumpEventQueue();

        await provider.updateStatus(
          provider.items.single,
          'In Progress',
          'Plumber booked',
        );
        await pumpEventQueue();

        final item = provider.items.single;
        expect(item.status, 'In Progress');
        expect(item.history.last.changedBy, 'Jordan Staff');
        expect(item.history.last.note, 'Plumber booked');
      },
    );

    test('upvoting toggles and the author cannot vote', () async {
      await submit('Leaking tap');
      await pumpEventQueue();
      final item = provider.items.single;

      await provider.toggleUpvote(item, 'u1');
      await pumpEventQueue();
      expect(provider.items.single.upvoteCount, 0);

      await provider.toggleUpvote(item, 'u2');
      await pumpEventQueue();
      expect(provider.items.single.upvoteCount, 1);
      expect(provider.hasUpvoted(item.id, 'u2'), isTrue);
      expect(provider.hasUpvoted(item.id, 'u3'), isFalse);

      await provider.toggleUpvote(provider.items.single, 'u2');
      await pumpEventQueue();
      expect(provider.items.single.upvoteCount, 0);
    });

    test('delete removes the report', () async {
      await submit('Leaking tap');
      await pumpEventQueue();
      await provider.delete(provider.items.single);
      await pumpEventQueue();
      expect(provider.items, isEmpty);
    });
  });

  group('search and filters', () {
    setUp(() async {
      provider.bind(aline);
      await submit('Leaking tap', category: 'Water');
      await submit('Broken chair', category: 'Furniture');
      await submit('Dark corridor', category: 'Electricity');
      await pumpEventQueue();
      await provider.updateStatus(
        provider.items.firstWhere((i) => i.title == 'Broken chair'),
        'Resolved',
        'Replaced',
      );
      await pumpEventQueue();
    });

    test('shows everything by default', () {
      expect(provider.visibleItems, hasLength(3));
    });

    test('searches the title and building case-insensitively', () {
      provider.setQuery('  CHAIR ');
      expect(provider.visibleItems.single.title, 'Broken chair');
      provider.setQuery('library');
      expect(provider.visibleItems, hasLength(3));
      provider.setQuery('nothing like this');
      expect(provider.visibleItems, isEmpty);
    });

    test('filters by category and status together', () {
      provider.setCategory('Water');
      expect(provider.visibleItems.single.title, 'Leaking tap');

      provider.setCategory('All');
      provider.setStatus('Resolved');
      expect(provider.visibleItems.single.title, 'Broken chair');

      provider.setCategory('Water');
      expect(provider.visibleItems, isEmpty);
    });

    test('changing a filter notifies listeners', () {
      var calls = 0;
      provider.addListener(() => calls++);
      provider.setCategory('Safety');
      provider.setStatus('Rejected');
      provider.setQuery('x');
      expect(calls, 3);
    });
  });

  group('errors', () {
    test('a failing stream becomes a readable error and can retry', () async {
      final broken = IncidentProvider(_BrokenService());
      addTearDown(broken.dispose);
      broken.bind(aline);
      await pumpEventQueue();

      expect(broken.loading, isFalse);
      expect(broken.error, contains('No connection'));

      broken.retry();
      expect(broken.error, isNull);
      expect(broken.loading, isTrue);
    });

    test('a denied write sets the error and rethrows', () async {
      final broken = IncidentProvider(_BrokenService());
      addTearDown(broken.dispose);
      await expectLater(
        broken.create(
          title: 'Leaking tap',
          description: 'Description long enough',
          category: 'Water',
          building: 'Library',
          anonymous: false,
          reporterId: 'u1',
          reporterName: 'Aline',
        ),
        throwsA(isA<FirebaseException>()),
      );
      expect(broken.error, contains('permission'));
      expect(broken.busy, isFalse);
    });
  });
}
