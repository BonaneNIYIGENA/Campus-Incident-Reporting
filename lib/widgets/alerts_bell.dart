import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../screens/shell/app_shell.dart';
import '../theme/app_icons.dart';
import 'notifications_sheet.dart';

// The notification bell for the top of a screen. It opens the alerts popup and counts unread ones.
class AlertsBell extends StatelessWidget {
  const AlertsBell({super.key, required this.staffView});
  final bool staffView;

  @override
  Widget build(BuildContext context) {
    final items = context.watch<IncidentProvider>().items;
    final uid = context.watch<AuthProvider>().user?.uid;
    final store = context.watch<AlertsProvider>();
    final alerts = staffView ? staffAlerts(items) : studentAlerts(items, uid);
    final unread = alerts
        .where((a) => !store.isDeleted(a.key) && !store.isRead(a.key))
        .length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Alerts',
          onPressed: ShellScope.maybeOf(context)?.openAlerts,
          icon: const Icon(Ph.bellSimple, size: 26),
        ),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5483F),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
