import 'dart:math';

import 'models.dart';

/// Pure reinforcement engine — easy to unit test.
class ReinforcementEngine {
  ReinforcementEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ReinforcementResult complete({
    required AppSettings settings,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final base = settings.basePoints;
    var bonus = 0;
    if (settings.variableRatioEnabled &&
        _random.nextDouble() < settings.variableRatioChance) {
      bonus = settings.variableRatioBonus;
    }

    final withinWindow = settings.lastSuccessAt != null &&
        moment.difference(settings.lastSuccessAt!) <=
            Duration(hours: settings.streakWindowHours);

    final newStreak = withinWindow ? settings.currentStreak + 1 : 1;
    final best = newStreak > settings.bestStreak ? newStreak : settings.bestStreak;
    final total = settings.currentPoints + base + bonus;

    return ReinforcementResult(
      basePoints: base,
      bonusPoints: bonus,
      newStreak: newStreak,
      bestStreak: best,
      totalPoints: total,
    );
  }
}
