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
import '../../widgets/select_field.dart';
import '../../widgets/user_avatar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  String? _campus;
  File? _photo;
  bool _editing = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _loadFrom(context.read<AuthProvider>().user);
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _loadFrom(AppUser? user) {
    _name.text = user?.displayName ?? '';
    _campus = user?.campus == 'Mauritius Campus'
        ? 'Mauritius Campus'
        : 'Kigali Campus';
    _photo = null;
  }

  bool _changed(AppUser? user) =>
      _photo != null ||
      _name.text.trim() != (user?.displayName ?? '') ||
      _campus !=
          (user?.campus.isEmpty ?? true ? 'Kigali Campus' : user!.campus);

  void _startEditing({bool focusName = false}) {
    setState(() => _editing = true);
    if (focusName) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nameFocus.requestFocus(),
      );
    }
  }

  void _stopEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editing = false;
      _loadFrom(context.read<AuthProvider>().user);
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 75,
    );
    if (file != null && mounted) {
      setState(() {
        _photo = File(file.path);
        _editing = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    final ok = await auth.updateProfile(
      name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      campus: _campus,
      photo: _photo,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _photo = null;
        _editing = false;
      }
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile saved.' : auth.error ?? 'Could not save your profile.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final themeMode = context.watch<ThemeProvider>();
    final role = auth.activeRole;
    final roleLabel = role == UserRole.staff ? 'Staff' : 'Student';
    final changed = _changed(user);
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? colors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Avatar(
                              user: user,
                              photo: _photo,
                              editing: _editing,
                              onPick: _pickPhoto,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _editing
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _RolePill(label: roleLabel),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Edit your profile',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          'Change your photo, name or campus.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _RolePill(label: roleLabel),
                                        const SizedBox(height: 8),
                                        _InfoLine(
                                          text: user?.displayName ?? '',
                                          strong: true,
                                          onEdit: () =>
                                              _startEditing(focusName: true),
                                          tooltip: 'Edit name',
                                        ),
                                        _InfoLine(
                                          icon: Ph.envelopeSimple,
                                          text: user?.email ?? '',
                                          onEdit: () =>
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Your ALU email can’t be changed. It decides whether you are a student or staff.',
                                                      ),
                                                    ),
                                                  ),
                                          tooltip: 'About your email',
                                        ),
                                        _InfoLine(
                                          icon: Ph.mapPin,
                                          text: campus,
                                          onEdit: _startEditing,
                                          tooltip: 'Edit campus',
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 6),
                            _CornerButton(
                              editing: _editing,
                              onTap: _editing ? _stopEditing : _startEditing,
                            ),
                          ],
                        ),
                        if (_editing) ...[
                          const SizedBox(height: 18),
                          Form(
                            key: _form,
                            onChanged: () => setState(() {}),
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: _name,
                                  focusNode: _nameFocus,
                                  label: 'Display name',
                                  icon: Ph.user,
                                  suffix: const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Ph.pencilSimple, size: 18),
                                  ),
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
                                    for (final c in const [
                                      'Kigali Campus',
                                      'Mauritius Campus',
                                    ])
                                      SelectOption(c, c, icon: Ph.mapPin),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _campus = value),
                                ),
                                const SizedBox(height: 14),
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'ALU email',
                                    prefixIcon: const FieldIcon(
                                      Ph.envelopeSimple,
                                    ),
                                    prefixIconConstraints:
                                        const BoxConstraints(),
                                    suffixIcon: const Padding(
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
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _saving || !changed
                                        ? null
                                        : _save,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              key: ValueKey('saving'),
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                          : const Text(
                                              'Save settings',
                                              key: ValueKey('label'),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (user?.isAdmin == true) ...[
                  const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.user,
    required this.photo,
    required this.editing,
    required this.onPick,
  });
  final AppUser? user;
  final File? photo;
  final bool editing;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: photo != null
                ? CircleAvatar(radius: 32, backgroundImage: FileImage(photo!))
                : UserAvatar(user: user, size: 64),
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
                  onTap: onPick,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2.5),
                    ),
                    child: Icon(Ph.camera, size: 15, color: colors.onPrimary),
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

class _CornerButton extends StatelessWidget {
  const _CornerButton({required this.editing, required this.onTap});
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: editing ? 'Cancel editing' : 'Edit profile',
      child: Tooltip(
        message: editing ? 'Cancel editing' : 'Edit profile',
        triggerMode: TooltipTriggerMode.manual,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: editing ? Colors.transparent : colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: editing ? colors.outlineVariant : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  editing ? Ph.xBold : Ph.pencilSimple,
                  size: 16,
                  color: editing ? colors.onSurfaceVariant : colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  editing ? 'Cancel' : 'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: editing ? colors.onSurfaceVariant : colors.primary,
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

// One line of profile info with a small edit icon at its end.
class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.text,
    required this.onEdit,
    required this.tooltip,
    this.icon,
    this.strong = false,
  });
  final String text, tooltip;
  final IconData? icon;
  final bool strong;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: strong
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
            ),
          ),
          Semantics(
            button: true,
            label: tooltip,
            child: Tooltip(
              message: tooltip,
              triggerMode: TooltipTriggerMode.manual,
              child: GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Ph.pencilSimple,
                    size: 16,
                    color: colors.onSurfaceVariant,
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

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ph.sealCheckFill, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.onPrimaryContainer,
            ),
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
