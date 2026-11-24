import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/expectation.dart';
import '../../providers/app_providers.dart';
import '../../services/expectation_nudge.dart';
import 'outcome_rating.dart';

/// Asks once about an unrated hope when a resting screen is showing.
/// A pull that is already on screen asks instead.
class PendingOutcomePrompt extends ConsumerStatefulWidget {
  const PendingOutcomePrompt({super.key});

  @override
  ConsumerState<PendingOutcomePrompt> createState() =>
      _PendingOutcomePromptState();
}

class _PendingOutcomePromptState extends ConsumerState<PendingOutcomePrompt>
    with WidgetsBindingObserver {
  GoRouter? _router;
  bool _started = false;

  void _onRouteChanged() {
    _maybeAsk();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GoRouter.maybeOf(context);
    if (!identical(next, _router)) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = next;
      _router?.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeAsk();
  }

  bool _shellIsVisible() {
    final router = _router;
    if (router == null) return true;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    return path == '/' || path == '/log' || path == '/settings';
  }

  Future<void> _maybeAsk() async {
    if (!mounted || _started) return;
    if (!_shellIsVisible()) return;
    final settings = ref.read(settingsProvider);
    if (!settings.expectationCheckEnabled) return;
    final repo = ref.read(repositoryProvider);
    final pending = pendingRatingAsk(repo.expectationChecks);
    if (pending == null) return;
    if (!RatingAskLock.tryBegin()) return;
    _started = true;
    try {
      if (!mounted) return;
      final ratingFuture = showOutcomeRatingDialog(context, pending);
      await repo.markRatingAsked(pending.id);
      if (!mounted) return;
      await expectationNudge.cancel(pending.id);
      if (!mounted) return;
      notifyDataChanged(ref);
      final rating = await ratingFuture;
      if (rating != null && mounted) {
        await repo.rateExpectation(id: pending.id, rating: rating);
        if (!mounted) return;
        notifyDataChanged(ref);
      }
    } finally {
      RatingAskLock.end();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
