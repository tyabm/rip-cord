import 'dart:math';

import 'models.dart';

/// Longest gap between consecutive *completed* activations (free period proxy).
Duration? longestFreePeriod(List<ActivationEvent> events, {DateTime? now}) {
  final completed = events
      .where((e) => e.outcome == ActivationOutcome.completed)
      .map((e) => e.completedAt ?? e.startedAt)
      .toList()
    ..sort();

  if (completed.isEmpty) return null;

  Duration? longest;
  for (var i = 1; i < completed.length; i++) {
    final gap = completed[i].difference(completed[i - 1]);
    if (longest == null || gap > longest) longest = gap;
  }

  // Include open interval from last completion to now (optional shaping signal).
  final open = (now ?? DateTime.now()).difference(completed.last);
  if (longest == null || open > longest) longest = open;

  return longest;
}

CompetingResponse? pickWeightedResponse(
  List<CompetingResponse> responses, {
  Random? random,
  String? excludeId,
  /// When false, responses with [CompetingResponse.requiresBonusUnlock] are skipped.
  bool includeBonusUnlock = true,
}) {
  var enabled = responses
      .where(
        (r) =>
            r.enabled && (includeBonusUnlock || !r.requiresBonusUnlock),
      )
      .toList();
  if (enabled.isEmpty) return null;

  // Avoid immediate repeat when there is at least one other option.
  if (excludeId != null && enabled.length > 1) {
    final without = enabled.where((r) => r.id != excludeId).toList();
    if (without.isNotEmpty) enabled = without;
  }

  final totalWeight = enabled.fold<int>(0, (sum, r) => sum + r.weight);
  if (totalWeight <= 0) return enabled.first;

  final rng = random ?? Random();
  var roll = rng.nextInt(totalWeight);
  for (final r in enabled) {
    roll -= r.weight;
    if (roll < 0) return r;
  }
  return enabled.last;
}
