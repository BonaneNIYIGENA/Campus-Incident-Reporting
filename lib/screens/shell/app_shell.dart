import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

import 'package:provider/provider.dart';

import '../../providers/alerts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/user_role.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/floating_nav.dart';
import '../../widgets/notifications_sheet.dart';
import '../auth/auth_gate.dart';
import '../incident_screens.dart';
import '../staff/facility_management_screen.dart';
import '../staff/staff_dashboard.dart';
import '../student/student_dashboard.dart';

// Lets a tab ask the shell to switch tabs or open the report form.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.goTab,
    required this.newReport,
    required super.child,
  });
  final void Function(int tab) goTab;
  final VoidCallback newReport;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

enum _Slot { tab, create, alerts }

class _Dest {
  const _Dest(this.slot, this.nav, [this.tab = -1]);
  final _Slot slot;
  final NavItemData nav;
  final int tab;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.role});
  final UserRole role;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _StackWatcher extends NavigatorObserver {
  _StackWatcher(this.onChange);
  final VoidCallback onChange;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
}

class _AppShellState extends State<AppShell> {
  final _nav = GlobalKey<NavigatorState>();
  final _tab = ValueNotifier<int>(0);
  final _canPop = ValueNotifier<bool>(false);
  late final _watcher = _StackWatcher(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _canPop.value = _nav.currentState?.canPop() ?? false;
    });
  });

  bool get _staff => widget.role == UserRole.staff;

  List<_Dest> _dests(AppUser? user) {
    final account = _Dest(
      _Slot.tab,
      NavItemData(
        label: 'Account',
        icon: Ph.userCircle,
        activeIcon: Ph.userCircleFill,
        avatar: (_) => UserAvatar(user: user, size: 28),
      ),
      _staff ? 3 : 2,
    );
    return _staff
        ? [
            _Dest(
              _Slot.tab,
              NavItemData(
                label: 'Overview',
                icon: Ph.squaresFour,
                activeIcon: Ph.squaresFourFill,
              ),
              0,
            ),
            _Dest(
              _Slot.tab,
              NavItemData(
                label: 'Reports',
                icon: Ph.clipboardText,
                activeIcon: Ph.clipboardTextFill,
              ),
              1,
            ),
            _Dest(
              _Slot.tab,
              NavItemData(
                label: 'Facilities',
                icon: Ph.buildings,
                activeIcon: Ph.buildingsFill,
              ),
              2,
            ),
            _Dest(
              _Slot.alerts,
              NavItemData(
                label: 'Alerts',
                icon: Ph.bellSimple,
                activeIcon: Ph.bellSimpleFill,
              ),
            ),
            account,
          ]
        : [
            const _Dest(
              _Slot.tab,
              NavItemData(
                label: 'Home',
                icon: Ph.house,
                activeIcon: Ph.houseFill,
              ),
              0,
            ),
            _Dest(
              _Slot.tab,
              NavItemData(
                label: 'Reports',
                icon: Ph.clipboardText,
                activeIcon: Ph.clipboardTextFill,
              ),
              1,
            ),
            _Dest(
              _Slot.create,
              NavItemData(
                label: 'New report',
                icon: Ph.plusBold,
                activeIcon: Ph.plusBold,
                primary: true,
              ),
            ),
            _Dest(
              _Slot.alerts,
              NavItemData(
                label: 'Alerts',
                icon: Ph.bellSimple,
                activeIcon: Ph.bellSimpleFill,
              ),
            ),
            account,
          ];
  }

  Widget _page(int tab, AppUser? user) {
    final campus = user?.campus ?? '';
    if (_staff) {
      return switch (tab) {
        0 => const StaffDashboard(),
        1 => const IncidentListScreen(staffView: true),
        2 => FacilityManagementScreen(
          campus: campus.isEmpty ? 'Kigali Campus' : campus,
        ),
        _ => const AccountSettingsScreen(),
      };
    }
    return switch (tab) {
      0 => const StudentDashboard(),
      1 => const IncidentListScreen(staffView: false),
      _ => const AccountSettingsScreen(),
    };
  }

  void _goTab(int tab) {
    _nav.currentState?.popUntil((route) => route.isFirst);
    _tab.value = tab;
  }

  void _newReport() => _nav.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => const CreateIncidentScreen()),
  );

  void _openAlerts() {
    final navigator = _nav.currentState!;
    navigator.push(
      TopPanelRoute(
        builder: (_) =>
            NotificationsPanel(staffView: _staff, navigator: navigator),
      ),
    );
  }

  void _onTap(_Dest dest) {
    switch (dest.slot) {
      case _Slot.tab:
        _goTab(dest.tab);
      case _Slot.create:
        _newReport();
      case _Slot.alerts:
        _openAlerts();
    }
  }

  Future<void> _confirmLogout() async {
    final out = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You’ll need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD7403A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (out == true && mounted) await context.read<AuthProvider>().signOut();
  }

  @override
  void dispose() {
    _tab.dispose();
    _canPop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>().items;
    final store = context.watch<AlertsProvider>();
    final alerts = _staff
        ? staffAlerts(incidents)
        : studentAlerts(incidents, user?.uid);
    final unread = alerts
        .where((a) => !store.isDeleted(a.key) && !store.isRead(a.key))
        .length;
    final dests = _dests(user);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ShellScope(
      goTab: _goTab,
      newReport: _newReport,
      child: ValueListenableBuilder<bool>(
        valueListenable: _canPop,
        builder: (context, canPop, child) => NavigatorPopHandler(
          enabled: canPop,
          onPopWithResult: (_) => _nav.currentState?.maybePop(),
          child: child!,
        ),
        child: Scaffold(
          body: Navigator(
            key: _nav,
            observers: [_watcher],
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => ValueListenableBuilder<int>(
                valueListenable: _tab,
                builder: (context, tab, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: .97, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('${widget.role.name}-$tab'),
                    child: _page(tab, context.watch<AuthProvider>().user),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: keyboardOpen
                ? const SizedBox(width: double.infinity)
                : ValueListenableBuilder<int>(
                    valueListenable: _tab,
                    builder: (context, tab, _) {
                      final selected = dests.indexWhere(
                        (d) => d.slot == _Slot.tab && d.tab == tab,
                      );
                      final onAccount =
                          selected >= 0 && dests[selected].nav.avatar != null;
                      return FloatingNavBar(
                        items: [
                          for (final d in dests)
                            d.slot == _Slot.alerts
                                ? NavItemData(
                                    label: d.nav.label,
                                    icon: d.nav.icon,
                                    activeIcon: d.nav.activeIcon,
                                    badge: unread,
                                  )
                                : d.nav,
                        ],
                        selected: selected,
                        onTap: (i) => _onTap(dests[i]),
                        onLogout: onAccount ? _confirmLogout : null,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
