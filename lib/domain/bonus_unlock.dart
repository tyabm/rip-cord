import 'models.dart';

/// Sum of points on completed activations in the last [window].
int pointsInLast24Hours(
  List<ActivationEvent> events, {
  DateTime? now,
  Duration window = const Duration(hours: 24),
}) {
  final n = now ?? DateTime.now();
  final start = n.subtract(window);
  var sum = 0;
  for (final e in events) {
    if (e.outcome != ActivationOutcome.completed) continue;
    final at = e.completedAt ?? e.startedAt;
    if (!at.isBefore(start) && !at.isAfter(n)) {
      sum += e.pointsAwarded;
    }
  }
  return sum;
}

/// Whether bonus prompts should be in the rotation.
bool isBonusUnlockActive(AppSettings settings, {DateTime? now}) {
  return settings.isBonusUnlockActive(now);
}

/// Eligible pool for weighted pick.
List<CompetingResponse> rotationPool(
  List<CompetingResponse> responses, {
  required bool bonusActive,
}) {
  return responses
      .where(
        (r) =>
            r.enabled && (!r.requiresBonusUnlock || bonusActive),
      )
      .toList();
}

/// If unlock is inactive and points meet threshold, return new expiry.
/// Does not extend an already-active window.
DateTime? maybeGrantBonusUnlock({
  required AppSettings settings,
  required int pointsLast24h,
  DateTime? now,
  Duration unlockDuration = const Duration(hours: 24),
}) {
  final n = now ?? DateTime.now();
  if (settings.isBonusUnlockActive(n)) return null;
  if (pointsLast24h < settings.bonusUnlockThreshold) return null;
  return n.add(unlockDuration);
}
