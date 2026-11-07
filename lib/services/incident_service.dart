import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/cloudinary_config.dart';
import '../models/incident.dart';
import 'image_upload_service.dart';

class IncidentService {
  IncidentService({FirebaseFirestore? firestore, ImageUploader? uploader})
    : _db = firestore ?? FirebaseFirestore.instance,
      _uploader = uploader ?? CloudinaryUploader();

  final FirebaseFirestore _db;
  final ImageUploader _uploader;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) Incident.fromMap(doc.id, doc.data()),
        ],
      );

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
  }) async {
    final ref = _incidents.doc();
    if (photo != null) {
      imageUrl = await _uploader.upload(
        photo,
        folder: CloudinaryConfig.incidentFolder,
      );
    }
    final first = StatusEvent(
      status: 'Submitted',
      note: 'Report submitted',
      changedBy: anonymous ? 'Anonymous' : reporterName,
      at: DateTime.now(),
    );
    await ref.set({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'building': building,
      'status': 'Submitted',
      'reporterId': reporterId,
      'reporterName': anonymous ? '' : reporterName,
      'isAnonymous': anonymous,
      'upvoteCount': 0,
      'upvoters': <String>[],
      'imageUrl': ?imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'history': [first.toMap()],
    });
    return ref.id;
  }

  Future<void> updateStatus({
    required String id,
    required String status,
    required String note,
    required String changedBy,
  }) {
    final event = StatusEvent(
      status: status,
      note: note.trim(),
      changedBy: changedBy,
      at: DateTime.now(),
    );
    return _incidents.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([event.toMap()]),
    });
  }

  // Returns true when the vote was added, false when it was taken back.
  Future<bool> toggleUpvote({required String id, required String uid}) {
    final ref = _incidents.doc(id);
    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      final voters = List<String>.from(
        snapshot.data()?['upvoters'] as List? ?? const [],
      );
      final adding = !voters.contains(uid);
      tx.update(ref, {
        'upvoters': adding
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
        'upvoteCount': FieldValue.increment(adding ? 1 : -1),
      });
      return adding;
    });
  }

  Future<void> delete(String id) => _incidents.doc(id).delete();
}
