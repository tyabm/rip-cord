import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/expectation.dart';
import '../../domain/handoff.dart';
import '../../providers/app_providers.dart';
import '../../services/expectation_nudge.dart';
import '../../services/handoff_service.dart';
import '../common/app_chrome.dart';
import '../common/check_in_button.dart';
import '../expectation/outcome_rating.dart';

/// How long the calm acknowledgement stays before Rip-Cord leaves.
const Duration doneLeaveDelay = Duration(seconds: 4);

/// Brief close of a pull. Not a celebration, and it does not return Home.
class DoneScreen extends ConsumerStatefulWidget {
  const DoneScreen({super.key});

  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen> {
  Timer? _leaveTimer;
  bool _left = false;
  ExpectationCheck? _unrated;
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _leaveTimer = Timer(doneLeaveDelay, _leave);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUnrated());
  }

  void _loadUnrated() {
    if (!mounted) return;
    final repo = ref.read(repositoryProvider);
    if (!repo.settings.expectationCheckEnabled) return;
    final check = closingScreenCheck(repo.expectationChecks);
    if (check == null) return;
    setState(() => _unrated = check);
  }

  Future<void> _rate(int value) async {
    final check = _unrated;
    if (check == null || _selectedRating != null || _left) return;
    _leaveTimer?.cancel();
    setState(() => _selectedRating = value);
    final repo = ref.read(repositoryProvider);
    await repo.rateExpectation(id: check.id, rating: value);
    await expectationNudge.cancel(check.id);
    notifyDataChanged(ref);
    if (!mounted || _left) return;
    _leaveTimer = Timer(const Duration(seconds: 2), _leave);
  }

  @override
  void dispose() {
    _leaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_left) return;
    _left = true;
    _leaveTimer?.cancel();
    final settings = ref.read(settingsProvider);
    try {
      if (handoffIsReady(settings)) {
        await launchConfiguredHandoff(settings);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (_) {
      // Still leave if Clock, music, or the dialer cannot open.
    }
    exitRipCordApp();
  }

  void _pauseForCheckIn() {
    _leaveTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rip-Cord'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Exit',
            onPressed: _leave,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.check_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Done',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                leaveAcknowledgement(settings),
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_unrated != null) ...[
                Text(
                  expectationFraming,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  outcomeRatingQuestion(_unrated!.expectation),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutcomeRatingRow(
                  selected: _selectedRating,
                  onSelected: _selectedRating == null
                      ? (value) {
                          _rate(value);
                        }
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedRating == null
                      ? expectationScaleCaption
                      : 'Saved on this phone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              TrustedCheckInButton(onOpened: _pauseForCheckIn),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _leave,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Leave now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
