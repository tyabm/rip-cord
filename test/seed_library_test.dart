import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/bonus_seed.dart';
import 'package:rip_cord/data/seed.dart';
import 'package:rip_cord/domain/free_period.dart';

void main() {
  test('built-in library keeps the base set and always-on former bonus prompts', () {
    final lib = defaultCompetingResponses();
    final bonusIds = bonusCompetingResponses().map((r) => r.id).toSet();
    final base = lib.where((r) => !bonusIds.contains(r.id)).toList();
    final bonus = lib.where((r) => bonusIds.contains(r.id)).toList();

    expect(base.length, greaterThanOrEqualTo(90));
    expect(base.length, lessThanOrEqualTo(100));
    expect(bonus.length, 12);
    expect(bonus.every((r) => r.enabled), isTrue);
    expect(currentResponseLibraryVersion, 4);

    final ids = lib.map((r) => r.id).toSet();
    expect(ids.length, lib.length, reason: 'seed IDs must be unique');
    expect(lib.every((r) => r.id.startsWith('seed_')), isTrue);
    expect(lib.every((r) => r.phrase.isNotEmpty), isTrue);
    expect(
      lib.every((r) => r.actionPrompt != null && r.actionPrompt!.isNotEmpty),
      isTrue,
    );
  });

  test('random pick avoids immediate repeat when possible', () {
    final lib = defaultCompetingResponses().take(5).toList();
    final first = pickWeightedResponse(lib)!;
    for (var i = 0; i < 20; i++) {
      final next = pickWeightedResponse(lib, excludeId: first.id)!;
      expect(next.id, isNot(first.id));
    }
  });

  test('categories cover expected groups', () {
    final cats = defaultCompetingResponses().map((r) => r.category).toSet();
    expect(
      cats,
      containsAll([
        'Breathing',
        'Grounding',
        'Movement',
        'Reframe',
        'Action',
        'Mindfulness',
        'Creative',
        'Writing',
        'Values',
      ]),
    );
  });
}
