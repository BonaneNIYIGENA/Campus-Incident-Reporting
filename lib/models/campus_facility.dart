class CampusFacility {
  const CampusFacility({
    required this.id,
    required this.name,
    required this.areas,
  });
  final String id;
  final String name;
  final List<String> areas;

  factory CampusFacility.fromMap(String id, Map<String, dynamic> map) =>
      CampusFacility(
        id: id,
        name: map['name'] as String? ?? id,
        areas: List<String>.from(map['areas'] as List? ?? const []),
      );
}
