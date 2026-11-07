import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../providers/facility_provider.dart';
import '../models/campus_facility.dart';
import '../utils/validators.dart';
import '../theme/app_icons.dart';
import '../utils/campus_locations.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_sheet.dart';
import '../widgets/select_field.dart';
import '../widgets/status_roadmap.dart';
import '../widgets/reports_filter.dart';
import '../widgets/incident_card.dart';

const incidentCategories = [
  'Water',
  'Electricity',
  'Facilities',
  'Furniture',
  'Sanitation',
  'Safety',
  'Other',
];
const incidentStatuses = ['Submitted', 'In Progress', 'Resolved', 'Rejected'];

class _FacilityAreaFields extends StatelessWidget {
  const _FacilityAreaFields({
    required this.campus,
    required this.facility,
    required this.area,
    required this.onChanged,
  });
  final String campus;
  final String? facility;
  final String? area;
  final void Function(String?, String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final Stream<List<CampusFacility>> facilityStream;
    try {
      facilityStream = context.read<FacilityProvider>().watch(campus);
    } catch (_) {
      return _fields(context, const <CampusFacility>[], true);
    }
    return StreamBuilder<List<CampusFacility>>(
      stream: facilityStream,
      builder: (context, snapshot) => _fields(
        context,
        snapshot.data ?? const <CampusFacility>[],
        snapshot.hasError,
      ),
    );
  }

  Widget _fields(
    BuildContext context,
    List<CampusFacility> remote,
    bool fallback,
  ) {
    final theme = Theme.of(context);
    final choices = Map<String, List<String>>.from(
      campusAreas[campus] ?? campusAreas['Kigali Campus']!,
    )..addAll({for (final item in remote) item.name: item.areas});
    final facilityValue = choices.containsKey(facility) ? facility : null;
    final areas = choices[facilityValue] ?? const <String>[];
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Ph.mapPin, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Campus: $campus',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SelectField<String>(
          key: ValueKey('facility-$campus'),
          label: 'Facility',
          sheetTitle: 'Choose a facility',
          icon: Ph.buildings,
          value: facilityValue,
          validator: (value) => Validators.required(value, 'Facility'),
          options: [for (final name in choices.keys) SelectOption(name, name)],
          onChanged: (value) => onChanged(value, null),
        ),
        const SizedBox(height: 14),
        SelectField<String>(
          key: ValueKey('area-$campus-$facilityValue'),
          label: 'Specific area',
          sheetTitle: 'Choose an area',
          icon: Ph.mapPin,
          value: areas.contains(area) ? area : null,
          enabled: areas.isNotEmpty,
          hint: areas.isEmpty ? 'Choose a facility first' : null,
          validator: (value) => Validators.required(value, 'Specific area'),
          options: [for (final name in areas) SelectOption(name, name)],
          onChanged: (value) => onChanged(facilityValue, value),
        ),
        if (fallback)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Using the campus default facility list.'),
            ),
          ),
      ],
    );
  }
}

IconData _statusIcon(String status) => switch (status) {
  'In Progress' => Ph.wrench,
  'Resolved' => Ph.checkCircle,
  'Rejected' => Ph.xCircle,
  _ => Ph.tray,
};

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});
  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

String _campusName(BuildContext context) {
  final campus = context.read<AuthProvider>().user?.campus ?? '';
  return campus.isEmpty ? 'Kigali Campus' : campus;
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _category, _facility, _area;
  File? _photo;
  bool _anonymous = false, _picking = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 70,
      );
      if (image == null || !mounted) return;
      final file = File(image.path);
      if (await file.length() > 2 * 1024 * 1024) {
        _message('Photo must be smaller than 2 MB.');
      } else {
        setState(() => _photo = file);
      }
    } catch (_) {
      _message(
        'Could not open your photos. Check app permissions and try again.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    try {
      await context.read<IncidentProvider>().create(
        title: _title.text,
        description: _description.text,
        category: _category!,
        building: '${_campusName(context)} · $_facility · $_area',
        anonymous: _anonymous,
        photo: _photo,
        reporterId: context.read<AuthProvider>().user?.uid ?? 'demo-student',
        reporterName:
            context.read<AuthProvider>().user?.displayName ?? 'Student',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted. You can follow its progress in My reports.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _message(
          context.read<IncidentProvider>().error ??
              'Report could not be submitted. Check your connection and retry.',
        );
      }
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<IncidentProvider>().busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Help us understand what needs attention.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _title,
                  label: 'Short title',
                  hint: 'e.g. Water leak near the library',
                  icon: Ph.textT,
                  maxLength: Validators.titleMax,
                  inputFormatters: Validators.titleFormatters,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: Validators.title,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _description,
                  label: 'What happened?',
                  icon: Ph.textAlignLeft,
                  maxLength: Validators.descriptionMax,
                  inputFormatters: Validators.descriptionFormatters,
                  minLines: 4,
                  maxLines: 7,
                  alignLabelWithHint: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.description,
                ),
                const SizedBox(height: 14),
                SelectField<String>(
                  label: 'Category',
                  sheetTitle: 'What kind of issue is it?',
                  icon: Ph.tag,
                  value: _category,
                  validator: (value) => Validators.required(value, 'Category'),
                  options: [
                    for (final c in incidentCategories) SelectOption(c, c),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 14),
                _FacilityAreaFields(
                  campus:
                      context.watch<AuthProvider>().user?.campus.isNotEmpty ==
                          true
                      ? context.watch<AuthProvider>().user!.campus
                      : 'Kigali Campus',
                  facility: _facility,
                  area: _area,
                  onChanged: (facility, area) => setState(() {
                    _facility = facility;
                    _area = area;
                  }),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _picking ? null : _pickPhoto,
                  icon: _picking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _photo == null
                        ? 'Add a photo (optional)'
                        : 'Choose a different photo',
                  ),
                ),
                if (_photo != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(
                          _photo!,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => _photo = null),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Remove photo',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _anonymous,
                  onChanged: (value) => setState(() => _anonymous = value),
                  title: const Text('Submit anonymously'),
                  subtitle: const Text(
                    'Staff can still see your account for follow-up.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton(
            onPressed: busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit report'),
          ),
        ),
      ),
    );
  }
}

class IncidentListScreen extends StatelessWidget {
  const IncidentListScreen({super.key, required this.staffView});
  final bool staffView;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final currentUid = context.watch<AuthProvider>().user?.uid;
    final items = provider.visibleItems;
    return Scaffold(
      appBar: AppBar(title: Text(staffView ? 'All reports' : 'Campus reports')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ReportsSearchBar(),
          ),
          const ActiveFilters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                items.length == 1 ? '1 report' : '${items.length} reports',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                ? _LoadError(message: provider.error!, onRetry: provider.retry)
                : items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No reports match these filters.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return IncidentCard(
                        incident: item,
                        staffView: staffView,
                        canDelete:
                            !staffView &&
                            item.reporterId == currentUid &&
                            item.status == 'Submitted',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => IncidentDetailScreen(
                              incident: item,
                              staffView: staffView,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incident,
    required this.staffView,
  });
  final Incident incident;
  final bool staffView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<IncidentProvider>();
    final match = provider.items.where((v) => v.id == incident.id);
    final item = match.isEmpty ? incident : match.first;
    final uid = context.watch<AuthProvider>().user?.uid;
    final canDelete =
        !staffView && uid == item.reporterId && item.status == 'Submitted';
    final reporter = item.isAnonymous
        ? 'Anonymous'
        : item.reporterName.isEmpty
        ? 'ALU student'
        : item.reporterName;
    final voted = provider.hasUpvoted(item.id, uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          if (canDelete)
            IconButton(
              tooltip: 'Delete report',
              icon: const Icon(Ph.trash),
              onPressed: () => _confirmDelete(context, item),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              if (item.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: Icon(
                              Ph.image,
                              size: 40,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              StatusRoadmap(incident: item),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(label: 'Issue: ${item.category}'),
                  _MetaChip(icon: Ph.mapPin, label: item.location),
                  _MetaChip(icon: Ph.clock, label: stamp(item.createdAt)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  item.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isAnonymous ? Ph.user : Ph.userCircleFill,
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
                          'Reported by $reporter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.upvoteCount} ${item.upvoteCount == 1 ? 'person finds' : 'people find'} this helpful',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!staffView)
                    _HelpfulButton(
                      voted: voted,
                      disabled: item.reporterId == uid,
                      count: item.upvoteCount,
                      onTap: () => provider.toggleUpvote(item, uid ?? ''),
                    ),
                ],
              ),
              if (staffView) ...[
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _showStatusSheet(context, item),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Ph.pencilSimple, size: 20),
                  label: const Text('Update status'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Incident item) async {
    final yes = await showConfirmSheet(
      context,
      icon: Ph.trash,
      title: 'Delete this report?',
      message: 'It will be removed for everyone and can’t be brought back. Only reports nobody has picked up yet can be deleted.',
      confirmLabel: 'Delete report',
      cancelLabel: 'Keep report',
    );
    if (!yes || !context.mounted) return;
    try {
      await context.read<IncidentProvider>().delete(item);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the report. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _showStatusSheet(BuildContext context, Incident item) async {
    final result = await showFormSheet<({String status, String note})>(
      context,
      builder: (_) => _StatusForm(current: item.status),
    );
    if (result == null || !context.mounted) return;
    try {
      await context.read<IncidentProvider>().updateStatus(
        item,
        result.status,
        result.note,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Status could not be updated. Check staff permissions and retry.',
            ),
          ),
        );
      }
    }
  }
}

class _StatusForm extends StatefulWidget {
  const _StatusForm({required this.current});
  final String current;

  @override
  State<_StatusForm> createState() => _StatusFormState();
}

class _StatusFormState extends State<_StatusForm> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  late String _status = widget.current;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    icon: Ph.pencilSimple,
    title: 'Update report status',
    subtitle: 'The reporter is told about every change.',
    primaryLabel: 'Save',
    onPrimary: () {
      if (_form.currentState!.validate()) {
        Navigator.of(context).pop((status: _status, note: _note.text));
      }
    },
    child: Form(
      key: _form,
      child: Column(
        children: [
          SelectField<String>(
            label: 'Status',
            sheetTitle: 'Set the status',
            icon: Ph.listBullets,
            value: _status,
            options: [
              for (final v in incidentStatuses)
                SelectOption(v, v, icon: _statusIcon(v)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _note,
            label: _status == 'Rejected'
                ? 'Reason for rejecting'
                : 'Update note (optional)',
            icon: Ph.pencilSimple,
            maxLength: Validators.noteMax,
            inputFormatters: Validators.noteFormatters,
            minLines: 2,
            maxLines: 4,
            alignLabelWithHint: true,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) =>
                Validators.updateNote(v, mandatory: _status == 'Rejected'),
          ),
        ],
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({this.icon, required this.label});
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpfulButton extends StatelessWidget {
  const _HelpfulButton({
    required this.voted,
    required this.disabled,
    required this.count,
    required this.onTap,
  });
  final bool voted, disabled;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final on = voted && !disabled;
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? colors.primary : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Ph.thumbsUpFill : Ph.thumbsUp,
                size: 18,
                color: on ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Helpful · $count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: on ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 38),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
