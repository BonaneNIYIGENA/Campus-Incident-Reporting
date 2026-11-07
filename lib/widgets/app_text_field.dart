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

// A text field with a leading icon, live validation and a character counter while typing.
class AppTextField extends StatelessWidget {
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
  Widget build(BuildContext context) => TextFormField(
    key: fieldKey,
    controller: controller,
    focusNode: focusNode,
    validator: validator,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    maxLines: maxLines,
    minLines: minLines,
    obscureText: obscureText,
    autofillHints: autofillHints,
    textCapitalization: textCapitalization,
    autocorrect: autocorrect,
    enableSuggestions: enableSuggestions,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    errorBuilder: (context, message) => FieldError(message),
    buildCounter:
        (context, {required currentLength, required isFocused, maxLength}) =>
            isFocused && maxLength != null
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
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? 0 : 0),
        child: Icon(icon, size: 22),
      ),
      suffixIcon: suffix,
    ),
  );
}
