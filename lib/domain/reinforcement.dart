import 'models.dart';

/// Quiet point and streak record. A completion awards base points only.
class ReinforcementEngine {
  const ReinforcementEngine();

  ReinforcementResult complete({
    required AppSettings settings,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final base = settings.basePoints;

    final withinWindow = settings.lastSuccessAt != null &&
        moment.difference(settings.lastSuccessAt!) <=
            Duration(hours: settings.streakWindowHours);

    final newStreak = withinWindow ? settings.currentStreak + 1 : 1;
    final best = newStreak > settings.bestStreak ? newStreak : settings.bestStreak;
    final total = settings.currentPoints + base;

    return ReinforcementResult(
      basePoints: base,
      newStreak: newStreak,
      bestStreak: best,
      totalPoints: total,
    );
  }
}
