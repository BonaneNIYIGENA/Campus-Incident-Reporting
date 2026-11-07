import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/incident_screens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/user_avatar.dart';
import '../shell/app_shell.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<IncidentProvider>();
    final user = context.watch<AuthProvider>().user;
    final own = provider.items
        .where((item) => item.reporterId == user?.uid)
        .toList();
    final first = (user?.displayName ?? '').trim().split(RegExp(r'\s+')).first;
    final recent = own.take(4).toList();
    final shell = ShellScope.maybeOf(context);
    final dark = theme.brightness == Brightness.dark;

    int count(bool Function(String status) test) =>
        own.where((i) => test(i.status)).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
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
                                'Good day,',
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
                    Text(
                      'Your reports',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: wide ? 2.4 : 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StatTile(
                          label: 'Total reports',
                          value: own.length,
                          icon: Ph.filesFill,
                          tone: Tone.mint,
                          onTap: () => shell?.goTab(1),
                        ),
                        StatTile(
                          label: 'Pending',
                          value: count((s) => s == 'Submitted'),
                          icon: Ph.hourglassMediumFill,
                          tone: Tone.sand,
                          onTap: () => shell?.goTab(1),
                        ),
                        StatTile(
                          label: 'Unresolved',
                          value: count(
                            (s) => s != 'Resolved' && s != 'Rejected',
                          ),
                          icon: Ph.warningCircleFill,
                          tone: Tone.blush,
                          onTap: () => shell?.goTab(1),
                        ),
                        StatTile(
                          label: 'Resolved',
                          value: count((s) => s == 'Resolved'),
                          icon: Ph.checkCircleFill,
                          tone: Tone.lime,
                          onTap: () => shell?.goTab(1),
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
                          onPressed: () => shell?.goTab(1),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (provider.loading && own.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.error != null && own.isEmpty)
                      _MessageCard(
                        icon: Ph.cloudSlashFill,
                        title: 'Reports are unavailable',
                        subtitle: provider.error!,
                      )
                    else if (recent.isEmpty)
                      _MessageCard(
                        icon: Ph.trayFill,
                        title: 'No reports yet',
                        subtitle: 'Spotted something that needs fixing? Report it and follow the progress here.',
                        action: FilledButton.icon(
                          onPressed: shell?.newReport,
                          icon: const Icon(Ph.plusBold, size: 18),
                          label: const Text('Report an issue'),
                        ),
                      )
                    else
                      ...recent.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IncidentCard(
                            incident: item,
                            staffView: false,
                            canDelete: item.status == 'Submitted',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => IncidentDetailScreen(
                                  incident: item,
                                  staffView: false,
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
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
