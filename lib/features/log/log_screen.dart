import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../../services/export_csv.dart';
import '../common/app_chrome.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    if (d.inDays >= 1) {
      final h = d.inHours.remainder(24);
      return '${d.inDays}d ${h}h';
    }
    if (d.inHours >= 1) {
      final m = d.inMinutes.remainder(60);
      return '${d.inHours}h ${m}m';
    }
    return '${d.inMinutes}m';
  }

  Color _outcomeColor(BuildContext context, ActivationOutcome o) {
    final scheme = Theme.of(context).colorScheme;
    switch (o) {
      case ActivationOutcome.completed:
        return scheme.primary;
      case ActivationOutcome.aborted:
        return scheme.error;
      case ActivationOutcome.incomplete:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              final repo = ref.read(repositoryProvider);
              await shareCsvExport(repo.exportCsv());
            },
            icon: const Icon(Icons.ios_share),
          ),
          ...ripCordAppBarActions(context),
        ],
      ),
      body: bootstrap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          final summary = ref.watch(summaryProvider);
          final events = ref.watch(eventsProvider);
          final dateFmt = DateFormat.MMMd().add_jm();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipStat(
                    label: 'Today uses',
                    value: '${summary.todayUses}',
                  ),
                  _ChipStat(
                    label: 'Today success',
                    value: summary.todayUses == 0
                        ? '—'
                        : '${(summary.todaySuccessRate * 100).round()}%',
                  ),
                  _ChipStat(
                    label: 'Week uses',
                    value: '${summary.weekUses}',
                  ),
                  _ChipStat(
                    label: 'Week success',
                    value: summary.weekUses == 0
                        ? '—'
                        : '${(summary.weekSuccessRate * 100).round()}%',
                  ),
                  _ChipStat(
                    label: 'Points',
                    value: '${summary.totalPoints}',
                  ),
                  _ChipStat(
                    label: 'Streak',
                    value: '${summary.currentStreak}',
                  ),
                  _ChipStat(
                    label: 'Best streak',
                    value: '${summary.bestStreak}',
                  ),
                  _ChipStat(
                    label: 'Longest free',
                    value: _formatDuration(summary.longestFreePeriod),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Recent activations', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (events.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No activations yet. Pull the Rip-Cord when an urge hits.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...events.map((e) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        e.responsePhrase ?? 'Competing response',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${dateFmt.format(e.startedAt)} · ${e.source.name}'
                        '${e.durationSec != null ? ' · ${e.durationSec}s' : ''}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            e.outcome.name,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _outcomeColor(context, e.outcome),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (e.pointsAwarded > 0)
                            Text(
                              '+${e.pointsAwarded}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
