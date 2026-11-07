import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../screens/incident_screens.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class AlertItem {
  const AlertItem({
    required this.key,
    required this.incident,
    required this.title,
    required this.detail,
    required this.at,
  });
  final String key;
  final Incident incident;
  final String title, detail;
  final DateTime at;
}

// Students hear about status changes on their own reports.
List<AlertItem> studentAlerts(List<Incident> items, String? uid) => [
  for (final item in items)
    if (item.reporterId == uid && item.history.length > 1)
      AlertItem(
        key: '${item.id}:${item.history.length}',
        incident: item,
        title: '${item.title} is now ${item.history.last.status}',
        detail: item.history.last.note.isEmpty
            ? 'The status of your report changed.'
            : item.history.last.note,
        at: item.history.last.at,
      ),
];

// Staff hear about reports nobody has picked up yet.
List<AlertItem> staffAlerts(List<Incident> items) => [
  for (final item in items)
    if (item.status == 'Submitted')
      AlertItem(
        key: item.id,
        incident: item,
        title: item.title,
        detail:
            '${item.isAnonymous ? 'Anonymous reporter' : item.reporterName} · ${item.building}',
        at: item.createdAt,
      ),
];

String timeAgo(DateTime at) {
  final gap = DateTime.now().difference(at);
  if (gap.inMinutes < 1) return 'Just now';
  if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
  if (gap.inHours < 24) return '${gap.inHours}h ago';
  if (gap.inDays < 7) return '${gap.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}

// A panel that drops down from the top and leaves the nav bar visible.
class TopPanelRoute extends PopupRoute<void> {
  TopPanelRoute({required this.builder});
  final WidgetBuilder builder;

  @override
  Color get barrierColor => Colors.black.withValues(alpha: .38);
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'Close updates';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({
    super.key,
    required this.staffView,
    required this.navigator,
  });
  final bool staffView;
  final NavigatorState navigator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<AlertsProvider>();
    final items = context.watch<IncidentProvider>().items;
    final uid = context.watch<AuthProvider>().user?.uid;
    final all = staffView ? staffAlerts(items) : studentAlerts(items, uid);
    final alerts = all.where((a) => !store.isDeleted(a.key)).take(12).toList();
    final unread = alerts.where((a) => !store.isRead(a.key)).length;
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * .62, maxWidth: 560),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          staffView ? 'Needs attention' : 'Updates',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread new',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (unread > 0)
                          TextButton.icon(
                            onPressed: () =>
                                store.markRead(alerts.map((a) => a.key)),
                            icon: const Icon(Ph.checkBold, size: 16),
                            label: const Text('Mark all read'),
                          ),
                      ],
                    ),
                  ),
                  if (alerts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Swipe right to mark as read, left to delete.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Ph.bellSimpleFill,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              staffView
                                  ? 'You’re all caught up. New reports will show here.'
                                  : 'You’re all caught up. Status updates will show here.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return _AlertTile(
                            alert: alert,
                            read: store.isRead(alert.key),
                            onOpen: () {
                              store.markRead([alert.key]);
                              Navigator.of(context).pop();
                              navigator.push(
                                MaterialPageRoute<void>(
                                  builder: (_) => IncidentDetailScreen(
                                    incident: alert.incident,
                                    staffView: staffView,
                                  ),
                                ),
                              );
                            },
                            onRead: () => store.markRead([alert.key]),
                            onDelete: () => store.delete(alert.key),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.read,
    required this.onOpen,
    required this.onRead,
    required this.onDelete,
  });
  final AlertItem alert;
  final bool read;
  final VoidCallback onOpen, onRead, onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _statusColor(alert.incident.status);
    return Dismissible(
      key: ValueKey(alert.key),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onRead();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: const _SwipeBackground(
        color: Color(0xFF1E8E4E),
        icon: Ph.checkBold,
        label: 'Read',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: Color(0xFFD7403A),
        icon: Ph.trashBold,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      child: Material(
        color: read
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // One solid circle holds the icon.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: read ? tint.withValues(alpha: .45) : tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(alert.incident.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                          color: read
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo(alert.at),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: read ? 0 : 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    final children = [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: left ? children : children.reversed.toList(),
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'Resolved' => AppTheme.green,
  'Rejected' => AppTheme.red,
  'In Progress' => AppTheme.amber,
  _ => const Color(0xFF6B7A70),
};

IconData _statusIcon(String status) => switch (status) {
  'Resolved' => Ph.checkCircleFill,
  'Rejected' => Ph.xCircleFill,
  'In Progress' => Ph.wrenchFill,
  _ => Ph.paperPlaneTiltFill,
};
