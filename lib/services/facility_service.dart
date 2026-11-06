import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campus_facility.dart';

class FacilityService {
  FacilityService({FirebaseFirestore? firestore}) : _providedDb = firestore;
  final FirebaseFirestore? _providedDb;
  FirebaseFirestore get _db => _providedDb ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _facilities(String campus) =>
      _db.collection('campusFacilities').doc(campus).collection('facilities');

  Stream<List<CampusFacility>> watch(String campus) =>
      _facilities(campus)
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => CampusFacility.fromMap(doc.id, doc.data()))
                .toList(),
          );

  Future<void> save(
    String campus, {
    String? id,
    required String name,
    required List<String> areas,
  }) async {
    final ref = id == null
        ? _facilities(campus).doc()
        : _facilities(campus).doc(id);
    await ref.set({
      'name': name.trim(),
      'areas': areas,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String campus, String id) =>
      _facilities(campus).doc(id).delete();
}
