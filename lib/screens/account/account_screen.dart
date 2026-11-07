import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_icons.dart';
import '../../utils/user_role.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_sheet.dart';
import '../../widgets/select_field.dart';
import '../../widgets/user_avatar.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final themeMode = context.watch<ThemeProvider>();
    final role = auth.activeRole;
    final roleLabel = role == UserRole.staff ? 'Staff' : 'Student';
    final campus = (user?.campus ?? '').isEmpty
        ? 'Kigali Campus'
        : user!.campus;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                Text(
                  'Account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _ProfileHeader(
                  user: user,
                  roleLabel: roleLabel,
                  campus: campus,
                  onEdit: () => showFormSheet<void>(
                    context,
                    builder: (_) => const _EditProfileSheet(),
                  ),
                ),
                if (user?.isAdmin == true) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('View the app as'),
                  _Panel(
                    child: Row(
                      children: [
                        Expanded(
                          child: _ChoiceTile(
                            icon: Ph.graduationCap,
                            label: 'Student',
                            selected: role != UserRole.staff,
                            onTap: () => auth.switchView(UserRole.student),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChoiceTile(
                            icon: Ph.identificationCard,
                            label: 'Staff',
                            selected: role == UserRole.staff,
                            onTap: () => auth.switchView(UserRole.staff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const _SectionTitle('Appearance'),
                _Panel(
                  child: Row(
                    children: [
                      for (final (mode, label, icon) in const [
                        (ThemeMode.system, 'System', Ph.circleHalf),
                        (ThemeMode.light, 'Light', Ph.sun),
                        (ThemeMode.dark, 'Dark', Ph.moon),
                      ]) ...[
                        Expanded(
                          child: _ChoiceTile(
                            icon: icon,
                            label: label,
                            selected: themeMode.mode == mode,
                            onTap: () => themeMode.setMode(mode),
                          ),
                        ),
                        if (mode != ThemeMode.dark) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Campus Incident Reporting · African Leadership University',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The profile card: photo, name, email, role and campus, with one edit icon in the corner.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.roleLabel,
    required this.campus,
    required this.onEdit,
  });
  final AppUser? user;
  final String roleLabel, campus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF14261C), const Color(0xFF0E1511)]
              : [const Color(0xFFE4F4EA), const Color(0xFFF3FAF6)],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2.5),
                ),
                child: UserAvatar(user: user, size: 88),
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _Pill(icon: Ph.sealCheckFill, label: roleLabel),
                  _Pill(icon: Ph.mapPin, label: campus),
                ],
              ),
            ],
          ),
          Positioned(
            right: -6,
            top: -8,
            child: Semantics(
              button: true,
              label: 'Edit profile',
              child: Tooltip(
                message: 'Edit profile',
                triggerMode: TooltipTriggerMode.manual,
                child: GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: .9),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(
                      Ph.pencilSimple,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The photo, name and campus are edited here, in the same sheet style as every other form.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _campus;
  File? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.displayName ?? '');
    _campus = user?.campus == 'Mauritius Campus'
        ? 'Mauritius Campus'
        : 'Kigali Campus';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _changed {
    final user = context.read<AuthProvider>().user;
    final saved = (user?.campus ?? '').isEmpty ? 'Kigali Campus' : user!.campus;
    return _photo != null ||
        _name.text.trim() != (user?.displayName ?? '') ||
        _campus != saved;
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 75,
    );
    if (file != null && mounted) setState(() => _photo = File(file.path));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    final ok = await auth.updateProfile(
      name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      campus: _campus,
      photo: _photo,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile saved.' : auth.error ?? 'Could not save your profile.',
        ),
      ),
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    return FormSheet(
      icon: Ph.pencilSimple,
      title: 'Edit profile',
      subtitle: 'Change your photo, name or campus.',
      primaryLabel: _saving ? 'Saving…' : 'Save settings',
      busy: _saving,
      onPrimary: _changed ? _save : null,
      child: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                    child: _photo != null
                        ? CircleAvatar(
                            radius: 38,
                            backgroundImage: FileImage(_photo!),
                          )
                        : UserAvatar(user: user, size: 76),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Semantics(
                      button: true,
                      label: 'Change profile photo',
                      child: Tooltip(
                        message: 'Change profile photo',
                        triggerMode: TooltipTriggerMode.manual,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              Ph.camera,
                              size: 16,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _name,
              label: 'Display name',
              icon: Ph.user,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: Validators.nameMax,
              inputFormatters: Validators.nameFormatters,
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            SelectField<String>(
              label: 'Campus',
              sheetTitle: 'Choose your campus',
              icon: Ph.buildings,
              value: _campus,
              options: [
                for (final c in const ['Kigali Campus', 'Mauritius Campus'])
                  SelectOption(c, c, icon: Ph.mapPin),
              ],
              onChanged: (value) => setState(() => _campus = value),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'ALU email',
                prefixIcon: FieldIcon(Ph.envelopeSimple),
                prefixIconConstraints: BoxConstraints(),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Ph.lockSimple, size: 18),
                ),
                enabled: false,
              ),
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  user?.email ?? '',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
