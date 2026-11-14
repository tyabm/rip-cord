import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/models.dart';
import 'package:rip_cord/domain/reinforcement.dart';

void main() {
  const engine = ReinforcementEngine();

  group('ReinforcementEngine', () {
    test('awards base points only', () {
      final settings = AppSettings(
        basePoints: 10,
        currentPoints: 50,
        currentStreak: 0,
      );

      final result = engine.complete(settings: settings);

      expect(result.basePoints, 10);
      expect(result.pointsAwarded, 10);
      expect(result.totalPoints, 60);
      expect(result.newStreak, 1);
    });

    test('increments streak within window', () {
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
