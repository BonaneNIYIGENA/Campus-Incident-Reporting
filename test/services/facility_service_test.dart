import 'package:cir/models/campus_facility.dart';
import 'package:cir/services/facility_service.dart';
import 'package:cir/utils/campus_locations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FacilityService service;

  setUp(() => service = FacilityService(firestore: FakeFirebaseFirestore()));

  test('saving creates a facility with its areas for one campus', () async {
    await service.save(
      'Kigali Campus',
      name: ' Library ',
      areas: ['Study area', 'Group rooms'],
    );
    final list = await service.watch('Kigali Campus').first;

    expect(list, hasLength(1));
    expect(list.single.name, 'Library');
    expect(list.single.areas, ['Study area', 'Group rooms']);
  });

  test('campuses keep separate facility lists', () async {
    await service.save('Kigali Campus', name: 'Library', areas: ['Study area']);
    await service.save(
      'Mauritius Campus',
      name: 'Cafeteria',
      areas: ['Dining'],
    );

    final kigali = await service.watch('Kigali Campus').first;
    final mauritius = await service.watch('Mauritius Campus').first;
    expect(kigali.map((f) => f.name), ['Library']);
    expect(mauritius.map((f) => f.name), ['Cafeteria']);
  });

  test('saving with an id edits that facility instead of adding one', () async {
    await service.save(
      'Kigali Campus',
      id: 'lib',
      name: 'Library',
      areas: ['A'],
    );
    await service.save(
      'Kigali Campus',
      id: 'lib',
      name: 'Main Library',
      areas: ['A', 'B'],
    );
    final list = await service.watch('Kigali Campus').first;

    expect(list, hasLength(1));
    expect(list.single.name, 'Main Library');
    expect(list.single.areas, ['A', 'B']);
  });

  test('facilities come back sorted by name', () async {
    await service.save('Kigali Campus', name: 'Residence', areas: []);
    await service.save('Kigali Campus', name: 'Cafeteria', areas: []);
    await service.save('Kigali Campus', name: 'Library', areas: []);
    final list = await service.watch('Kigali Campus').first;
    expect(list.map((f) => f.name), ['Cafeteria', 'Library', 'Residence']);
  });

  test('delete removes a facility', () async {
    await service.save('Kigali Campus', id: 'x', name: 'Library', areas: []);
    await service.delete('Kigali Campus', 'x');
    expect(await service.watch('Kigali Campus').first, isEmpty);
  });

  test('a facility without a name falls back to its id', () {
    final facility = CampusFacility.fromMap('lib', {});
    expect(facility.name, 'lib');
    expect(facility.areas, isEmpty);
  });

  group('default campus areas', () {
    test('both campuses have areas for every facility', () {
      for (final campus in ['Kigali Campus', 'Mauritius Campus']) {
        final facilities = campusAreas[campus]!;
        expect(facilities, isNotEmpty);
        for (final entry in facilities.entries) {
          expect(entry.value, isNotEmpty, reason: '${entry.key} has no areas');
        }
      }
    });

    test('residence electricity is separate from campus electricity', () {
      final kigali = campusAreas['Kigali Campus']!;
      expect(kigali['Residence'], contains('Residence electricity'));
      expect(kigali['Campus facilities'], contains('Campus electricity'));
      expect(kigali['Residence'], isNot(contains('Campus electricity')));
    });

    test('default ids are lowercase with underscores', () {
      expect(
        defaultFacilityId('Campus facilities'),
        'default_campus_facilities',
      );
      expect(defaultFacilityId('Library'), 'default_library');
    });
  });
}
