import 'package:flutter/foundation.dart';

import '../models/campus_facility.dart';
import '../services/facility_service.dart';

class FacilityProvider extends ChangeNotifier {
  FacilityProvider(this._service);
  final FacilityService _service;
  Stream<List<CampusFacility>> watch(String campus) => _service.watch(campus);
  Future<void> save(
    String campus, {
    String? id,
    required String name,
    required List<String> areas,
  }) => _service.save(campus, id: id, name: name, areas: areas);
  Future<void> delete(String campus, String id) => _service.delete(campus, id);
}
