import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/incident_provider.dart';
import '../theme/app_icons.dart';

const _statusOptions = [
  ('All', 'All statuses'),
  ('Submitted', 'New'),
  ('In Progress', 'In progress'),
  ('Resolved', 'Resolved'),
  ('Rejected', 'Rejected'),
];

const reportCategories = [
  'Water',
  'Electricity',
  'Facilities',
  'Furniture',
  'Sanitation',
  'Safety',
  'Other',
];

String statusLabel(String value) => _statusOptions
    .firstWhere((o) => o.$1 == value, orElse: () => (value, value))
    .$2;

// A pill-shaped search field with a filter button on the right.
class ReportsSearchBar extends StatefulWidget {
  const ReportsSearchBar({super.key});

  @override
  State<ReportsSearchBar> createState() => _ReportsSearchBarState();
}

class _ReportsSearchBarState extends State<ReportsSearchBar> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<IncidentProvider>().query,
    );
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active =
        (provider.status != 'All' ? 1 : 0) +
        (provider.category != 'All' ? 1 : 0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF141816) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _focus.hasFocus
              ? colors.primary
              : (dark ? const Color(0xFF262C28) : const Color(0xFFE4E8E4)),
          width: _focus.hasFocus ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .3 : .06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Ph.magnifyingGlass,
            size: 22,
            color: _focus.hasFocus ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              maxLength: 60,
              onChanged: (value) {
                provider.setQuery(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search reports',
                counterText: '',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _controller.text.isEmpty
                ? const SizedBox(width: 4, key: ValueKey('no-clear'))
                : IconButton(
                    key: const ValueKey('clear'),
                    tooltip: 'Clear search',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _controller.clear();
                      provider.setQuery('');
                      setState(() {});
                    },
                    icon: const Icon(Ph.xCircleFill, size: 20),
                    color: colors.onSurfaceVariant,
                  ),
          ),
          _FilterButton(
            count: active,
            onTap: () {
              _focus.unfocus();
              showReportFilters(context);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = count > 0;
    return Semantics(
      button: true,
      label: 'Filters',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Filters',
        triggerMode: TooltipTriggerMode.manual,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? colors.primary : Colors.transparent,
                  border: Border.all(color: colors.primary, width: 1.6),
                ),
                child: Icon(
                  Ph.slidersHorizontal,
                  size: 20,
                  color: active ? colors.onPrimary : colors.primary,
                ),
              ),
              if (active)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5483F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shows the filters that are on, each one removable.
class ActiveFilters extends StatelessWidget {
  const ActiveFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final chips = <Widget>[
      if (provider.status != 'All')
        _ActiveChip(
          label: statusLabel(provider.status),
          onRemove: () => provider.setStatus('All'),
        ),
      if (provider.category != 'All')
        _ActiveChip(
          label: provider.category,
          onRemove: () => provider.setCategory('All'),
        ),
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: chips.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...chips,
                  if (chips.length > 1)
                    TextButton(
                      onPressed: () {
                        provider.setStatus('All');
                        provider.setCategory('All');
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Ph.xBold, size: 14, color: colors.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

Future<void> showReportFilters(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .78,
      ),
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final count = provider.visibleItems.length;
    final active = provider.status != 'All' || provider.category != 'All';
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter reports',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: active ? 1 : 0,
                      child: TextButton(
                        onPressed: active
                            ? () {
                                provider.setStatus('All');
                                provider.setCategory('All');
                              }
                            : null,
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Status', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (value, label) in _statusOptions)
                      _OptionChip(
                        label: label,
                        selected: provider.status == value,
                        onTap: () => provider.setStatus(value),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in ['All', ...reportCategories])
                      _OptionChip(
                        label: value == 'All' ? 'All categories' : value,
                        selected: provider.category == value,
                        onTap: () => provider.setCategory(value),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  count == 1 ? 'Show 1 report' : 'Show $count reports',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Ph.checkBold,
                          size: 14,
                          color: colors.onPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
