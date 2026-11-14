import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/urge_drill.dart';
import '../../providers/app_providers.dart';
import '../common/app_chrome.dart';
import '../common/check_in_button.dart';

enum _DrillPhase { name, choose, practice }

/// Name the urge, do one physical action, then leave. No points, no reward.
class DrillScreen extends ConsumerStatefulWidget {
  const DrillScreen({super.key, required this.source});

  final ActivationSource source;

  @override
  ConsumerState<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends ConsumerState<DrillScreen> {
  final _urgeCtrl = TextEditingController();
  _DrillPhase _phase = _DrillPhase.name;
  String? _chip;
  DrillAction? _action;
  String? _eventId;
  int _elapsed = 0;
  Timer? _timer;
  bool _finishing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _urgeCtrl.dispose();
    super.dispose();
  }

  String? get _urge {
    final typed = _urgeCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    final chip = _chip?.trim();
    if (chip == null || chip.isEmpty) return null;
    return chip;
  }

  Future<void> _beginPractice() async {
    final urge = _urge;
    final action = _action;
    if (urge == null || action == null || _finishing) return;

    final repo = ref.read(repositoryProvider);
    final event = await repo.startDrill(
      source: widget.source,
      urge: urge,
      action: action,
    );
    notifyDataChanged(ref);
    if (!mounted) return;

    setState(() {
      _eventId = event.id;
      _phase = _DrillPhase.practice;
      _elapsed = 0;
    });

    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    await HapticFeedback.mediumImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= drillPracticeSeconds) {
        timer.cancel();
        HapticFeedback.lightImpact();
        unawaited(_complete());
      }
    });
  }

  Future<void> _complete() async {
    if (_finishing || _eventId == null) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    final repo = ref.read(repositoryProvider);
    await repo.completeDrill(eventId: _eventId!, durationSec: _elapsed);
    ref.read(activeSequenceProvider.notifier).state = null;
    notifyDataChanged(ref);
    if (!mounted) return;
    context.go('/done');
  }

  Future<void> _stop() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    if (_eventId != null) {
      final repo = ref.read(repositoryProvider);
      await repo.abortActivation(eventId: _eventId!, durationSec: _elapsed);
      notifyDataChanged(ref);
    }
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _exitApp() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    if (_eventId != null) {
      final repo = ref.read(repositoryProvider);
      await repo.abortActivation(eventId: _eventId!, durationSec: _elapsed);
      notifyDataChanged(ref);
    }
    exitRipCordApp();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Urge drill'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Exit',
            onPressed: _finishing ? null : _exitApp,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: switch (_phase) {
        _DrillPhase.name => _NameStep(
            controller: _urgeCtrl,
            chip: _chip,
            onChip: (value) => setState(() => _chip = value),
            onChanged: () => setState(() {}),
            canContinue: _urge != null,
            onContinue: () => setState(() => _phase = _DrillPhase.choose),
          ),
        _DrillPhase.choose => _ChooseStep(
            selected: _action,
            onSelected: (action) => setState(() => _action = action),
            onBack: () => setState(() => _phase = _DrillPhase.name),
            onStart: _action == null ? null : _beginPractice,
          ),
        _DrillPhase.practice => _PracticeStep(
            urge: _urge ?? '',
            action: _action!,
            elapsed: _elapsed,
            finishing: _finishing,
            onStop: _stop,
          ),
      },
    );

    if (!settings.grayscaleDuringSequence) return content;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: content,
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.chip,
    required this.onChip,
    required this.onChanged,
    required this.canContinue,
    required this.onContinue,
  });

  final TextEditingController controller;
  final String? chip;
  final ValueChanged<String?> onChip;
  final VoidCallback onChanged;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Name the urge',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One line is enough. Then a single physical move, and you leave.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in urgeNameChips)
                      ChoiceChip(
                        label: Text(label),
                        selected: chip == label,
                        onSelected: (selected) =>
                            onChip(selected ? label : null),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Or type it',
                    hintText: 'One short line',
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: canContinue ? onContinue : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Next'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChooseStep extends StatelessWidget {
  const _ChooseStep({
    required this.selected,
    required this.onSelected,
    required this.onBack,
    required this.onStart,
  });

  final DrillAction? selected;
  final ValueChanged<DrillAction> onSelected;
  final VoidCallback onBack;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: RadioGroup<DrillAction>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    'One physical action',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final action in drillActions)
                  RadioListTile<DrillAction>(
                    value: action,
                    title: Text(action.label),
                    subtitle: Text(action.instruction),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                TextButton(onPressed: onBack, child: const Text('Back')),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PracticeStep extends StatelessWidget {
  const _PracticeStep({
    required this.urge,
    required this.action,
    required this.elapsed,
    required this.finishing,
    required this.onStop,
  });

  final String urge;
  final DrillAction action;
  final int elapsed;
  final bool finishing;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (drillPracticeSeconds - elapsed).clamp(0, drillPracticeSeconds);
    final progress = (elapsed / drillPracticeSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                Text(
                  urge,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  action.instruction,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$remaining',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'seconds',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Do it once. Rip-Cord leaves when the timer ends.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const TrustedCheckInButton(),
                TextButton(
                  onPressed: finishing ? null : onStop,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
