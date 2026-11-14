import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seed.dart';
import '../../domain/handoff.dart';
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
                title: const Text('Grayscale during practice'),
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
              _SectionTitle('After a pull'),
              Text(
                'Choose one optional next step. Rip-Cord opens it, then leaves. '
                'If you choose none, the app just closes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              RadioGroup<HandoffKind>(
                groupValue: settings.handoffKind,
                onChanged: (value) {
                  if (value != null) {
                    save(settings.copyWith(handoffKind: value));
                  }
                },
                child: const Column(
                  children: [
                    RadioListTile<HandoffKind>(
                      value: HandoffKind.none,
                      contentPadding: EdgeInsets.zero,
                      title: Text('None'),
                      subtitle: Text('Close Rip-Cord'),
                    ),
                    RadioListTile<HandoffKind>(
                      value: HandoffKind.walkTimer,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Walk timer'),
                      subtitle: Text('Hand a timer to the Clock app'),
                    ),
                    RadioListTile<HandoffKind>(
                      value: HandoffKind.music,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Music'),
                      subtitle: Text('Open a playlist or link'),
                    ),
                    RadioListTile<HandoffKind>(
                      value: HandoffKind.call,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Call'),
                      subtitle: Text('Open the dialer for your trusted person'),
                    ),
                  ],
                ),
              ),
              if (settings.handoffKind == HandoffKind.walkTimer) ...[
                Text(
                  'Walk length: ${settings.walkTimerMinutes} min',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: settings.walkTimerMinutes.toDouble().clamp(5, 30),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: '${settings.walkTimerMinutes} min',
                  onChanged: (v) => save(
                    settings.copyWith(walkTimerMinutes: v.round()),
                  ),
                ),
              ],
              if (settings.handoffKind == HandoffKind.music) ...[
                _RememberedField(
                  value: settings.musicUri ?? '',
                  label: 'Playlist or music link',
                  helper: musicLaunchUri(settings.musicUri) == null &&
                          (settings.musicUri ?? '').isNotEmpty
                      ? 'Use a full link, such as a Spotify or YouTube Music URL.'
                      : 'Paste a link your phone can open. Rip-Cord does not play it itself.',
                  keyboardType: TextInputType.url,
                  onSave: (value) {
                    final current = ref.read(repositoryProvider).settings;
                    final trimmed = value.trim();
                    return save(
                      current.copyWith(
                        musicUri: trimmed.isEmpty ? null : trimmed,
                        clearMusicUri: trimmed.isEmpty,
                      ),
                    );
                  },
                ),
              ],
              if (settings.handoffKind == HandoffKind.call &&
                  dialerUri(settings.trustedPersonPhone) == null)
                Text(
                  'Add a phone number under Trusted person. Until then, a pull just closes the app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              const SizedBox(height: 16),
              _SectionTitle('Urge drill'),
              Text(
                'Name the urge, do one short physical action, then leave. '
                'Under a minute. No points.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use the urge drill as the default pull'),
                subtitle: const Text(
                  'The Rip-Cord button, Quick Settings tile, widget, and deep link open the drill. A prompt is still available on Home.',
                ),
                value: settings.drillIsDefaultPull,
                onChanged: (v) =>
                    save(settings.copyWith(drillIsDefaultPull: v)),
              ),
              const SizedBox(height: 8),
              _SectionTitle('Trusted person'),
              Text(
                'Optional. Type a name and number yourself. Rip-Cord does not read your contacts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _RememberedField(
                value: settings.trustedPersonName ?? '',
                label: 'Name',
                keyboardType: TextInputType.name,
                onSave: (value) {
                  final current = ref.read(repositoryProvider).settings;
                  final trimmed = value.trim();
                  return save(
                    current.copyWith(
                      trustedPersonName: trimmed.isEmpty ? null : trimmed,
                      clearTrustedPersonName: trimmed.isEmpty,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _RememberedField(
                value: settings.trustedPersonPhone ?? '',
                label: 'Phone number',
                helper:
                    'Stays on this phone. A button during a pull opens your SMS app with a blank message. Rip-Cord never sends the text.',
                keyboardType: TextInputType.phone,
                onSave: (value) {
                  final current = ref.read(repositoryProvider).settings;
                  final trimmed = value.trim();
                  return save(
                    current.copyWith(
                      trustedPersonPhone: trimmed.isEmpty ? null : trimmed,
                      clearTrustedPersonPhone: trimmed.isEmpty,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle('Private record'),
              Text(
                'Points and streak stay in Log. A pull does not celebrate them, and stopping does not reset the streak.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Base points'),
                subtitle: Text('${settings.basePoints} per completed prompt'),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Streak window (hours)'),
                subtitle: Text(
                  'Successes within ${settings.streakWindowHours}h keep the streak.',
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
                'Mindfulness, Creative, Writing, and Values are always in the rotation. '
                'Each pull picks one enabled prompt at random.',
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
                  'No cloud accounts. No network calls for core features. Logs stay on this phone. '
                  'A trusted person\'s name and number, if you type them, stay on this device. '
                  'Rip-Cord does not read contacts, send messages, or track replies.',
                ),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear all data?'),
                      content: const Text(
                        'This resets the log, the private points and streak record, hand-off choices, the trusted person, and restores default responses.',
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

    final widgets = <Widget>[];
    for (final key in keys) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            key,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      for (final r in groups[key]!) {
        final action = r.actionPrompt;
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                r.phrase,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: action == null || action.isEmpty
                  ? null
                  : Text(
                      action,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              leading: Icon(
                r.enabled ? Icons.check_circle : Icons.circle_outlined,
                color: r.enabled ? theme.colorScheme.primary : null,
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

class _RememberedField extends StatefulWidget {
  const _RememberedField({
    required this.value,
    required this.label,
    required this.onSave,
    this.helper,
    this.keyboardType,
  });

  final String value;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;
  final Future<void> Function(String value) onSave;

  @override
  State<_RememberedField> createState() => _RememberedFieldState();
}

class _RememberedFieldState extends State<_RememberedField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant _RememberedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _commit();
    }
  }

  Future<void> _commit() async {
    if (_controller.text.trim() == widget.value.trim()) return;
    await widget.onSave(_controller.text);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      onEditingComplete: _commit,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 3,
      ),
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
