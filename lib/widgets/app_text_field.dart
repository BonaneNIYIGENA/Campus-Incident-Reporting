import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_icons.dart';

// The error line shown under a field: an icon and the message, in the error colour.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Ph.warningCircleFill, size: 15, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The icon at the start of a field, with a thin divider between it and the text.
class FieldIcon extends StatelessWidget {
  const FieldIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 18, right: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Container(
          width: 1.2,
          height: 24,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ],
    ),
  );
}

// A soft glow behind a field while it is active.
class FieldGlow extends StatelessWidget {
  const FieldGlow({
    super.key,
    required this.active,
    required this.child,
    this.radius = 28,
  });
  final bool active;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: active
          ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : const [],
    ),
    child: child,
  );
}

InputBorder _withRadius(InputBorder? border, double radius) =>
    border is OutlineInputBorder
    ? border.copyWith(borderRadius: BorderRadius.circular(radius))
    : (border ?? const OutlineInputBorder());

// A text field with a leading icon, live validation and a character counter while typing.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.focusNode,
    this.alignLabelWithHint = false,
    this.fieldKey,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool autocorrect, enableSuggestions, alignLabelWithHint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final GlobalKey<FormFieldState<String>>? fieldKey;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    final radius = multiline ? 24.0 : 28.0;
    final t = Theme.of(context).inputDecorationTheme;
    return FieldGlow(
      active: _focus.hasFocus,
      radius: radius,
      child: TextFormField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focus,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        obscureText: widget.obscureText,
        autofillHints: widget.autofillHints,
        textCapitalization: widget.textCapitalization,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        errorBuilder: (context, message) => FieldError(message),
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => isFocused && maxLength != null
            ? Text(
                '$currentLength/$maxLength',
                style: TextStyle(
                  fontSize: 12,
                  color: currentLength >= maxLength
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          alignLabelWithHint: widget.alignLabelWithHint,
          prefixIcon: FieldIcon(widget.icon),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.suffix,
          border: _withRadius(t.border, radius),
          enabledBorder: _withRadius(t.enabledBorder, radius),
          focusedBorder: _withRadius(t.focusedBorder, radius),
          errorBorder: _withRadius(t.errorBorder, radius),
          focusedErrorBorder: _withRadius(t.focusedErrorBorder, radius),
        ),
      ),
    );
  }
}
