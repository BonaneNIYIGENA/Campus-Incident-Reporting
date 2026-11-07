import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Which alerts the signed-in person has read or deleted. Stored in the database under their
// account, so it is the same after a restart or on another phone.
class AlertsProvider extends ChangeNotifier {
  AlertsProvider({this.firestore});

  final FirebaseFirestore? firestore;
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Set<String> _storedRead = {}, _storedDeleted = {};
  // Changes made in this session show straight away, even before the database confirms them.
  final _localRead = <String>{}, _localDeleted = <String>{};

  bool isRead(String key) =>
      _storedRead.contains(key) || _localRead.contains(key);
  bool isDeleted(String key) =>
      _storedDeleted.contains(key) || _localDeleted.contains(key);

  CollectionReference<Map<String, dynamic>> get _states =>
      _db.collection('users').doc(_uid).collection('alertStates');

  void bind(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _storedRead = {};
    _storedDeleted = {};
    _localRead.clear();
    _localDeleted.clear();
    if (uid == null) return;
    _sub = _states.snapshots().listen((snapshot) {
      _storedRead = {
        for (final doc in snapshot.docs)
          if (doc.data()['read'] == true) doc.id,
      };
      _storedDeleted = {
        for (final doc in snapshot.docs)
          if (doc.data()['deleted'] == true) doc.id,
      };
      notifyListeners();
    }, onError: (_) {});
  }

  void markRead(Iterable<String> keys) {
    final fresh = keys.where((key) => !isRead(key)).toList();
    if (fresh.isEmpty) return;
    _localRead.addAll(fresh);
    notifyListeners();
    for (final key in fresh) {
      _write(key, {'read': true});
    }
  }

  void delete(String key) {
    _localDeleted.add(key);
    _localRead.add(key);
    notifyListeners();
    _write(key, {'read': true, 'deleted': true});
  }

  void _write(String key, Map<String, dynamic> fields) {
    if (_uid == null) return;
    _states
        .doc(key)
        .set({
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
