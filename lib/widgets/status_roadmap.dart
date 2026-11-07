import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_icons.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String stamp(DateTime at) {
  final local = at.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]} ${local.year} · ${local.hour}:$minute';
}

enum _StepState { done, current, skipped, upcoming }

// Every status laid out in order. Steps not reached yet stay grey; finished ones show who did them.
class StatusRoadmap extends StatelessWidget {
  const StatusRoadmap({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final rejected = incident.status == 'Rejected';
    final steps = [
      'Submitted',
      'In Progress',
      rejected ? 'Rejected' : 'Resolved',
    ];
    final currentIndex = steps
        .indexOf(incident.status)
        .clamp(0, steps.length - 1);

    StatusEvent? eventFor(String status) {
      for (final event in incident.history.reversed) {
        if (event.status == status) return event;
      }
      return null;
    }

    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final event = eventFor(steps[i]);
      final _StepState state;
      if (i > currentIndex) {
        state = _StepState.upcoming;
      } else if (i == currentIndex) {
        state = _StepState.current;
      } else {
        state = event != null ? _StepState.done : _StepState.skipped;
      }
      children.add(
        _Step(
          status: steps[i],
          state: state,
          event: event,
          reporter: incident.isAnonymous
              ? 'Anonymous'
              : (incident.reporterName.isEmpty
                    ? 'a student'
                    : incident.reporterName),
          last: i == steps.length - 1,
          lineReached: i < currentIndex,
        ),
      );
    }
    return Column(children: children);
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.state,
    required this.event,
    required this.reporter,
    required this.last,
    required this.lineReached,
  });
  final String status, reporter;
  final _StepState state;
  final StatusEvent? event;
  final bool last, lineReached;

  bool get _terminal => status == 'Resolved' || status == 'Rejected';
  // A finished step is one that was reached and is not still being worked on.
  bool get _finished =>
      state == _StepState.done || (state == _StepState.current && _terminal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rejected = status == 'Rejected';
    final accent = rejected ? const Color(0xFFD7403A) : colors.primary;
    final grey = colors.outlineVariant;
    final upcoming = state == _StepState.upcoming;
    final label = status == 'In Progress' ? 'In progress' : status;

    final who = event == null || event!.changedBy.isEmpty
        ? (status == 'Submitted' ? reporter : 'staff')
        : event!.changedBy;
    final line = switch (status) {
      'Submitted' => 'Reported by $who',
      'In Progress' => 'Taken on by $who',
      'Resolved' => 'Resolved by $who',
      _ => 'Rejected by $who',
    };
    final note = event?.note ?? '';
    final showNote = note.isNotEmpty && note != 'Report submitted';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!last)
          Positioned(
            left: 18.5,
            top: 36,
            bottom: -4,
            width: 3,
            child: _Rail(reached: lineReached, accent: accent, grey: grey),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Align(
                alignment: Alignment.topLeft,
                child: _Node(
                  state: state,
                  finished: _finished,
                  accent: accent,
                  grey: grey,
                  rejected: rejected,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 24, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: upcoming
                                  ? colors.outline
                                  : (_finished && rejected ? accent : null),
                            ),
                          ),
                        ),
                        if (state == _StepState.current && !_terminal) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Now',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (upcoming)
                      Text(
                        'Not reached yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.outline,
                        ),
                      )
                    else if (state == _StepState.skipped)
                      Text(
                        'Skipped',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.outline,
                        ),
                      )
                    else ...[
                      Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event != null)
                        Text(
                          stamp(event!.at),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (showNote) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            note,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.state,
    required this.finished,
    required this.accent,
    required this.grey,
    required this.rejected,
  });
  final _StepState state;
  final bool finished, rejected;
  final Color accent, grey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const size = 32.0;
    if (finished) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        child: Icon(
          rejected ? Ph.xBold : Ph.checkBold,
          color: Colors.white,
          size: 17,
        ),
      );
    }
    switch (state) {
      case _StepState.done:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          child: const Icon(Ph.checkBold, color: Colors.white, size: 17),
        );
      case _StepState.current:
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                  color: accent.withValues(alpha: .12),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      case _StepState.skipped:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: grey, shape: BoxShape.circle),
          child: Icon(Ph.checkBold, color: colors.surface, size: 16),
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
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: grey, shape: BoxShape.circle),
            ),
          ),
        );
    }
  }
}

// The line between two steps fills in green once the next step has been reached.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.reached,
    required this.accent,
    required this.grey,
  });
  final bool reached;
  final Color accent, grey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Container(
      width: 3,
      decoration: BoxDecoration(
        color: grey,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: reached ? 1 : 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => FractionallySizedBox(
            heightFactor: t,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
