import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_icons.dart';
import '../theme/status_style.dart';

String stamp(DateTime at) {
  final local = at.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${monthShort(local.month)} ${local.year} · ${local.hour}:$minute';
}

enum _StepState { done, current, skipped, upcoming }

// Every status in a row, small enough to sit under the photo. Steps not reached stay grey;
// reached ones take their status colour and say who did them.
class StatusRoadmap extends StatelessWidget {
  const StatusRoadmap({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rejected = incident.status == 'Rejected';
    final steps = [
      'Submitted',
      'In Progress',
      if (rejected) 'Rejected' else 'Resolved',
    ];
    final current = steps.indexOf(incident.status).clamp(0, steps.length - 1);

    StatusEvent? eventFor(String status) {
      for (final event in incident.history.reversed) {
        if (event.status == status) return event;
      }
      return null;
    }

    _StepState stateOf(int i) {
      if (i > current) return _StepState.upcoming;
      if (i == current) return _StepState.current;
      return eventFor(steps[i]) != null ? _StepState.done : _StepState.skipped;
    }

    final latest = incident.history.isEmpty ? null : incident.history.last;
    final showNote =
        latest != null &&
        latest.note.isNotEmpty &&
        latest.note != 'Report submitted';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: _Step(
                    status: steps[i],
                    state: stateOf(i),
                    event: eventFor(steps[i]),
                    reporter: incident.isAnonymous
                        ? 'Anonymous'
                        : (incident.reporterName.isEmpty
                              ? 'a student'
                              : incident.reporterName),
                    leftReached: i > 0 && i <= current,
                    rightReached: i < current,
                    first: i == 0,
                    last: i == steps.length - 1,
                    nextColor: i < steps.length - 1
                        ? statusStyle(steps[i + 1]).color
                        : null,
                    ownColor: statusStyle(steps[i]).color,
                  ),
                ),
            ],
          ),
          if (showNote) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Ph.pencilSimple, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (latest.changedBy.isNotEmpty)
                            TextSpan(
                              text: '${latest.changedBy}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          TextSpan(text: latest.note),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.state,
    required this.event,
    required this.reporter,
    required this.leftReached,
    required this.rightReached,
    required this.first,
    required this.last,
    required this.nextColor,
    required this.ownColor,
  });
  final String status, reporter;
  final _StepState state;
  final StatusEvent? event;
  final bool leftReached, rightReached, first, last;
  final Color? nextColor;
  final Color ownColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = statusStyle(status);
    final upcoming = state == _StepState.upcoming;
    final skipped = state == _StepState.skipped;
    final grey = colors.outlineVariant;

    final name = event == null || event!.changedBy.isEmpty
        ? (status == 'Submitted' ? reporter : 'staff')
        : event!.changedBy;

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                child: first
                    ? const SizedBox.shrink()
                    : _Line(reached: leftReached, color: ownColor, grey: grey),
              ),
              _Node(state: state, style: style, grey: grey),
              Expanded(
                child: last
                    ? const SizedBox.shrink()
                    : _Line(
                        reached: rightReached,
                        color: nextColor ?? ownColor,
                        grey: grey,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          style.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: upcoming || skipped ? colors.outline : style.color,
          ),
        ),
        const SizedBox(height: 2),
        if (upcoming)
          Text(
            'Not yet',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
          )
        else if (skipped)
          Text(
            'Skipped',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'by $name',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (event != null)
            Text(
              '${event!.at.toLocal().day} ${monthShort(event!.at.toLocal().month)} · ${event!.at.toLocal().hour}:${event!.at.toLocal().minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.state, required this.style, required this.grey});
  final _StepState state;
  final StatusStyle style;
  final Color grey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const size = 30.0;
    switch (state) {
      case _StepState.done:
      case _StepState.current:
        final now = state == _StepState.current;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: style.color,
            shape: BoxShape.circle,
            boxShadow: now
                ? [
                    BoxShadow(
                      color: style.color.withValues(alpha: .35),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(style.icon, color: Colors.white, size: 17),
        );
      case _StepState.skipped:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: grey, shape: BoxShape.circle),
          child: Icon(Ph.checkBold, color: colors.surface, size: 15),
        );
      case _StepState.upcoming:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: grey, width: 2),
            color: colors.surfaceContainer,
          ),
          child: Icon(style.icon, color: grey, size: 15),
        );
    }
  }
}

// The line between two steps fills in with the colour of the step it leads to.
class _Line extends StatelessWidget {
  const _Line({required this.reached, required this.color, required this.grey});
  final bool reached;
  final Color color, grey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Container(
      height: 3,
      decoration: BoxDecoration(
        color: grey,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: reached ? 1 : 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => FractionallySizedBox(
            widthFactor: t,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
