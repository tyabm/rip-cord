import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/bonus_seed.dart';
import 'package:rip_cord/data/seed.dart';
import 'package:rip_cord/domain/bonus_unlock.dart';
import 'package:rip_cord/domain/free_period.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  group('pointsInLast24Hours', () {
    test('sums completed points in window only', () {
      final now = DateTime(2026, 8, 6, 12);
      final events = [
        ActivationEvent(
          id: '1',
          startedAt: now.subtract(const Duration(hours: 2)),
          completedAt: now.subtract(const Duration(hours: 2)),
          outcome: ActivationOutcome.completed,
          pointsAwarded: 10,
          source: ActivationSource.fab,
        ),
        ActivationEvent(
          id: '2',
          startedAt: now.subtract(const Duration(hours: 30)),
          completedAt: now.subtract(const Duration(hours: 30)),
          outcome: ActivationOutcome.completed,
          pointsAwarded: 50,
          source: ActivationSource.fab,
        ),
        ActivationEvent(
          id: '3',
          startedAt: now.subtract(const Duration(hours: 1)),
          outcome: ActivationOutcome.aborted,
          pointsAwarded: 0,
          source: ActivationSource.fab,
        ),
      ];
      expect(pointsInLast24Hours(events, now: now), 10);
    });
  });

  group('maybeGrantBonusUnlock', () {
    test('grants when inactive and threshold met', () {
      final now = DateTime(2026, 8, 6, 12);
      final settings = AppSettings(bonusUnlockThreshold: 150);
      final exp = maybeGrantBonusUnlock(
        settings: settings,
        pointsLast24h: 150,
        now: now,
      );
      expect(exp, now.add(const Duration(hours: 24)));
    });

    test('does not grant when already active', () {
      final now = DateTime(2026, 8, 6, 12);
      final settings = AppSettings(
        bonusUnlockThreshold: 100,
        bonusUnlockExpiresAt: now.add(const Duration(hours: 5)),
      );
      expect(
        maybeGrantBonusUnlock(
          settings: settings,
          pointsLast24h: 500,
          now: now,
        ),
        isNull,
      );
    });

    test('does not grant below threshold', () {
      final settings = AppSettings(bonusUnlockThreshold: 150);
      expect(
        maybeGrantBonusUnlock(
          settings: settings,
          pointsLast24h: 149,
        ),
        isNull,
      );
    });
  });

  group('selection filter', () {
    test('excludes bonus when locked', () {
      final pool = [
        CompetingResponse(id: 'a', phrase: 'base', enabled: true),
        CompetingResponse(
          id: 'b',
          phrase: 'bonus',
          enabled: true,
          requiresBonusUnlock: true,
        ),
      ];
      final pick = pickWeightedResponse(pool, includeBonusUnlock: false)!;
      expect(pick.id, 'a');
    });

    test('includes bonus when unlocked', () {
      final pool = [
        CompetingResponse(
          id: 'b',
          phrase: 'bonus',
          enabled: true,
          requiresBonusUnlock: true,
          weight: 100,
        ),
      ];
      final pick = pickWeightedResponse(pool, includeBonusUnlock: true)!;
      expect(pick.id, 'b');
    });
  });

  test('bonus seed size and flags', () {
    final bonus = bonusCompetingResponses();
    expect(bonus.length, inInclusiveRange(8, 15));
    expect(bonus.every((r) => r.requiresBonusUnlock), isTrue);
    expect(
      bonus.map((r) => r.category).toSet(),
      containsAll(['Mindfulness', 'Creative', 'Writing', 'Values']),
    );
  });

  test('full default library includes base and bonus', () {
    final all = defaultCompetingResponses();
    final bonus = all.where((r) => r.requiresBonusUnlock).length;
    final base = all.where((r) => !r.requiresBonusUnlock).length;
    expect(base, 100);
    expect(bonus, inInclusiveRange(8, 15));
    expect(currentResponseLibraryVersion, greaterThanOrEqualTo(3));
  });
}
