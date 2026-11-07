import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/incident_screens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/incident_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.name, this.campus = ''});
  final String name;
  final String campus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final own = provider.items.where((item) => item.reporterId == uid).toList();
    final first = name.trim().split(RegExp(r'\s+')).first;
    final recent = own.take(4).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Good day, $first'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _open(context, const NotificationsScreen()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().setMode(
              theme.brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    16,
                    wide ? 28 : 20,
                    30,
                  ),
                  children: [
                    Text(
                      'Here’s what needs attention on your campus.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: wide ? 2.5 : 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _Metric(
                          label: 'Total reports',
                          value: own.length,
                          icon: Icons.description_outlined,
                          color: AppTheme.green,
                        ),
                        _Metric(
                          label: 'Pending',
                          value: own
                              .where((i) => i.status == 'Submitted')
                              .length,
                          icon: Icons.schedule_rounded,
                          color: AppTheme.amber,
                        ),
                        _Metric(
                          label: 'Unresolved',
                          value: own
                              .where(
                                (i) =>
                                    i.status != 'Resolved' &&
                                    i.status != 'Rejected',
                              )
                              .length,
                          icon: Icons.error_outline_rounded,
                          color: AppTheme.red,
                        ),
                        _Metric(
                          label: 'Resolved',
                          value: own
                              .where((i) => i.status == 'Resolved')
                              .length,
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF42856A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your recent reports',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _open(
                            context,
                            const IncidentListScreen(staffView: false),
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    if (provider.loading && own.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.error != null && own.isEmpty)
                      _MessageCard(
                        icon: Icons.cloud_off_outlined,
                        title: 'Reports are unavailable',
                        subtitle: provider.error!,
                      )
                    else if (recent.isEmpty)
                      Column(
                        children: [
                          _MessageCard(
                            icon: Icons.inbox_outlined,
                            title: 'No reports yet',
                            subtitle: 'Your reports and their status updates will appear here.',
                          ),
                        ],
                      )
                    else
                      ...recent.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IncidentCard(
                            incident: item,
                            staffView: false,
                            canDelete: item.status == 'Submitted',
                            onTap: () => _open(
                              context,
                              IncidentDetailScreen(
                                incident: item,
                                staffView: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New report',
        onPressed: () => _open(context, const CreateIncidentScreen()),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 76,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.assignment_outlined,
                label: 'Reports',
                onTap: () =>
                    _open(context, const IncidentListScreen(staffView: false)),
              ),
            ),
            SizedBox(
              width: 82,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Account',
                customIcon: context.watch<AuthProvider>().user?.photoUrl == null
                    ? null
                    : ClipOval(
                        child: Image.network(
                          context.watch<AuthProvider>().user!.photoUrl!,
                          width: 25,
                          height: 25,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                onTap: () => _open(context, const AccountSettingsScreen()),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                onTap: () => context.read<AuthProvider>().signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.customIcon,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final Widget? customIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          customIcon ?? Icon(icon, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? .14 : .08,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
