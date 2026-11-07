import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/user_role.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/floating_nav.dart';
import '../../widgets/form_sheet.dart';
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
    required this.openAlerts,
    required super.child,
  });
  final void Function(int tab) goTab;
  final VoidCallback newReport;
  final VoidCallback openAlerts;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

enum _Slot { tab, create, logout }

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
        avatar: (_) => UserAvatar(user: user, size: 26),
      ),
      _staff ? 3 : 2,
    );
    const records = _Dest(
      _Slot.tab,
      NavItemData(
        label: 'Records',
        icon: Ph.clipboardText,
        activeIcon: Ph.clipboardTextFill,
      ),
      1,
    );
    const logout = _Dest(
      _Slot.logout,
      NavItemData(
        label: 'Log out',
        icon: Ph.signOut,
        activeIcon: Ph.signOutFill,
        destructive: true,
      ),
    );
    if (_staff) {
      return [
        const _Dest(
          _Slot.tab,
          NavItemData(
            label: 'Overview',
            icon: Ph.squaresFour,
            activeIcon: Ph.squaresFourFill,
          ),
          0,
        ),
        records,
        const _Dest(
          _Slot.tab,
          NavItemData(
            label: 'Facilities',
            icon: Ph.buildings,
            activeIcon: Ph.buildingsFill,
          ),
          2,
        ),
        account,
        logout,
      ];
    }
    // Two tabs, the Report button, then two more: the button sits in the middle.
    return [
      const _Dest(
        _Slot.tab,
        NavItemData(label: 'Home', icon: Ph.house, activeIcon: Ph.houseFill),
        0,
      ),
      records,
      const _Dest(
        _Slot.create,
        NavItemData(
          label: 'Report',
          icon: Ph.plusBold,
          activeIcon: Ph.plusBold,
          primary: true,
        ),
      ),
      account,
      logout,
    ];
  }

  Widget _page(int tab, AppUser? user) {
    final campus = (user?.campus ?? '').isEmpty
        ? 'Kigali Campus'
        : user!.campus;
    if (_staff) {
      return switch (tab) {
        0 => const StaffDashboard(),
        1 => const IncidentListScreen(staffView: true),
        2 => FacilityManagementScreen(campus: campus),
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
      case _Slot.logout:
        _confirmLogout();
    }
  }

  Future<void> _confirmLogout() async {
    final out = await showConfirmSheet(
      context,
      icon: Ph.signOut,
      title: 'Log out?',
      message: 'You’ll need to sign in again to use the app.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay signed in',
    );
    if (out && mounted) await context.read<AuthProvider>().signOut();
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
    final dests = _dests(user);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ShellScope(
      goTab: _goTab,
      newReport: _newReport,
      openAlerts: _openAlerts,
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
                      return FloatingNavBar(
                        items: [for (final d in dests) d.nav],
                        selected: selected,
                        onTap: (i) => _onTap(dests[i]),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
