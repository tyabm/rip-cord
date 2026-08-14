import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/free_period.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  group('longestFreePeriod', () {
    test('returns null with no completed events', () {
      expect(longestFreePeriod([]), isNull);
    });

    test('includes open interval from last completion', () {
      final now = DateTime(2026, 8, 5, 12);
      final events = [
        ActivationEvent(
          id: '1',
          startedAt: now.subtract(const Duration(hours: 5)),
          completedAt: now.subtract(const Duration(hours: 5)),
          outcome: ActivationOutcome.completed,
          source: ActivationSource.fab,
        ),
      ];
      final d = longestFreePeriod(events, now: now)!;
      expect(d.inHours, 5);
    });

    test('finds longest gap between completions', () {
      final t0 = DateTime(2026, 8, 1);
      final events = [
        ActivationEvent(
          id: 'a',
          startedAt: t0,
          completedAt: t0,
          outcome: ActivationOutcome.completed,
          source: ActivationSource.fab,
        ),
        ActivationEvent(
          id: 'b',
          startedAt: t0.add(const Duration(hours: 2)),
          completedAt: t0.add(const Duration(hours: 2)),
          outcome: ActivationOutcome.completed,
          source: ActivationSource.tile,
        ),
        ActivationEvent(
          id: 'c',
          startedAt: t0.add(const Duration(hours: 12)),
          completedAt: t0.add(const Duration(hours: 12)),
          outcome: ActivationOutcome.completed,
          source: ActivationSource.widget,
        ),
      ];
      final now = t0.add(const Duration(hours: 13));
      final d = longestFreePeriod(events, now: now)!;
      expect(d.inHours, 10);
    });
  });

  group('pickWeightedResponse', () {
    test('returns null when none enabled', () {
      final list = [
        CompetingResponse(id: '1', phrase: 'a', enabled: false),
      ];
      expect(pickWeightedResponse(list), isNull);
    });

    test('respects weights', () {
      final list = [
        CompetingResponse(id: 'light', phrase: 'a', weight: 1),
        CompetingResponse(id: 'heavy', phrase: 'b', weight: 99),
      ];
      // roll 0 always picks first weight bucket that absorbs it → heavy after light's 1
      final fixed = _SeqRandom([0]); // picks first item (weight 1 absorbs 0)
      expect(pickWeightedResponse(list, random: fixed)?.id, 'light');

      final fixed2 = _SeqRandom([1]);
      expect(pickWeightedResponse(list, random: fixed2)?.id, 'heavy');
    });
  });
}

class _SeqRandom implements Random {
  _SeqRandom(this.values);
  final List<int> values;
  int i = 0;

  @override
  int nextInt(int max) => values[i++ % values.length] % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
