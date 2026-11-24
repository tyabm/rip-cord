import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/app_repository.dart';
import 'package:rip_cord/domain/expectation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'expectation history persists, asks once, and survives a bad file',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({
          'currentPoints': 40,
          'currentStreak': 2,
          'responseLibraryVersion': 4,
          'variableRatioEnabled': true,
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final dir = await Directory.systemTemp.createTemp('ripcord_expect');
      File('${dir.path}/activation_events.json').writeAsStringSync(
        jsonEncode([
          {
            'id': 'old-event',
            'startedAt': '2026-01-01T00:00:00.000Z',
            'outcome': 'completed',
            'pointsAwarded': 10,
            'bonusAwarded': 0,
            'source': 'fab',
          },
        ]),
      );

      final repo = AppRepository(prefs: prefs, documentsDirectory: dir);
      await repo.load();
      expect(repo.settings.currentPoints, 40);
      expect(repo.settings.expectationCheckEnabled, isTrue);
      expect(repo.settings.expectationNudgeEnabled, isFalse);
      expect(repo.events.single.id, 'old-event');
      expect(repo.expectationChecks, isEmpty);
      expect(pendingRatingAsk(repo.expectationChecks), isNull);

      final first = await repo.recordExpectation(ExpectationKind.relief);
      expect(first.expectation, ExpectationKind.relief);
      expect(pendingRatingAsk(repo.expectationChecks)?.id, first.id);

      final second = await repo.recordExpectation(ExpectationKind.checking);
      final storedFirst = repo.expectationChecks.firstWhere(
        (check) => check.id == first.id,
      );
      expect(storedFirst.ratingAsked, isTrue);
      expect(pendingRatingAsk(repo.expectationChecks)?.id, second.id);

      expect(await repo.rateExpectation(id: second.id, rating: 0), isFalse);
      expect(await repo.rateExpectation(id: second.id, rating: 4), isTrue);
      expect(pendingRatingAsk(repo.expectationChecks), isNull);
      expect(
        repo.expectationChecks
            .firstWhere((check) => check.id == second.id)
            .rating,
        4,
      );

      await repo.attachExpectationToEvent(
        checkId: second.id,
        eventId: 'old-event',
      );
      await repo.markNudgeScheduled(second.id);

      final again = AppRepository(prefs: prefs, documentsDirectory: dir);
      await again.load();
      final reloaded = again.expectationChecks.firstWhere(
        (check) => check.id == second.id,
      );
      expect(reloaded.rating, 4);
      expect(reloaded.activationEventId, 'old-event');
      expect(reloaded.nudgeScheduled, isTrue);
      expect(again.events.single.id, 'old-event');
      expect(again.settings.currentPoints, 40);

      await again.clearExpectationHistory();
      expect(again.expectationChecks, isEmpty);
      expect(again.events, isNotEmpty);
      expect(again.settings.currentPoints, 40);

      final third = await again.recordExpectation(ExpectationKind.other);
      await again.clearAll();
      expect(again.expectationChecks, isEmpty);
      expect(again.events, isEmpty);
      expect(again.settings.currentPoints, 0);
      expect(again.settings.expectationCheckEnabled, isTrue);
      expect(again.settings.expectationNudgeEnabled, isFalse);
      expect(
        File('${dir.path}/expectation_checks.json').readAsStringSync(),
        '[]',
      );
      expect(third.id, isNotEmpty);
    },
  );

  test('a corrupt expectation file does not block an existing log', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final dir = await Directory.systemTemp.createTemp('ripcord_expect_bad');
    File('${dir.path}/expectation_checks.json').writeAsStringSync('{');
    File('${dir.path}/activation_events.json').writeAsStringSync(
      jsonEncode([
        {
          'id': 'kept',
          'startedAt': '2026-02-01T00:00:00.000Z',
          'outcome': 'aborted',
          'source': 'tile',
        },
      ]),
    );

    final repo = AppRepository(prefs: prefs, documentsDirectory: dir);
    await repo.load();
    expect(repo.events.single.id, 'kept');
    expect(repo.expectationChecks, isEmpty);
    expect(repo.settings.expectationCheckEnabled, isTrue);

    File('${dir.path}/expectation_checks.json').writeAsStringSync(
      jsonEncode([
        {
          'id': 'kept-check',
          'recordedAt': '2026-02-02T00:00:00.000Z',
          'expectation': 'relief',
        },
        {'id': 'drop-me', 'recordedAt': 'not-a-date', 'expectation': 'relief'},
        'nope',
      ]),
    );
    final reloaded = AppRepository(prefs: prefs, documentsDirectory: dir);
    await reloaded.load();
    expect(reloaded.expectationChecks.single.id, 'kept-check');
    expect(reloaded.events.single.id, 'kept');
  });
}
