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
import '../../widgets/splash_screen.dart';
import '../shell/app_shell.dart';
import 'auth_screens.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final String id;
    final Widget page;
    if (auth.initializing) {
      id = 'splash';
      page = const SplashScreen();
    } else if (user == null) {
      id = 'login';
      page = const LoginScreen();
    } else if (!user.emailVerified) {
      id = 'verify';
      page = const VerifyEmailScreen();
    } else {
      final role = auth.activeRole;
      id = 'app-${role?.name}';
      page = role == null
          ? const AccessDeniedScreen()
          : AppShell(key: ValueKey(id), role: role);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(id), child: page),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 42),
            const SizedBox(height: 14),
            Text(
              'This account can’t access Campus Care',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use an approved ALU email address to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _name;
  File? _photo;
  bool _saving = false;
  String? _campus = 'Kigali Campus';
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<AuthProvider>().user?.displayName ?? '',
    );
    _campus = context.read<AuthProvider>().user?.campus == 'Mauritius Campus'
        ? 'Mauritius Campus'
        : 'Kigali Campus';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account and preferences')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: _photo == null ? null : FileImage(_photo!),
                    child: _photo != null
                        ? null
                        : auth.user?.photoUrl == null
                        ? const Icon(Ph.user, size: 40)
                        : ClipOval(
                            child: Image.network(
                              auth.user!.photoUrl!,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Ph.user, size: 40),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Change profile photo',
                      onPressed: () async {
                        final file = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          imageQuality: 75,
                        );
                        if (file != null && mounted) {
                          setState(() => _photo = File(file.path));
                        }
                      },
                      icon: const Icon(Ph.camera, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                labelText: 'Email',
                prefixIcon: Icon(Ph.envelopeSimple, size: 22),
                suffixIcon: Icon(Ph.lockSimple, size: 18),
                enabled: false,
              ),
              child: Text(
                auth.user?.email ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final authProvider = context.read<AuthProvider>();
                      setState(() => _saving = true);
                      final ok = await authProvider.updateProfile(
                        name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                        campus: _campus,
                        photo: _photo,
                      );
                      if (!mounted) return;
                      setState(() => _saving = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Profile saved.'
                                : authProvider.error ??
                                      'Could not save profile.',
                          ),
                        ),
                      );
                      if (ok) setState(() => _photo = null);
                    },
              child: Text(_saving ? 'Saving…' : 'Save profile'),
            ),
            if (auth.user?.isAdmin == true) ...[
              const SizedBox(height: 18),
              Text('View as', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.student,
                    label: Text('Student'),
                    icon: Icon(Ph.user),
                  ),
                  ButtonSegment(
                    value: UserRole.staff,
                    label: Text('Staff'),
                    icon: Icon(Ph.identificationCard),
                  ),
                ],
                selected: {auth.activeRole ?? UserRole.student},
                onSelectionChanged: (selection) {
                  context.read<AuthProvider>().switchView(selection.first);
                },
              ),
            ],
            const SizedBox(height: 18),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {theme.mode},
              onSelectionChanged: (selection) => theme.setMode(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
