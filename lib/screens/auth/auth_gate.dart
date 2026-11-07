import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/user_role.dart';
import '../staff/staff_dashboard.dart';
import '../student/student_dashboard.dart';
import 'auth_screens.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    if (user == null) return const LoginScreen();
    if (!user.emailVerified) return const VerifyEmailScreen();

    return switch (auth.activeRole) {
      UserRole.staff => StaffDashboard(
        name: user.displayName,
        campus: user.campus,
      ),
      UserRole.student => StudentDashboard(
        name: user.displayName,
        campus: user.campus,
      ),
      null => const AccessDeniedScreen(),
    };
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
  String _campus = 'Kigali Campus';

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
      body: ListView(
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
                      ? const Icon(Icons.person_outline_rounded, size: 40)
                      : ClipOval(
                          child: Image.network(
                            auth.user!.photoUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_outline_rounded,
                              size: 40,
                            ),
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
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _campus,
            decoration: const InputDecoration(labelText: 'Campus'),
            items: const [
              'Kigali Campus',
              'Mauritius Campus',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _campus = value);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(auth.user?.email ?? ''),
          ),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final authProvider = context.read<AuthProvider>();
                    setState(() => _saving = true);
                    final ok = await authProvider.updateProfile(
                      name: _name.text.trim(),
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
                              : authProvider.error ?? 'Could not save profile.',
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
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: UserRole.staff,
                  label: Text('Staff'),
                  icon: Icon(Icons.badge_outlined),
                ),
              ],
              selected: {auth.activeRole ?? UserRole.student},
              onSelectionChanged: (selection) {
                context.read<AuthProvider>().switchView(selection.first);
                Navigator.of(context).pop();
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
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
