import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
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
