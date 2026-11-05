import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Welcome back',
    subtitle: 'Sign in with your ALU account to continue.',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [Validators.noSpaces],
            validator: Validators.email,
            decoration: const InputDecoration(
              labelText: 'ALU email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: !_visible,
            autofillHints: const [AutofillHints.password],
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required' : null,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _visible ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _AuthAction(
            label: 'Sign in',
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              final success = await context.read<AuthProvider>().signIn(
                _email.text,
                _password.text,
              );
              if (!context.mounted) return;
              if (!success) {
                _showError(context, context.read<AuthProvider>().error);
              }
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => auth.error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      auth.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
              ),
              child: const Text('New to Campus Care? Create an account'),
            ),
          ),
        ],
      ),
    ),
  );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Create your account',
    subtitle: 'Use your ALU address. We’ll send a verification link.',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [Validators.noSpaces],
            validator: Validators.email,
            decoration: const InputDecoration(
              labelText: 'ALU email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: !_visible,
            validator: Validators.password,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: '8+ characters, upper and lower case, and a number',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            validator: (value) =>
                value != _password.text ? 'Passwords don’t match' : null,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 18),
          _AuthAction(
            label: 'Create account',
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              final ok = await context.read<AuthProvider>().signUp(
                _name.text,
                _email.text,
                _password.text,
              );
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account created. We sent a verification link to your email.',
                    ),
                  ),
                );
                Navigator.of(context).pop();
              } else {
                _showError(context, context.read<AuthProvider>().error);
              }
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => auth.error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(auth.error!, textAlign: TextAlign.center),
                  ),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Sign in'),
            ),
          ),
        ],
      ),
    ),
  );
}

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return _AuthLayout(
      title: 'Verify your email',
      subtitle:
          'We sent a verification link to ${auth.user?.email ?? 'your ALU email'}. Open it, then come back here.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 48),
          const SizedBox(height: 18),
          const Text(
            'Check your inbox and spam folder. You can use the app once your ALU email is verified.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await auth.refreshVerification();
              if (context.mounted && auth.user?.emailVerified != true) {
                _showError(
                  context,
                  'Email is not verified yet. Open the verification link first.',
                );
              }
            },
            child: const Text('I’ve verified my email'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              final ok = await context
                  .read<AuthProvider>()
                  .resendCurrentVerification();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Verification email sent again.' : 'Could not send the email. Wait a moment and try again.',
                  ),
                ),
              );
            },
            child: const Text('Resend verification email'),
          ),
          TextButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 26),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthAction extends StatelessWidget {
  const _AuthAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

void _showError(BuildContext context, String? message) {
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
