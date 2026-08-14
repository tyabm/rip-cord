import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/models.dart';
import 'package:rip_cord/domain/reinforcement.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value > 0.5;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('ReinforcementEngine', () {
    test('awards base points without bonus when roll misses', () {
      final engine = ReinforcementEngine(random: _FixedRandom(0.99));
      final settings = AppSettings(
        basePoints: 10,
        variableRatioEnabled: true,
        variableRatioChance: 0.2,
        variableRatioBonus: 15,
        currentPoints: 50,
        currentStreak: 0,
      );

      final result = engine.complete(settings: settings);

      expect(result.basePoints, 10);
      expect(result.bonusPoints, 0);
      expect(result.pointsAwarded, 10);
      expect(result.totalPoints, 60);
      expect(result.newStreak, 1);
    });

    test('awards variable-ratio bonus when roll hits', () {
      final engine = ReinforcementEngine(random: _FixedRandom(0.05));
      final settings = AppSettings(
        basePoints: 10,
        variableRatioEnabled: true,
        variableRatioChance: 0.2,
        variableRatioBonus: 15,
        currentPoints: 0,
      );

      final result = engine.complete(settings: settings);
      expect(result.bonusPoints, 15);
      expect(result.pointsAwarded, 25);
      expect(result.hadBonus, isTrue);
    });

    test('increments streak within window', () {
      final engine = ReinforcementEngine(random: _FixedRandom(0.99));
      final now = DateTime(2026, 8, 5, 12);
      final settings = AppSettings(
        currentStreak: 3,
        bestStreak: 5,
        streakWindowHours: 24,
        lastSuccessAt: now.subtract(const Duration(hours: 2)),
      );

      final result = engine.complete(settings: settings, now: now);
      expect(result.newStreak, 4);
      expect(result.bestStreak, 5);
    });

    test('resets streak outside window', () {
      final engine = ReinforcementEngine(random: _FixedRandom(0.99));
      final now = DateTime(2026, 8, 5, 12);
      final settings = AppSettings(
        currentStreak: 7,
        bestStreak: 7,
        streakWindowHours: 24,
        lastSuccessAt: now.subtract(const Duration(hours: 30)),
      );

      final result = engine.complete(settings: settings, now: now);
      expect(result.newStreak, 1);
      expect(result.bestStreak, 7);
    });

    test('updates best streak', () {
      final engine = ReinforcementEngine(random: _FixedRandom(0.99));
      final now = DateTime(2026, 8, 5, 12);
      final settings = AppSettings(
        currentStreak: 5,
        bestStreak: 5,
        lastSuccessAt: now.subtract(const Duration(hours: 1)),
      );

      final result = engine.complete(settings: settings, now: now);
      expect(result.newStreak, 6);
      expect(result.bestStreak, 6);
    });
  });
}
