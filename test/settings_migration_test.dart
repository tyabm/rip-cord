import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  test('old settings keys load and are not written back', () {
    final settings = AppSettings.fromJson({
      'sequenceDurationSec': 30,
      'basePoints': 12,
      'variableRatioEnabled': true,
      'variableRatioChance': 0.35,
      'variableRatioBonus': 40,
      'bonusUnlockThreshold': 200,
      'bonusUnlockExpiresAt': 'not-a-date',
      'currentPoints': 80,
      'currentStreak': 4,
      'bestStreak': 9,
      'responseLibraryVersion': 3,
      'themeMode': 'dark',
      'unknownFutureKey': {'nested': true},
    });

    expect(settings.sequenceDurationSec, 30);
    expect(settings.basePoints, 12);
    expect(settings.currentPoints, 80);
    expect(settings.currentStreak, 4);
    expect(settings.bestStreak, 9);
    expect(settings.responseLibraryVersion, 3);
    expect(settings.themeMode, AppThemeMode.dark);
    expect(settings.handoffKind, HandoffKind.none);
    expect(settings.drillIsDefaultPull, isFalse);
    expect(settings.walkTimerMinutes, 10);
    expect(settings.trustedPersonPhone, isNull);
    expect(settings.expectationCheckEnabled, isTrue);
    expect(settings.expectationNudgeEnabled, isFalse);

    final stored = settings.toJson();
    for (final key in legacyAppSettingsKeys) {
      expect(stored.containsKey(key), isFalse, reason: key);
    }
    expect(stored['expectationCheckEnabled'], isTrue);
    expect(stored['expectationNudgeEnabled'], isFalse);
  });

  test('unknown handoff and theme names fall back safely', () {
    final settings = AppSettings.fromJson({
      'handoffKind': 'tokenShop',
      'themeMode': 'neon',
      'drillIsDefaultPull': true,
      'walkTimerMinutes': 15,
      'trustedPersonName': '  Sam  ',
      'trustedPersonPhone': ' 555 ',
      'musicUri': ' https://example.com/pl ',
    });

    expect(settings.handoffKind, HandoffKind.none);
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.drillIsDefaultPull, isTrue);
    expect(settings.walkTimerMinutes, 15);
    expect(settings.trustedPersonName, 'Sam');
    expect(settings.trustedPersonPhone, '555');
    expect(settings.musicUri, 'https://example.com/pl');
    expect(settings.expectationCheckEnabled, isTrue);
    expect(settings.expectationNudgeEnabled, isFalse);
  });

  test('expectation toggles round-trip and stay distinct from legacy keys', () {
    final settings = AppSettings.fromJson({
      'expectationCheckEnabled': false,
      'expectationNudgeEnabled': true,
      'variableRatioEnabled': true,
    });

    expect(settings.expectationCheckEnabled, isFalse);
    expect(settings.expectationNudgeEnabled, isTrue);

    final stored = settings.toJson();
    expect(stored['expectationCheckEnabled'], isFalse);
    expect(stored['expectationNudgeEnabled'], isTrue);
    for (final key in legacyAppSettingsKeys) {
      expect(stored.containsKey(key), isFalse, reason: key);
    }
  });

  test('former bonus flag on a response is ignored', () {
    final response = CompetingResponse.fromJson({
      'id': 'seed_bonus_body_scan',
      'phrase': 'Edited body scan',
      'actionPrompt': 'My own scan',
      'category': 'Mindfulness',
      'enabled': false,
      'requiresBonusUnlock': true,
      'sortOrder': 5,
    });

    expect(response.phrase, 'Edited body scan');
    expect(response.actionPrompt, 'My own scan');
    expect(response.enabled, isFalse);
    expect(response.toJson().containsKey('requiresBonusUnlock'), isFalse);
  });
}
