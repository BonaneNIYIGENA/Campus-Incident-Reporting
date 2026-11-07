import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/campus_facility.dart';
import '../../providers/facility_provider.dart';
import '../../theme/app_icons.dart';
import '../../utils/campus_locations.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_sheet.dart';

class FacilityManagementScreen extends StatelessWidget {
  const FacilityManagementScreen({super.key, required this.campus});
  final String campus;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FacilityProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('$campus facilities')),
      body: StreamBuilder<List<CampusFacility>>(
        stream: provider.watch(campus),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Facilities could not load. Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final defaults = campusAreas[campus] ?? campusAreas['Kigali Campus']!;
          final byName = <String, CampusFacility>{
            for (final entry in defaults.entries)
              entry.key: CampusFacility(
                id: defaultFacilityId(entry.key),
                name: entry.key,
                areas: entry.value,
              ),
            for (final facility in snapshot.data!) facility.name: facility,
          };
          final items = byName.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _FacilityCard(
              facility: items[index],
              onEdit: () => _edit(context, items[index]),
              onDelete: items[index].id.startsWith('default_')
                  ? null
                  : () => _delete(context, items[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Ph.plusBold, size: 20),
        label: const Text('Add facility'),
      ),
    );
  }

  Future<void> _edit(BuildContext context, CampusFacility? existing) async {
    final result = await showFormSheet<_FacilityResult>(
      context,
      builder: (_) => _FacilityForm(existing: existing),
    );
    if (result == null || !context.mounted) return;
    try {
      await context.read<FacilityProvider>().save(
        campus,
        id: existing?.id,
        name: result.name,
        areas: result.areas,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The facility could not be saved. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, CampusFacility facility) async {
    final yes = await showConfirmSheet(
      context,
      icon: Ph.trash,
      title: 'Delete ${facility.name}?',
      message: 'Students will no longer be able to pick it when they report an issue. Reports already made keep their location.',
      confirmLabel: 'Delete facility',
      cancelLabel: 'Keep it',
    );
    if (yes && context.mounted) {
      await context.read<FacilityProvider>().delete(campus, facility.id);
    }
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.onEdit,
    required this.onDelete,
  });
  final CampusFacility facility;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shown = facility.areas.take(4).toList();
    final more = facility.areas.length - shown.length;
    return Material(
      color: theme.cardTheme.color ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Ph.buildingsFill,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        facility.areas.length == 1
                            ? '1 area'
                            : '${facility.areas.length} areas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${facility.name}',
                  onPressed: onEdit,
                  icon: const Icon(Ph.pencilSimple, size: 22),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete ${facility.name}',
                    onPressed: onDelete,
                    color: const Color(0xFFD7403A),
                    icon: const Icon(Ph.trash, size: 22),
                  ),
              ],
            ),
            if (shown.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in shown) _AreaTag(label: area),
                    if (more > 0) _AreaTag(label: '+$more more'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AreaTag extends StatelessWidget {
  const _AreaTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _FacilityResult {
  const _FacilityResult(this.name, this.areas);
  final String name;
  final List<String> areas;
}

class _FacilityForm extends StatefulWidget {
  const _FacilityForm({this.existing});
  final CampusFacility? existing;

  @override
  State<_FacilityForm> createState() => _FacilityFormState();
}

class _FacilityFormState extends State<_FacilityForm> {
  final _form = GlobalKey<FormState>();
  final _areaKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _name;
  final _area = TextEditingController();
  late final List<String> _areas;
  String? _areasError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _areas = [...?widget.existing?.areas];
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  // Returns false when the typed area is not valid, so the error shows under the field.
  bool _addArea() {
    final value = _area.text.trim();
    if (value.isEmpty) return true;
    if (_areas.length >= Validators.areasMax) {
      setState(() => _areasError = 'Add at most ${Validators.areasMax} areas');
      return false;
    }
    if (_areas.any((a) => a.toLowerCase() == value.toLowerCase())) {
      setState(() => _areasError = 'That area is already in the list');
      return false;
    }
    if (!(_areaKey.currentState?.validate() ?? false)) return false;
    setState(() {
      _areas.add(value);
      _area.clear();
      _areasError = null;
    });
    return true;
  }

  void _save() {
    final nameOk = _form.currentState!.validate();
    if (!_addArea()) return;
    if (_areas.isEmpty) {
      setState(() => _areasError = 'Add at least one area');
      return;
    }
    if (!nameOk) return;
    Navigator.of(context).pop(_FacilityResult(_name.text.trim(), _areas));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final colors = Theme.of(context).colorScheme;
    return FormSheet(
      icon: Ph.buildings,
      title: editing ? 'Edit facility' : 'Add a facility',
      subtitle: 'Students pick from these when they report an issue.',
      primaryLabel: editing ? 'Save changes' : 'Add facility',
      onPrimary: _save,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _name,
              label: 'Facility name',
              icon: Ph.buildings,
              maxLength: Validators.facilityMax,
              inputFormatters: Validators.facilityFormatters,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.facilityName,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _area,
              fieldKey: _areaKey,
              label: 'Add an area',
              hint: 'e.g. Study area',
              icon: Ph.mapPin,
              maxLength: Validators.facilityMax,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[<>{}\\|^~`\n]')),
                LengthLimitingTextInputFormatter(Validators.facilityMax),
              ],
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? null : Validators.areas(v),
              onChanged: (_) {
                if (_areasError != null) setState(() => _areasError = null);
              },
              onSubmitted: (_) => _addArea(),
              suffix: IconButton(
                tooltip: 'Add area',
                onPressed: _addArea,
                icon: const Icon(Ph.plusBold, size: 20),
              ),
            ),
            if (_areasError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: FieldError(_areasError!),
              ),
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _areas.isEmpty
                  ? Text(
                      'No areas yet.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final area in _areas)
                          RemovableChip(
                            label: area,
                            onRemove: () => setState(() => _areas.remove(area)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
