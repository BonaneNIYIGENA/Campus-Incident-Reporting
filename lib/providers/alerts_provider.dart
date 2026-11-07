import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Which alerts the signed-in person has read or deleted. Kept per account on the phone.
class AlertsProvider extends ChangeNotifier {
  String? _uid;
  Set<String> _read = {};
  Set<String> _deleted = {};

  bool isRead(String key) => _read.contains(key);
  bool isDeleted(String key) => _deleted.contains(key);

  Future<void> bind(String? uid) async {
    if (uid == _uid) return;
    _uid = uid;
    _read = {};
    _deleted = {};
    if (uid == null) {
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_uid != uid) return;
    _read = (prefs.getStringList('alerts_read_$uid') ?? const []).toSet();
    _deleted = (prefs.getStringList('alerts_deleted_$uid') ?? const []).toSet();
    notifyListeners();
  }

  void markRead(Iterable<String> keys) {
    _read.addAll(keys);
    _save();
  }

  void delete(String key) {
    _deleted.add(key);
    _save();
  }

  void _save() {
    notifyListeners();
    final uid = _uid;
    if (uid == null) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('alerts_read_$uid', _read.toList());
      prefs.setStringList('alerts_deleted_$uid', _deleted.toList());
    });
  }
}
