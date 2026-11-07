import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

// Every form and confirmation in the app opens in this same bottom sheet.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: builder,
);

// The layout of such a sheet: an icon and title, the fields, then the buttons.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.child,
    this.secondaryLabel = 'Cancel',
    this.destructive = false,
    this.busy = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final String primaryLabel, secondaryLabel;
  // Null greys the main button out, for example until something has changed.
  final VoidCallback? onPrimary;
  final bool destructive, busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = destructive ? const Color(0xFFD7403A) : colors.primary;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        0,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 22), child!],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : onPrimary,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(primaryLabel),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: colors.onSurfaceVariant,
            ),
            child: Text(secondaryLabel),
          ),
        ],
      ),
    );
  }
}

// A yes or no question in the same style, for things like deleting or logging out.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final yes = await showFormSheet<bool>(
    context,
    builder: (sheet) => FormSheet(
      icon: icon,
      title: title,
      destructive: destructive,
      primaryLabel: confirmLabel,
      secondaryLabel: cancelLabel,
      onPrimary: () => Navigator.of(sheet).pop(true),
      child: Text(
        message,
        style: Theme.of(sheet).textTheme.bodyLarge?.copyWith(
          color: Theme.of(sheet).colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    ),
  );
  return yes == true;
}

// Chips for a list the person builds up one item at a time, such as a facility's areas.
class RemovableChip extends StatelessWidget {
  const RemovableChip({super.key, required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Ph.xCircleFill,
                size: 18,
                color: colors.onPrimaryContainer.withValues(alpha: .7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
