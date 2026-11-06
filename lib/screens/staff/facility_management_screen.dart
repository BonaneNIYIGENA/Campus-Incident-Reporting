import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campus_facility.dart';
import '../../providers/facility_provider.dart';
import '../../utils/campus_locations.dart';

class FacilityManagementScreen extends StatelessWidget {
  const FacilityManagementScreen({super.key, required this.campus});
  final String campus;

  @override
  Widget build(BuildContext context) {
    final facilityProvider = context.read<FacilityProvider>();
    final facilities = facilityProvider.watch(campus);
    return Scaffold(
      appBar: AppBar(title: Text('$campus facilities')),
      body: StreamBuilder<List<CampusFacility>>(
        stream: facilities,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Facilities could not load: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stored = snapshot.data!;
          final defaults = campusAreas[campus] ?? campusAreas['Kigali Campus']!;
          final byName = <String, CampusFacility>{
            for (final entry in defaults.entries)
              entry.key: CampusFacility(
                id: defaultFacilityId(entry.key),
                name: entry.key,
                areas: entry.value,
              ),
            for (final facility in stored) facility.name: facility,
          };
          final items = byName.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return items.isEmpty
              ? const Center(
                  child: Text(
                    'No custom facilities yet. Add one to manage report locations.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final facility = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(facility.name),
                        subtitle: Text(facility.areas.join(' · ')),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await _edit(context, facility);
                            }
                            if (action == 'delete' &&
                                !facility.id.startsWith('default_')) {
                              await facilityProvider.delete(
                                campus,
                                facility.id,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (!facility.id.startsWith('default_'))
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add facility'),
      ),
    );
  }

  Future<void> _edit(BuildContext context, CampusFacility? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final areas = TextEditingController(text: existing?.areas.join('\n') ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add facility' : 'Edit facility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Facility name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: areas,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Areas (one per line)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted && name.text.trim().isNotEmpty) {
      final areaList = areas.text
          .split('\n')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList();
      await context.read<FacilityProvider>().save(
        campus,
        id: existing?.id,
        name: name.text,
        areas: areaList,
      );
    }
    name.dispose();
    areas.dispose();
  }
}
