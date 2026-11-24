import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/expectation.dart';

void main() {
  test('mirror stays hidden until three ratings for that expectation', () {
    final checks = [
      _rated(ExpectationKind.relief, 2, DateTime.utc(2026, 1, 1)),
      _rated(ExpectationKind.relief, 4, DateTime.utc(2026, 1, 2)),
      _rated(ExpectationKind.escapeBoredom, 1, DateTime.utc(2026, 1, 3)),
      _rated(ExpectationKind.escapeBoredom, 1, DateTime.utc(2026, 1, 4)),
      _rated(ExpectationKind.escapeBoredom, 1, DateTime.utc(2026, 1, 5)),
    ];

    expect(expectationMirrorLine(ExpectationKind.relief, checks), isNull);
    expect(
      expectationMirrorLine(ExpectationKind.escapeBoredom, checks),
      'The last 3 times you expected to escape boredom, '
      'you rated it 1.0 out of 5.',
    );
  });

  test('mirror uses the last six ratings and one decimal', () {
    final checks = [
      for (var day = 1; day <= 7; day++)
        _rated(
          ExpectationKind.relief,
          day == 1 ? 5 : 2,
          DateTime.utc(2026, 2, day),
        ),
      _rated(ExpectationKind.checking, 5, DateTime.utc(2026, 3, 1)),
    ];

    expect(
      expectationMirrorLine(ExpectationKind.relief, checks),
      'The last 6 times you expected relief, you rated it 2.0 out of 5.',
    );
  });

  test('mirror averages a short run without rounding away the tenth', () {
    final checks = [
      _rated(ExpectationKind.habit, 2, DateTime.utc(2026, 4, 1)),
      _rated(ExpectationKind.habit, 2, DateTime.utc(2026, 4, 2)),
      _rated(ExpectationKind.habit, 3, DateTime.utc(2026, 4, 3)),
    ];

    expect(
      expectationMirrorLine(ExpectationKind.habit, checks),
      'The last 3 times you expected a habit, no reason, '
      'you rated it 2.3 out of 5.',
    );
  });

  test('outcome question names the recorded expectation', () {
    expect(
      outcomeRatingQuestion(ExpectationKind.relief),
      'Last time you expected relief. '
      'When you\'ve given in to that before, did it deliver?',
    );
    expect(
      outcomeRatingQuestion(ExpectationKind.checking),
      contains('to check something'),
    );
    expect(
      expectationNudgeBody(ExpectationKind.other),
      contains('something else'),
    );
    expect(expectationNudgeDelay, const Duration(hours: 2));
    expect(expectationNudgeTitle, 'See if it was worth it');
    expect(expectationOptions.map((option) => option.label), [
      'Relief',
      'Escape boredom',
      'Checking something',
      'Habit, no reason',
      'Other',
    ]);
  });

  test('pending ask is the newest unrated hope, and a rating closes it', () {
    final older = ExpectationCheck(
      id: 'older',
      recordedAt: DateTime.utc(2026, 5, 1),
      expectation: ExpectationKind.relief,
    );
    final newer = ExpectationCheck(
      id: 'newer',
      recordedAt: DateTime.utc(2026, 5, 2),
      expectation: ExpectationKind.other,
    );
    final asked = newer.copyWith(ratingAsked: true);
    final rated = newer.copyWith(rating: 4, ratedAt: DateTime.utc(2026, 5, 3));

    expect(pendingRatingAsk([older, newer])?.id, 'newer');
    expect(pendingRatingAsk([older, asked])?.id, 'older');
    expect(pendingRatingAsk([rated]), isNull);
    expect(rated.needsRatingAsk, isFalse);
  });

  test('closing screen only offers a recent unasked hope', () {
    final now = DateTime.utc(2026, 6, 1, 12);
    final recent = ExpectationCheck(
      id: 'recent',
      recordedAt: now.subtract(const Duration(minutes: 5)),
      expectation: ExpectationKind.relief,
    );
    final stale = ExpectationCheck(
      id: 'stale',
      recordedAt: now.subtract(const Duration(minutes: 20)),
      expectation: ExpectationKind.relief,
    );
    final asked = recent.copyWith(ratingAsked: true);

    expect(closingScreenCheck([stale], now: now), isNull);
    expect(closingScreenCheck([recent, stale], now: now)?.id, 'recent');
    expect(closingScreenCheck([asked], now: now), isNull);
    expect(
      closingScreenCheck([
        ExpectationCheck(
          id: 'future',
          recordedAt: now.add(const Duration(minutes: 1)),
          expectation: ExpectationKind.relief,
        ),
      ], now: now),
      isNull,
    );
  });

  test('stored checks ignore unknown kinds and out-of-range ratings', () {
    final good = ExpectationCheck(
      id: 'ok',
      recordedAt: DateTime.utc(2026, 7, 1),
      expectation: ExpectationKind.checking,
      rating: 4,
      ratedAt: DateTime.utc(2026, 7, 2),
      nudgeScheduled: true,
      activationEventId: 'event-1',
    );
    final restored = ExpectationCheck.tryFromJson(good.toJson());
    expect(restored?.id, 'ok');
    expect(restored?.rating, 4);
    expect(restored?.ratingAsked, isTrue);
    expect(restored?.nudgeScheduled, isTrue);
    expect(restored?.activationEventId, 'event-1');

    expect(
      ExpectationCheck.tryFromJson({
        'id': 'bad-kind',
        'recordedAt': '2026-07-01T00:00:00.000Z',
        'expectation': 'reward',
      }),
      isNull,
    );
    final unrated = ExpectationCheck.tryFromJson({
      'id': 'range',
      'recordedAt': '2026-07-01T00:00:00.000Z',
      'expectation': 'relief',
      'rating': 9,
    });
    expect(unrated?.rating, isNull);
    expect(unrated?.needsRatingAsk, isTrue);

    final implied = ExpectationCheck.tryFromJson({
      'id': 'implied',
      'recordedAt': '2026-07-01T00:00:00.000Z',
      'expectation': 'relief',
      'rating': 2.2,
    });
    expect(implied?.rating, 2);
    expect(implied?.ratingAsked, isTrue);
  });
}

ExpectationCheck _rated(ExpectationKind kind, int rating, DateTime when) {
  return ExpectationCheck(
    id: '${kind.name}-${when.millisecondsSinceEpoch}',
    recordedAt: when,
    expectation: kind,
    rating: rating,
    ratedAt: when,
    ratingAsked: true,
  );
}
