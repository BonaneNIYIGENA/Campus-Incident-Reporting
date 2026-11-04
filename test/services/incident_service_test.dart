import 'package:cir/services/incident_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late IncidentService service;

  Future<String> report({bool anonymous = false, String uid = 'u1'}) =>
      service.create(
        title: ' Water leak ',
        description: 'The tap in the second floor bathroom is leaking.',
        category: 'Water',
        building: 'Residence',
        anonymous: anonymous,
        reporterId: uid,
        reporterName: 'Aline Student',
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    service = IncidentService(firestore: db);
  });

  group('create', () {
    test(
      'stores a trimmed report with the starting status and history',
      () async {
        final id = await report();
        final data = (await db.collection('incidents').doc(id).get()).data()!;

        expect(data['title'], 'Water leak');
        expect(data['status'], 'Submitted');
        expect(data['reporterId'], 'u1');
        expect(data['reporterName'], 'Aline Student');
        expect(data['upvoteCount'], 0);
        expect(data['upvoters'], isEmpty);
        expect(data['createdAt'], isNotNull);
        expect(data['history'], hasLength(1));
        expect(data['history'][0]['status'], 'Submitted');
      },
    );

    test('hides the name of anonymous reporters everywhere', () async {
      final id = await report(anonymous: true);
      final data = (await db.collection('incidents').doc(id).get()).data()!;

      expect(data['isAnonymous'], isTrue);
      expect(data['reporterName'], '');
      expect(data['history'][0]['changedBy'], 'Anonymous');
      expect(data.toString().contains('Aline'), isFalse);
    });

    test('keeps the photo url only when one is given', () async {
      final withPhoto = await service.create(
        title: 'Broken chair',
        description: 'The chair in room 4 has a broken leg.',
        category: 'Furniture',
        building: 'Main Campus',
        anonymous: false,
        reporterId: 'u1',
        reporterName: 'Aline',
        imageUrl: 'https://example.com/a.jpg',
      );
      final withoutPhoto = await report();
      final a = (await db.collection('incidents').doc(withPhoto).get()).data()!;
      final b = (await db.collection('incidents').doc(withoutPhoto).get())
          .data()!;
      expect(a['imageUrl'], 'https://example.com/a.jpg');
      expect(b.containsKey('imageUrl'), isFalse);
    });
  });

  group('watchAll', () {
    test('emits reports as models with their history', () async {
      final id = await report();
      final list = await service.watchAll().first;

      expect(list, hasLength(1));
      expect(list.single.id, id);
      expect(list.single.category, 'Water');
      expect(list.single.history.single.status, 'Submitted');
    });

    test('pushes new reports and status changes live', () async {
      final emissions = <List<String>>[];
      final sub = service.watchAll().listen(
        (items) => emissions.add([for (final i in items) i.status]),
      );

      final id = await report();
      await Future<void>.delayed(Duration.zero);
      await service.updateStatus(
        id: id,
        status: 'In Progress',
        note: 'Plumber on the way',
        changedBy: 'Jordan Staff',
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions.last, ['In Progress']);
    });
  });

  group('updateStatus', () {
    test('changes the status and appends to the history', () async {
      final id = await report();
      await service.updateStatus(
        id: id,
        status: 'Resolved',
        note: '  Fixed the pipe  ',
        changedBy: 'Jordan Staff',
      );
      final item = (await service.watchAll().first).single;

      expect(item.status, 'Resolved');
      expect(item.history.map((e) => e.status), ['Submitted', 'Resolved']);
      expect(item.history.last.note, 'Fixed the pipe');
      expect(item.history.last.changedBy, 'Jordan Staff');
    });
  });

  group('toggleUpvote', () {
    test('adds a vote then takes it back', () async {
      final id = await report();

      expect(await service.toggleUpvote(id: id, uid: 'u2'), isTrue);
      var item = (await service.watchAll().first).single;
      expect(item.upvoteCount, 1);
      expect(item.upvoters, ['u2']);

      expect(await service.toggleUpvote(id: id, uid: 'u2'), isFalse);
      item = (await service.watchAll().first).single;
      expect(item.upvoteCount, 0);
      expect(item.upvoters, isEmpty);
    });

    test('counts different voters once each', () async {
      final id = await report();
      await service.toggleUpvote(id: id, uid: 'u2');
      await service.toggleUpvote(id: id, uid: 'u3');
      final item = (await service.watchAll().first).single;
      expect(item.upvoteCount, 2);
      expect(item.upvoters, unorderedEquals(['u2', 'u3']));
    });
  });

  test('delete removes the report', () async {
    final id = await report();
    await service.delete(id);
    expect(await service.watchAll().first, isEmpty);
  });
}
