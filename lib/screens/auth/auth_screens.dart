import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_icons.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/select_field.dart';

const _campuses = ['Kigali Campus', 'Mauritius Campus'];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    await context.read<AuthProvider>().signIn(_email.text, _password.text);
  }

  Future<void> _forgotPassword() async {
    // Only the email has to be right to send a reset link.
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthProvider>().sendPasswordReset(
      _email.text,
    );
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, a reset link is on its way.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    title: 'Welcome back',
    subtitle: 'Sign in with your ALU account to continue.',
    footer: _SwitchLine(
      question: 'New to Campus Incident Reporting?',
      action: 'Create an account',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen())),
    ),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _email,
            fieldKey: _emailKey,
            label: 'ALU email',
            hint: 'name@alustudent.com',
            icon: Ph.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: Validators.emailFormatters,
            validator: Validators.email,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _password,
            label: 'Password',
            icon: Ph.lock,
            obscureText: !_visible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            inputFormatters: Validators.passwordFormatters,
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password' : null,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            onSubmitted: (_) => _signIn(),
            suffix: _VisibilityToggle(
              visible: _visible,
              onTap: () => setState(() => _visible = !_visible),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const _ErrorBanner(),
          const SizedBox(height: 6),
          _PrimaryButton(label: 'Sign in', onPressed: _signIn),
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
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  bool _visible = false, _confirmVisible = false;
  String? _campus = 'Kigali Campus';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await auth.signUp(
      _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      _email.text,
      _password.text,
      campus: _campus ?? 'Kigali Campus',
    );
    if (!mounted || !ok) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Account created. We sent a verification link to your email.',
        ),
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    title: 'Create your account',
    subtitle: 'Use your ALU address. We’ll send a verification link.',
    footer: _SwitchLine(
      question: 'Already have an account?',
      action: 'Sign in',
      onTap: () => Navigator.of(context).pop(),
    ),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: 'Full name',
            icon: Ph.user,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            maxLength: Validators.nameMax,
            inputFormatters: Validators.nameFormatters,
            validator: Validators.name,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _email,
            label: 'ALU email',
            hint: 'name@alustudent.com',
            icon: Ph.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: Validators.emailFormatters,
            validator: Validators.email,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
          ),
          const SizedBox(height: 16),
          SelectField<String>(
            label: 'Your campus',
            sheetTitle: 'Choose your campus',
            icon: Ph.buildings,
            value: _campus,
            validator: (value) => Validators.required(value, 'Campus'),
            options: [
              for (final c in _campuses) SelectOption(c, c, icon: Ph.mapPin),
            ],
            onChanged: (value) => setState(() => _campus = value),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _password,
            label: 'Password',
            icon: Ph.lock,
            obscureText: !_visible,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            maxLength: Validators.passwordMax,
            inputFormatters: Validators.passwordFormatters,
            validator: Validators.password,
            onChanged: (_) {
              setState(() {});
              // The confirmation has to be checked again against the new password.
              if (_confirm.text.isNotEmpty) {
                _confirmKey.currentState?.validate();
              }
            },
            suffix: _VisibilityToggle(
              visible: _visible,
              onTap: () => setState(() => _visible = !_visible),
            ),
          ),
          _PasswordStrength(password: _password.text),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirm,
            fieldKey: _confirmKey,
            label: 'Confirm password',
            icon: Ph.lockKey,
            obscureText: !_confirmVisible,
            textInputAction: TextInputAction.done,
            maxLength: Validators.passwordMax,
            inputFormatters: Validators.passwordFormatters,
            validator: (value) =>
                Validators.confirmPassword(value, _password.text),
            onSubmitted: (_) => _submit(),
            suffix: _VisibilityToggle(
              visible: _confirmVisible,
              onTap: () => setState(() => _confirmVisible = !_confirmVisible),
            ),
          ),
          const SizedBox(height: 14),
          const _ErrorBanner(),
          const SizedBox(height: 6),
          _PrimaryButton(label: 'Create account', onPressed: _submit),
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
    final theme = Theme.of(context);
    return _AuthShell(
      title: 'Verify your email',
      subtitle:
          'We sent a verification link to ${auth.user?.email ?? 'your ALU email'}. Open it, then come back here.',
      footer: TextButton(
        onPressed: () => context.read<AuthProvider>().signOut(),
        child: const Text('Sign out'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Ph.envelopeSimpleFill,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Check your inbox and spam folder. You can use the app once your ALU email is verified.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          _PrimaryButton(
            label: 'I’ve verified my email',
            onPressed: () async {
              await auth.refreshVerification();
              if (context.mounted && auth.user?.emailVerified != true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Email is not verified yet. Open the verification link first.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
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
        ],
      ),
    );
  }
}

// The page frame: soft colour behind the content and a staggered entrance.
class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });
  final String title, subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: _Glow(
              color: colors.primary.withValues(alpha: .16),
              size: 380,
            ),
          ),
          Positioned(
            top: 260,
            left: -170,
            child: _Glow(
              color: colors.primary.withValues(alpha: .07),
              size: 340,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Reveal(
                        order: 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 60,
                              height: 60,
                              semanticLabel: 'ALU',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Reveal(
                        order: 1,
                        child: Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Reveal(
                        order: 2,
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Reveal(order: 3, child: child),
                      if (footer != null) ...[
                        const SizedBox(height: 18),
                        _Reveal(order: 4, child: Center(child: footer)),
                      ],
                    ],
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

// Each piece of the page rises into place a little after the one before it.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 380 + order * 90),
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
    ),
    child: child,
  );
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: visible ? 'Hide password' : 'Show password',
    onPressed: onTap,
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        visible ? Ph.eyeSlash : Ph.eye,
        key: ValueKey(visible),
        size: 22,
      ),
    ),
  );
}

// Shows what is still missing from a password while it is being typed.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = Validators.passwordScore(password);
    final color = switch (score) {
      0 || 1 => const Color(0xFFD7403A),
      2 => const Color(0xFFE0A030),
      3 => const Color(0xFF8DBE3F),
      _ => theme.colorScheme.primary,
    };
    final label = switch (score) {
      0 => '',
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      _ => 'Strong',
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: password.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            height: 5,
                            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i < score
                                  ? color
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 44,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final (text, test) in Validators.passwordRules)
                        _Rule(text: text, met: test(password)),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.met});
  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met ? Ph.checkCircleFill : Ph.checkCircle,
            key: ValueKey(met),
            size: 16,
            color: met ? colors.primary : colors.outline,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: met ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// A server-side problem such as a wrong password, shown clearly above the button.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    final error = context.select<AuthProvider, String?>((a) => a.error);
    final colors = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: error == null
          ? const SizedBox(width: double.infinity)
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.error.withValues(alpha: .35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Ph.warningCircleFill, color: colors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((a) => a.busy);
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? const SizedBox(
                key: ValueKey('busy'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  const SizedBox(width: 8),
                  const Icon(Ph.arrowRightBold, size: 18),
                ],
              ),
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.question,
    required this.action,
    required this.onTap,
  });
  final String question, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
