import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/incident_screens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/incident_card.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final reports = provider.items;
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Care · Staff'),
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
                constraints: const BoxConstraints(maxWidth: 1000),
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
                      'Here’s the campus facilities overview.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: .55,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              color: theme.colorScheme.primary,
                              size: 25,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reports that need your attention',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Review new issues and keep students informed.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 1.7 : 1.55,
                      children: [
                        _StaffMetric(
                          label: 'New',
                          count: _count(reports, 'Submitted'),
                          icon: Icons.fiber_new_rounded,
                          color: AppTheme.green,
                        ),
                        _StaffMetric(
                          label: 'In progress',
                          count: _count(reports, 'In Progress'),
                          icon: Icons.handyman_outlined,
                          color: AppTheme.red,
                        ),
                        _StaffMetric(
                          label: 'Resolved',
                          count: _count(reports, 'Resolved'),
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
                            'Recent reports',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _open(
                            context,
                            const IncidentListScreen(staffView: true),
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: provider.setQuery,
                      decoration: const InputDecoration(
                        hintText: 'Search by title or location',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusFilter(
                          label: 'All reports',
                          value: 'All',
                          selected: provider.status == 'All',
                        ),
                        _StatusFilter(
                          label: 'New',
                          value: 'Submitted',
                          selected: provider.status == 'Submitted',
                        ),
                        _StatusFilter(
                          label: 'In progress',
                          value: 'In Progress',
                          selected: provider.status == 'In Progress',
                        ),
                        _StatusFilter(
                          label: 'Resolved',
                          value: 'Resolved',
                          selected: provider.status == 'Resolved',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.loading && reports.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (provider.error != null && reports.isEmpty)
                      _DashboardMessage(
                        icon: Icons.cloud_off_outlined,
                        text: provider.error!,
                      )
                    else if (provider.visibleItems.isEmpty)
                      const _DashboardMessage(
                        icon: Icons.task_alt_rounded,
                        text: 'You’re all caught up. New campus reports will appear here.',
                      )
                    else
                      ...provider.visibleItems
                          .take(4)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: IncidentCard(
                                incident: item,
                                staffView: true,
                                canDelete: false,
                                onTap: () => _open(
                                  context,
                                  IncidentDetailScreen(
                                    incident: item,
                                    staffView: true,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _open(context, const IncidentListScreen(staffView: true));
          }
          if (index == 2) _open(context, const AccountSettingsScreen());
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  int _count(List<Incident> items, String status) =>
      items.where((item) => item.status == status).length;
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 19),
                const Spacer(),
                Text(
                  count.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.label,
    required this.value,
    required this.selected,
  });
  final String label, value;
  final bool selected;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => context.read<IncidentProvider>().setStatus(value),
  );
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
