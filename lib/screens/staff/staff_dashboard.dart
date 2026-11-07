import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/incident_screens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/user_avatar.dart';
import '../shell/app_shell.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final user = context.watch<AuthProvider>().user;
    final reports = provider.items;
    final first = (user?.displayName ?? '').trim().split(RegExp(r'\s+')).first;
    final shell = ShellScope.maybeOf(context);
    final dark = theme.brightness == Brightness.dark;

    void showStatus(String status) {
      provider.setStatus(status);
      shell?.goTab(1);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    14,
                    wide ? 28 : 20,
                    24,
                  ),
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: user, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Staff overview',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Toggle theme',
                          onPressed: () => context
                              .read<ThemeProvider>()
                              .setMode(dark ? ThemeMode.light : ThemeMode.dark),
                          icon: Icon(dark ? Ph.sun : Ph.moon, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 1.7 : 1.35,
                      children: [
                        StatTile(
                          label: 'New',
                          value: _count(reports, 'Submitted'),
                          icon: Ph.trayFill,
                          tone: Tone.mint,
                          onTap: () => showStatus('Submitted'),
                        ),
                        StatTile(
                          label: 'In progress',
                          value: _count(reports, 'In Progress'),
                          icon: Ph.wrenchFill,
                          tone: Tone.sand,
                          onTap: () => showStatus('In Progress'),
                        ),
                        StatTile(
                          label: 'Resolved',
                          value: _count(reports, 'Resolved'),
                          icon: Ph.checkCircleFill,
                          tone: Tone.lime,
                          onTap: () => showStatus('Resolved'),
                        ),
                        StatTile(
                          label: 'Rejected',
                          value: _count(reports, 'Rejected'),
                          icon: Ph.xCircleFill,
                          tone: Tone.blush,
                          onTap: () => showStatus('Rejected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent reports',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.setStatus('All');
                            shell?.goTab(1);
                          },
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: provider.setQuery,
                      decoration: const InputDecoration(
                        hintText: 'Search by title or location',
                        prefixIcon: Icon(Ph.magnifyingGlass),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (label, value) in const [
                          ('All reports', 'All'),
                          ('New', 'Submitted'),
                          ('In progress', 'In Progress'),
                          ('Resolved', 'Resolved'),
                          ('Rejected', 'Rejected'),
                        ])
                          FilterChip(
                            label: Text(label),
                            selected: provider.status == value,
                            showCheckmark: false,
                            onSelected: (_) => provider.setStatus(value),
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
                        icon: Ph.cloudSlashFill,
                        text: provider.error!,
                      )
                    else if (provider.visibleItems.isEmpty)
                      const _DashboardMessage(
                        icon: Ph.checkCircleFill,
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
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => IncidentDetailScreen(
                                      incident: item,
                                      staffView: true,
                                    ),
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
    );
  }

  int _count(List<Incident> items, String status) =>
      items.where((item) => item.status == status).length;
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
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
