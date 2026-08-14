import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/breath_pattern.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../../services/tts_service.dart';
import 'breath_guide.dart';

class SequenceScreen extends ConsumerStatefulWidget {
  const SequenceScreen({super.key, required this.source});

  final ActivationSource source;

  @override
  ConsumerState<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends ConsumerState<SequenceScreen> {
  String? _eventId;
  CompetingResponse? _response;
  BreathPattern? _breathPattern;
  int _targetSec = 20;
  int _elapsed = 0;
  Timer? _timer;
  bool _starting = true;
  bool _finishing = false;
  bool _canComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final repo = ref.read(repositoryProvider);
    await repo.load();
    final result = await repo.startActivation(source: widget.source);
    final settings = repo.settings;
    final pattern = breathPatternFor(result.response);

    if (!mounted) return;

    setState(() {
      _eventId = result.event.id;
      _response = result.response;
      _breathPattern = pattern;
      _targetSec = settings.sequenceDurationSec.clamp(10, 45);
      _starting = false;
      _canComplete = false;
    });

    ref.read(activeSequenceProvider.notifier).state = ActiveSequence(
      eventId: result.event.id,
      response: result.response,
      source: widget.source,
      startedAt: result.event.startedAt,
      targetDurationSec: _targetSec,
    );

    notifyDataChanged(ref);

    // Avoid TTS talking over breath chimes for breathing guides.
    if (settings.ttsEnabled && pattern == null) {
      final text = [
        result.response.phrase,
        if (result.response.actionPrompt != null) result.response.actionPrompt!,
      ].join(' ');
      unawaited(ttsService.speak(text));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_elapsed >= _targetSec) {
          _canComplete = true;
          t.cancel();
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(ttsService.stop());
    super.dispose();
  }

  Future<void> _complete() async {
    if (_finishing || _eventId == null || !_canComplete) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    await ttsService.stop();
    HapticFeedback.mediumImpact();

    final repo = ref.read(repositoryProvider);
    final result = await repo.completeActivation(
      eventId: _eventId!,
      durationSec: _elapsed,
    );
    ref.read(lastRewardProvider.notifier).state = result;
    ref.read(activeSequenceProvider.notifier).state = null;
    notifyDataChanged(ref);

    if (!mounted) return;
    context.go('/reward');
  }

  Future<void> _abort() async {
    if (_finishing || _eventId == null) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    await ttsService.stop();

    final repo = ref.read(repositoryProvider);
    await repo.abortActivation(eventId: _eventId!, durationSec: _elapsed);
    ref.read(activeSequenceProvider.notifier).state = null;
    notifyDataChanged(ref);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged as incomplete — no points awarded.')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final progress =
        _targetSec == 0 ? 0.0 : (_elapsed / _targetSec).clamp(0.0, 1.0);
    final remaining = (_targetSec - _elapsed).clamp(0, _targetSec);
    final showBreath = _breathPattern != null;

    Widget body;
    if (_starting || _response == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Competing response',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _response!.phrase,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_response!.actionPrompt != null &&
                      _response!.actionPrompt!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              showBreath
                                  ? Icons.air
                                  : Icons.directions_run,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _response!.actionPrompt!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (showBreath)
                    Center(
                      child: BreathGuide(
                        pattern: _breathPattern!,
                        size: 220,
                        chimesEnabled: true,
                      ),
                    )
                  else
                    Center(
                      child: SizedBox(
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
                    ),
                  const SizedBox(height: 16),
                  if (showBreath) ...[
                    // Session countdown under the breath orb
                    Text(
                      _canComplete
                          ? 'Ready — mark complete when finished.'
                          : 'Session: ${remaining}s remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else
                    Text(
                      _canComplete
                          ? 'Ready — mark complete when finished.'
                          : 'Stay with the response until the timer ends.',
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
                  FilledButton(
                    onPressed: _canComplete && !_finishing ? _complete : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('I completed this'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _finishing ? null : _abort,
                    child: const Text('Abort (no points)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Rip-Cord'),
        automaticallyImplyLeading: false,
      ),
      body: body,
    );

    if (settings.grayscaleDuringSequence) {
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
    return content;
  }
}
