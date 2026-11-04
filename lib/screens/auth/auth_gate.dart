import 'package:flutter/material.dart';
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

    return switch (roleFromAluEmail(user.email)) {
      UserRole.staff => StaffDashboard(name: user.displayName),
      UserRole.student => StudentDashboard(name: user.displayName),
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

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account and preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline_rounded),
            ),
            title: Text(auth.user?.displayName ?? 'ALU account'),
            subtitle: Text(auth.user?.email ?? ''),
          ),
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
