import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/validators.dart';
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
const campusLocations = [
  'Main Campus',
  'Kigali Campus',
  'Residence',
  'Library',
  'Cafeteria',
  'Other',
];
const incidentStatuses = [
  'Submitted',
  'Under Review',
  'In Progress',
  'Resolved',
  'Rejected',
];

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});
  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _category, _building;
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
        building: _building!,
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
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.title,
                  decoration: const InputDecoration(
                    labelText: 'Short title',
                    hintText: 'e.g. Water leak near the library',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  minLines: 4,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.description,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  validator: (value) => Validators.required(value, 'Category'),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: incidentCategories
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _building,
                  validator: (value) => Validators.required(value, 'Location'),
                  decoration: const InputDecoration(
                    labelText: 'Campus location',
                  ),
                  items: campusLocations
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) => setState(() => _building = value),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: provider.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search title or location',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: provider.category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                        ),
                        items: ['All', ...incidentCategories]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) provider.setCategory(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: provider.status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items: ['All', ...incidentStatuses]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) provider.setStatus(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
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
    final provider = context.watch<IncidentProvider>();
    final match = provider.items.where((v) => v.id == incident.id);
    final item = match.isEmpty ? incident : match.first;
    final user = context.watch<AuthProvider>().user;
    final uid = user?.uid;
    final canDelete =
        !staffView && uid == item.reporterId && item.status == 'Submitted';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          if (canDelete)
            IconButton(
              tooltip: 'Delete report',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, item),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StatusBadge(status: item.status),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('${item.category} · ${item.building}'),
          const SizedBox(height: 18),
          if (item.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(item.imagePath!),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 90,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          if (!staffView) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: item.reporterId == uid
                    ? null
                    : () => provider.toggleUpvote(item, uid ?? ''),
                icon: Icon(
                  provider.hasUpvoted(item.id, uid ?? '')
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_upward_outlined,
                ),
                label: Text('Helpful · ${item.upvoteCount}'),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Reported by ${item.isAnonymous
                ? 'Anonymous'
                : item.reporterName.isEmpty
                ? 'ALU student'
                : item.reporterName}',
          ),
          const SizedBox(height: 26),
          Text(
            'Status history',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...item.history.map(
            (event) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 12),
              title: Text(event.status),
              subtitle: Text(event.note.isEmpty ? event.changedBy : event.note),
              trailing: Text(
                '${event.at.day}/${event.at.month}/${event.at.year}',
              ),
            ),
          ),
          if (staffView) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _showStatusDialog(context, item),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update status'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Incident item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep report'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
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

  Future<void> _showStatusDialog(BuildContext context, Incident item) async {
    String status = item.status;
    final note = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update report status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                items: incidentStatuses
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => status = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Update note'),
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
      ),
    );
    if (result != true || !context.mounted) return;
    if (status == 'Rejected' && note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a note when rejecting a report.')),
      );
      return;
    }
    try {
      await context.read<IncidentProvider>().updateStatus(
        item,
        status,
        note.text,
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
