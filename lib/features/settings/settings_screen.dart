import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seed.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../common/app_chrome.dart';
import 'color_wheel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: ripCordAppBarActions(context),
      ),
      body: bootstrap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          final settings = ref.watch(settingsProvider);
          final responses = ref.watch(responsesProvider);
          final bonus = ref.watch(bonusUnlockStatusProvider);
          final repo = ref.read(repositoryProvider);

          Future<void> save(AppSettings next) async {
            await repo.updateSettings(next);
            notifyDataChanged(ref);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SectionTitle('Sequence'),
              Text(
                'Duration: ${settings.sequenceDurationSec}s',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'Prompts are written to finish in about 15–30 seconds. '
                'Set the timer in that range so the action matches the clock.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Slider(
                value: settings.sequenceDurationSec.toDouble(),
                min: 10,
                max: 45,
                divisions: 35,
                label: '${settings.sequenceDurationSec}s',
                onChanged: (v) => save(
                  settings.copyWith(sequenceDurationSec: v.round()),
                ),
              ),
              SwitchListTile(
                title: const Text('Grayscale during sequence'),
                subtitle: const Text('Mild sensory quieting while you practice'),
                value: settings.grayscaleDuringSequence,
                onChanged: (v) =>
                    save(settings.copyWith(grayscaleDuringSequence: v)),
              ),
              SwitchListTile(
                title: const Text('Speak response (TTS)'),
                value: settings.ttsEnabled,
                onChanged: (v) => save(settings.copyWith(ttsEnabled: v)),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Reinforcement'),
              ListTile(
                title: const Text('Base points'),
                subtitle: Text('${settings.basePoints} per completion'),
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: settings.basePoints <= 1
                            ? null
                            : () => save(
                                  settings.copyWith(
                                    basePoints: settings.basePoints - 1,
                                  ),
                                ),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${settings.basePoints}'),
                      IconButton(
                        onPressed: () => save(
                          settings.copyWith(
                            basePoints: settings.basePoints + 1,
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Variable-ratio bonus'),
                subtitle: Text(
                  '${(settings.variableRatioChance * 100).round()}% chance of +${settings.variableRatioBonus}',
                ),
                value: settings.variableRatioEnabled,
                onChanged: (v) =>
                    save(settings.copyWith(variableRatioEnabled: v)),
              ),
              if (settings.variableRatioEnabled) ...[
                Text('Bonus chance'),
                Slider(
                  value: settings.variableRatioChance,
                  min: 0.05,
                  max: 0.5,
                  divisions: 9,
                  label:
                      '${(settings.variableRatioChance * 100).round()}%',
                  onChanged: (v) =>
                      save(settings.copyWith(variableRatioChance: v)),
                ),
                ListTile(
                  title: const Text('Bonus points'),
                  trailing: Text('${settings.variableRatioBonus}'),
                  onTap: () async {
                    final next = await _pickInt(
                      context,
                      title: 'Bonus points',
                      value: settings.variableRatioBonus,
                      min: 1,
                      max: 100,
                    );
                    if (next != null) {
                      await save(settings.copyWith(variableRatioBonus: next));
                    }
                  },
                ),
              ],
              ListTile(
                title: const Text('Streak window (hours)'),
                subtitle: Text(
                  'Consecutive successes within ${settings.streakWindowHours}h keep the streak. Abort does not reset it.',
                ),
                trailing: Text('${settings.streakWindowHours}h'),
                onTap: () async {
                  final next = await _pickInt(
                    context,
                    title: 'Streak window hours',
                    value: settings.streakWindowHours,
                    min: 1,
                    max: 72,
                  );
                  if (next != null) {
                    await save(settings.copyWith(streakWindowHours: next));
                  }
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle('Bonus prompts (24h unlock)'),
              Text(
                'Earn many points in 24 hours to unlock Mindfulness, Creative, '
                'Writing, and Values prompts for one day. They leave the rotation '
                'when the window ends; hit the threshold again to restore them.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  bonus.active ? Icons.auto_awesome : Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  bonus.active
                      ? 'Unlocked'
                      : 'Locked — ${bonus.pointsLast24h} / ${bonus.threshold} pts (24h)',
                ),
                subtitle: Text(
                  bonus.active && bonus.expiresAt != null
                      ? 'Ends ${bonus.expiresAt!.toLocal()}'
                      : 'High threshold by default; keep practicing to unlock.',
                ),
              ),
              Text(
                'Unlock threshold: ${settings.bonusUnlockThreshold} points / 24h',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: settings.bonusUnlockThreshold.toDouble().clamp(50, 500),
                min: 50,
                max: 500,
                divisions: 45,
                label: '${settings.bonusUnlockThreshold}',
                onChanged: (v) => save(
                  settings.copyWith(bonusUnlockThreshold: v.round()),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Theme'),
              SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.system,
                    label: Text('Sys'),
                    icon: Icon(Icons.brightness_auto),
                    tooltip: 'System',
                  ),
                  ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.highContrast,
                    label: Text('HC'),
                    icon: Icon(Icons.contrast),
                    tooltip: 'High contrast',
                  ),
                  ButtonSegment(
                    value: AppThemeMode.moreColors,
                    label: Text('MC'),
                    icon: Icon(Icons.palette_outlined),
                    tooltip: 'More colors',
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) =>
                    save(settings.copyWith(themeMode: s.first)),
              ),
              if (settings.themeMode == AppThemeMode.moreColors ||
                  settings.themeMode == AppThemeMode.light ||
                  settings.themeMode == AppThemeMode.dark) ...[
                const SizedBox(height: 12),
                Text(
                  settings.themeMode == AppThemeMode.light
                      ? 'Pick a color for Light mode. Pastels are darkened so text and buttons stay readable.'
                      : settings.themeMode == AppThemeMode.dark
                          ? 'Pick a color for Dark mode. Deep tones are lightened so text and buttons stay readable.'
                          : 'Pick a color. It is adjusted automatically so text and buttons stay visible in light and dark mode.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                BasicColorWheel(
                  color: Color(settings.customSeedColor),
                  onChanged: (c) {
                    save(settings.copyWith(customSeedColor: c.toARGB32()));
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => save(
                      settings.copyWith(customSeedColor: defaultSeedColorArgb),
                    ),
                    child: const Text('Reset to default green'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SectionTitle('Competing responses'),
              Text(
                'Library: ${responses.length} prompts '
                '(${responses.where((r) => r.enabled).length} enabled). '
                'Each Rip-Cord pull picks one at random — not reshuffled only on open.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                competingResponseDesignTip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ..._groupedResponseTiles(context, ref, responses),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final blank = repo.createBlankResponse();
                  await _editResponse(context, ref, blank, isNew: true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add custom response'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final n = await repo.refreshBuiltInResponses();
                  await repo.updateSettings(
                    repo.settings.copyWith(
                      responseLibraryVersion: currentResponseLibraryVersion,
                    ),
                  );
                  notifyDataChanged(ref);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Built-in library refreshed ($n prompts). Customs kept.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restore / refresh built-in prompts'),
              ),
              const SizedBox(height: 24),
              _SectionTitle('Activation methods'),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Settings tile',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Swipe down twice → pencil / edit → drag “Rip-Cord” into the panel. One tap starts the sequence.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Home-screen widget',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Long-press home screen → Widgets → Rip-Cord → place the 1×1 button. One tap activates.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Deep link',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text('ripcord://activate?source=tile'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Samsung side key',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'On One UI: Settings → Advanced features → Side button (or Side key). '
                        'Set Double press to Open app, then choose Rip-Cord.\n\n'
                        'If that menu is missing, try Settings → Advanced features and look for Side button / Side key.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  const channel =
                      MethodChannel('com.ripcord.rip_cord/activation');
                  try {
                    final opened = await channel.invokeMethod<bool>(
                      'openSideKeySettings',
                    );
                    if (context.mounted && opened != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not open Side button settings. Use Settings → Advanced features → Side button.',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Open Settings → Advanced features → Side button, then assign Rip-Cord.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Open Side button settings'),
              ),
              const SizedBox(height: 24),
              _SectionTitle('Data & privacy'),
              const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('100% on-device'),
                subtitle: Text(
                  'No cloud accounts. No network calls for core features. Logs stay on this phone.',
                ),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear all data?'),
                      content: const Text(
                        'This resets points, streak, log, and restores default responses.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await repo.clearAll();
                    notifyDataChanged(ref);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared.')),
                      );
                    }
                  }
                },
                child: const Text('Clear all data'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _groupedResponseTiles(
    BuildContext context,
    WidgetRef ref,
    List<CompetingResponse> responses,
  ) {
    final theme = Theme.of(context);
    final groups = <String, List<CompetingResponse>>{};
    for (final r in responses) {
      final key = (r.category == null || r.category!.trim().isEmpty)
          ? 'Other'
          : r.category!;
      groups.putIfAbsent(key, () => []).add(r);
    }

    // Prefer a stable category order for built-ins.
    const preferred = [
      'Breathing',
      'Grounding',
      'Movement',
      'Reframe',
      'Action',
      'Mindfulness',
      'Creative',
      'Writing',
      'Values',
      'Custom',
      'Other',
    ];
    final keys = [
      ...preferred.where(groups.containsKey),
      ...groups.keys.where((k) => !preferred.contains(k)),
    ];

    final bonusActive =
        ref.read(repositoryProvider).settings.isBonusUnlockActive();

    final widgets = <Widget>[];
    for (final key in keys) {
      final isBonusGroup = groups[key]!.any((r) => r.requiresBonusUnlock);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Text(
                key,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isBonusGroup) ...[
                const SizedBox(width: 8),
                Icon(
                  bonusActive ? Icons.auto_awesome : Icons.lock,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  bonusActive ? 'In rotation' : 'Needs unlock',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      for (final r in groups[key]!) {
        final subtitleParts = <String>[
          if (r.requiresBonusUnlock) 'Bonus',
          if (r.actionPrompt != null && r.actionPrompt!.isNotEmpty)
            r.actionPrompt!,
        ];
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                r.phrase,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: subtitleParts.isEmpty
                  ? null
                  : Text(
                      subtitleParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              leading: Icon(
                r.requiresBonusUnlock && !bonusActive
                    ? Icons.lock_outline
                    : (r.enabled
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                color: r.enabled && (!r.requiresBonusUnlock || bonusActive)
                    ? theme.colorScheme.primary
                    : null,
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editResponse(context, ref, r),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _editResponse(
    BuildContext context,
    WidgetRef ref,
    CompetingResponse response, {
    bool isNew = false,
  }) async {
    final phraseCtrl = TextEditingController(text: response.phrase);
    final actionCtrl =
        TextEditingController(text: response.actionPrompt ?? '');
    final categoryCtrl =
        TextEditingController(text: response.category ?? (isNew ? 'Custom' : ''));
    var enabled = response.enabled;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isNew ? 'New response' : 'Edit response',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep it short: aim for 15–30 seconds total (thought + action).',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phraseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Replacement thought',
                        helperText: 'One short reframe you can read once.',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: actionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Action prompt (optional)',
                        helperText:
                            'Concrete steps that fit in about 15–30 seconds.',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        helperText:
                            'e.g. Breathing, Grounding, Movement, Reframe, Action, Custom',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enabled in rotation'),
                      value: enabled,
                      onChanged: (v) => setModal(() => enabled = v),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        if (phraseCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Save'),
                    ),
                    if (!isNew)
                      TextButton(
                        onPressed: () async {
                          final repo = ref.read(repositoryProvider);
                          await repo.deleteResponse(response.id);
                          notifyDataChanged(ref);
                          if (ctx.mounted) Navigator.pop(ctx, false);
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (saved == true) {
      final repo = ref.read(repositoryProvider);
      final cat = categoryCtrl.text.trim();
      await repo.saveResponse(
        response.copyWith(
          phrase: phraseCtrl.text.trim(),
          actionPrompt: actionCtrl.text.trim().isEmpty
              ? null
              : actionCtrl.text.trim(),
          clearActionPrompt: actionCtrl.text.trim().isEmpty,
          category: cat.isEmpty ? null : cat,
          clearCategory: cat.isEmpty,
          enabled: enabled,
        ),
      );
      notifyDataChanged(ref);
    }

    phraseCtrl.dispose();
    actionCtrl.dispose();
    categoryCtrl.dispose();
  }

  Future<int?> _pickInt(
    BuildContext context, {
    required String title,
    required int value,
    required int min,
    required int max,
  }) async {
    var current = value;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return AlertDialog(
              title: Text(title),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: current <= min
                        ? null
                        : () => setD(() => current--),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$current', style: Theme.of(ctx).textTheme.headlineSmall),
                  IconButton(
                    onPressed: current >= max
                        ? null
                        : () => setD(() => current++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, current),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
