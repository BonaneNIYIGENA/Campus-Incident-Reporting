import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_text_field.dart';

class SelectOption<T> {
  const SelectOption(this.value, this.label, {this.subtitle, this.icon});
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

class _Pick<T> {
  const _Pick(this.value);
  final T value;
}

// A dropdown that looks like the text fields and opens a clean list of options in a sheet.
class SelectField<T> extends FormField<T> {
  SelectField({
    super.key,
    required String label,
    required IconData icon,
    required List<SelectOption<T>> options,
    T? value,
    ValueChanged<T>? onChanged,
    super.validator,
    super.enabled,
    String? hint,
    String? sheetTitle,
  }) : super(
         initialValue: value,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (state) => _SelectBody<T>(
           state: state,
           label: label,
           hint: hint,
           icon: icon,
           options: options,
           sheetTitle: sheetTitle ?? label,
           enabled: enabled,
           onChanged: onChanged,
         ),
       );
}

class _SelectBody<T> extends StatefulWidget {
  const _SelectBody({
    required this.state,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.sheetTitle,
    required this.enabled,
    required this.onChanged,
  });
  final FormFieldState<T> state;
  final String label, sheetTitle;
  final String? hint;
  final IconData icon;
  final List<SelectOption<T>> options;
  final bool enabled;
  final ValueChanged<T>? onChanged;

  @override
  State<_SelectBody<T>> createState() => _SelectBodyState<T>();
}

class _SelectBodyState<T> extends State<_SelectBody<T>> {
  bool _open = false;

  SelectOption<T>? get _selected {
    final value = widget.state.value;
    for (final option in widget.options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _pick() async {
    if (!widget.enabled || widget.options.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _open = true);
    final pick = await showModalBottomSheet<_Pick<T>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      builder: (_) => _OptionSheet<T>(
        title: widget.sheetTitle,
        options: widget.options,
        selected: widget.state.value,
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (pick != null) {
      widget.state.didChange(pick.value);
      widget.onChanged?.call(pick.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;
    final error = widget.state.errorText;
    return Semantics(
      button: true,
      label: widget.label,
      value: selected?.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pick,
        child: FieldGlow(
          active: _open,
          child: InputDecorator(
            isFocused: _open,
            isEmpty: selected == null,
            isHovering: false,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              enabled: widget.enabled,
              prefixIcon: FieldIcon(widget.icon),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: AnimatedRotation(
                turns: _open ? .5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(Ph.caretDownBold, size: 18),
              ),
              error: error == null ? null : FieldError(error),
            ),
            child: Text(
              selected?.label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: widget.enabled
                    ? theme.colorScheme.onSurface
                    : theme.disabledColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionSheet<T> extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });
  final String title;
  final List<SelectOption<T>> options;
  final T? selected;

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = widget.options
        .where((o) => o.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.options.length > 8)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Ph.magnifyingGlass, size: 20),
                  ),
                ),
              ),
            Flexible(
              child: shown.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Nothing matches that.')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final option = shown[index];
                        final selected = option.value == widget.selected;
                        return _OptionRow(
                          option: option,
                          selected: selected,
                          onTap: () =>
                              Navigator.of(context).pop(_Pick(option.value)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final SelectOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 22,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (option.subtitle != null)
                    Text(
                      option.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(Ph.checkCircleFill, color: colors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
