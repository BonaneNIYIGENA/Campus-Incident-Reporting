import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/incident_screens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/incident_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final own = provider.items.where((item) => item.reporterId == uid).toList();
    final first = name.trim().split(RegExp(r'\s+')).first;
    final recent = own.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Care'),
        actions: [
          IconButton(
            tooltip: 'Account and preferences',
            onPressed: () => _open(context, const AccountSettingsScreen()),
            icon: const Icon(Icons.account_circle_outlined),
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
                      'Good day, $first',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Let’s make campus better, together.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ReportBanner(
                      onPressed: () =>
                          _open(context, const CreateIncidentScreen()),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Submitted',
                            value: own
                                .where((i) => i.status == 'Submitted')
                                .length,
                            icon: Icons.assignment_outlined,
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'In progress',
                            value: own
                                .where(
                                  (i) =>
                                      i.status == 'In Progress' ||
                                      i.status == 'Under Review',
                                )
                                .length,
                            icon: Icons.pending_actions_rounded,
                            color: AppTheme.amber,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'Resolved',
                            value: own
                                .where((i) => i.status == 'Resolved')
                                .length,
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF42856A),
                          ),
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
                      _MessageCard(
                        icon: Icons.inbox_outlined,
                        title: 'No reports yet',
                        subtitle: 'Your reports and their status updates will appear here.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const CreateIncidentScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New report'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _open(context, const IncidentListScreen(staffView: false));
          }
          if (index == 2) _open(context, const AccountSettingsScreen());
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.deepGreen,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See something that needs attention?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Tell the right team and follow progress.',
                    style: TextStyle(color: Color(0xFFD9F2E3)),
                  ),
                  SizedBox(height: 17),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Report an issue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.campaign_outlined, color: Colors.white, size: 36),
          ],
        ),
      ),
    ),
  );
}

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
