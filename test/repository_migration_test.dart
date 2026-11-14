import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/app_repository.dart';
import 'package:rip_cord/data/bonus_seed.dart';
import 'package:rip_cord/domain/models.dart';
import 'package:rip_cord/domain/urge_drill.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v3 settings and edited library migrate without dropping user text', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings_v1': jsonEncode({
        'currentPoints': 80,
        'currentStreak': 4,
        'bestStreak': 6,
        'basePoints': 10,
        'responseLibraryVersion': 3,
        'variableRatioEnabled': true,
        'variableRatioChance': 0.2,
        'variableRatioBonus': 15,
        'bonusUnlockThreshold': 150,
        'bonusUnlockExpiresAt': 'not-a-date',
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final dir = await Directory.systemTemp.createTemp('ripcord_mig');
    final edited = CompetingResponse(
      id: 'seed_bonus_body_scan',
      phrase: 'Edited body scan',
      actionPrompt: 'My own scan',
      category: 'Mindfulness',
      enabled: false,
      sortOrder: 5,
    );
    final custom = CompetingResponse(
      id: 'custom-1',
      phrase: 'My own line',
      category: 'Custom',
      sortOrder: 1,
    );
    File('${dir.path}/competing_responses.json').writeAsStringSync(
      jsonEncode([
        edited.toJson()..['requiresBonusUnlock'] = true,
        custom.toJson(),
      ]),
    );

    final repo = AppRepository(prefs: prefs, documentsDirectory: dir);
    await repo.load();

    expect(repo.settings.currentPoints, 80);
    expect(repo.settings.currentStreak, 4);
    expect(repo.settings.responseLibraryVersion, 4);
    expect(repo.settings.handoffKind, HandoffKind.none);
    for (final key in legacyAppSettingsKeys) {
      expect(repo.settings.toJson().containsKey(key), isFalse);
    }

    final body = repo.responses.firstWhere((r) => r.id == edited.id);
    expect(body.phrase, 'Edited body scan');
    expect(body.actionPrompt, 'My own scan');
    expect(body.enabled, isFalse);
    expect(repo.responses.firstWhere((r) => r.id == custom.id).phrase, 'My own line');
    expect(
      repo.responses.map((r) => r.id),
      containsAll(bonusCompetingResponses().map((r) => r.id)),
    );

    final storedResponses = jsonDecode(
      File('${dir.path}/competing_responses.json').readAsStringSync(),
    ) as List;
    expect(
      storedResponses.any(
        (row) =>
            row is Map &&
            row['id'] == edited.id &&
            row['phrase'] == 'Edited body scan' &&
            row.containsKey('requiresBonusUnlock'),
      ),
      isFalse,
    );

    final beforePoints = repo.settings.currentPoints;
    final beforeStreak = repo.settings.currentStreak;
    final event = await repo.startDrill(
      source: ActivationSource.fab,
      urge: 'Scroll',
      action: drillActions.first,
    );
    await repo.completeDrill(eventId: event.id, durationSec: drillPracticeSeconds);
    expect(repo.settings.currentPoints, beforePoints);
    expect(repo.settings.currentStreak, beforeStreak);
    final logged = repo.events.firstWhere((e) => e.id == event.id);
    expect(logged.outcome, ActivationOutcome.completed);
    expect(logged.pointsAwarded, 0);
    expect(logged.bonusAwarded, 0);
    expect(logged.responsePhrase, contains('Scroll'));

    final started = await repo.startActivation(source: ActivationSource.fab);
    final rewarded = await repo.completeActivation(
      eventId: started.event.id,
      durationSec: 25,
    );
    expect(rewarded.pointsAwarded, 10);
    expect(repo.settings.currentPoints, beforePoints + 10);
    final after = repo.events.firstWhere((e) => e.id == started.event.id);
    expect(after.bonusAwarded, 0);
    expect(after.outcome, ActivationOutcome.completed);
    expect(
      repo.events.firstWhere((e) => e.id == event.id).pointsAwarded,
      0,
    );
  });
}
