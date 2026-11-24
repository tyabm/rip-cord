import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/expectation.dart';
import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../../services/expectation_nudge.dart';
import '../common/app_chrome.dart';
import '../drill/drill_screen.dart';
import '../sequence/sequence_screen.dart';
import 'outcome_rating.dart';

enum PullKind { prompt, drill }

enum _Step { loading, rating, expectation, mirror }

/// Expectation question, then the existing prompt or drill.
/// When the check is off, the practice starts immediately.
class PullFlow extends ConsumerStatefulWidget {
  const PullFlow({super.key, required this.source, required this.kind});

  final ActivationSource source;
  final PullKind kind;

  @override
  ConsumerState<PullFlow> createState() => _PullFlowState();
}

class _PullFlowState extends ConsumerState<PullFlow> {
  _Step _step = _Step.loading;
  bool _ready = false;
  bool _busy = false;
  ExpectationCheck? _ratingCheck;
  String? _mirrorLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final repo = ref.read(repositoryProvider);
    await repo.load();
    if (!mounted) return;
    if (!repo.settings.expectationCheckEnabled) {
      setState(() => _ready = true);
      return;
    }

    final pending = pendingRatingAsk(repo.expectationChecks);
    if (pending != null && RatingAskLock.tryBegin()) {
      if (!mounted) {
        RatingAskLock.end();
        return;
      }
      setState(() {
        _ratingCheck = pending;
        _step = _Step.rating;
      });
      try {
        await repo.markRatingAsked(pending.id);
        if (!mounted) return;
        await expectationNudge.cancel(pending.id);
        if (!mounted) return;
        notifyDataChanged(ref);
      } finally {
        RatingAskLock.end();
      }
      return;
    }

    setState(() => _step = _Step.expectation);
  }

  Future<void> _onRated(int score) async {
    final check = _ratingCheck;
    if (check == null || _busy) return;
    setState(() => _busy = true);
    final repo = ref.read(repositoryProvider);
    await repo.rateExpectation(id: check.id, rating: score);
    if (!mounted) return;
    notifyDataChanged(ref);
    setState(() {
      _busy = false;
      _ratingCheck = null;
      _step = _Step.expectation;
    });
  }

  void _skipRating() {
    if (_busy) return;
    setState(() {
      _ratingCheck = null;
      _step = _Step.expectation;
    });
  }

  Future<void> _choose(ExpectationKind kind) async {
    if (_busy || _ready) return;
    setState(() => _busy = true);
    final repo = ref.read(repositoryProvider);
    final check = await repo.recordExpectation(kind);
    if (!mounted) return;
    ref.read(openExpectationCheckIdProvider.notifier).state = check.id;
    if (repo.settings.expectationNudgeEnabled) {
      final scheduled = await scheduleExpectationNudge(check);
      if (scheduled) {
        await repo.markNudgeScheduled(check.id);
      }
    }
    notifyDataChanged(ref);
    if (!mounted) return;
    final line = expectationMirrorLine(kind, repo.expectationChecks);
    if (line == null) {
      setState(() {
        _busy = false;
        _ready = true;
      });
      return;
    }
    setState(() {
      _busy = false;
      _mirrorLine = line;
      _step = _Step.mirror;
    });
  }

  void _skipExpectation() {
    if (_busy) return;
    ref.read(openExpectationCheckIdProvider.notifier).state = null;
    setState(() => _ready = true);
  }

  void _continueFromMirror() {
    if (_busy) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      if (widget.kind == PullKind.drill) {
        return DrillScreen(
          key: const ValueKey('pull-drill'),
          source: widget.source,
        );
      }
      return SequenceScreen(
        key: const ValueKey('pull-prompt'),
        source: widget.source,
      );
    }

    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget body;
    if (_step == _Step.loading ||
        (_step == _Step.rating && _ratingCheck == null)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_step == _Step.rating) {
      body = _PromptColumn(
        title: outcomeRatingQuestion(_ratingCheck!.expectation),
        caption: expectationScaleCaption,
        skip: _skipRating,
        children: [
          OutcomeRatingRow(
            onSelected: _busy
                ? null
                : (score) {
                    _onRated(score);
                  },
          ),
        ],
      );
    } else if (_step == _Step.mirror) {
      body = _PromptColumn(
        title: _mirrorLine ?? '',
        children: [
          FilledButton(
            onPressed: _continueFromMirror,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text('Continue'),
          ),
        ],
      );
    } else {
      body = _PromptColumn(
        title: expectationPromptQuestion,
        caption: 'One tap. Your answer stays on this phone.',
        skip: _skipExpectation,
        children: [
          for (final option in expectationOptions) ...[
            FilledButton.tonal(
              onPressed: _busy
                  ? null
                  : () {
                      _choose(option.kind);
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(option.label),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rip-Cord'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Exit',
            onPressed: exitRipCordApp,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                expectationFraming,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(child: body),
              Text(
                'You can put the phone down when the practice ends.',
                style: quiet,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptColumn extends StatelessWidget {
  const _PromptColumn({
    required this.title,
    this.caption,
    this.skip,
    required this.children,
  });

  final String title;
  final String? caption;
  final VoidCallback? skip;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (caption != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    caption!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
        if (skip != null)
          TextButton(
            onPressed: skip,
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Skip'),
          ),
      ],
    );
  }
}
