import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/seed.dart';
import 'package:rip_cord/domain/free_period.dart';

void main() {
  test('built-in library is ~100 base plus bonus prompts', () {
    final lib = defaultCompetingResponses();
    final base = lib.where((r) => !r.requiresBonusUnlock).toList();
    final bonus = lib.where((r) => r.requiresBonusUnlock).toList();
    expect(base.length, greaterThanOrEqualTo(90));
    expect(base.length, lessThanOrEqualTo(100));
    expect(bonus.length, inInclusiveRange(8, 15));
    expect(currentResponseLibraryVersion, greaterThanOrEqualTo(3));

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
    // Force exclude — should never return first.id when others exist
    for (var i = 0; i < 20; i++) {
      final next = pickWeightedResponse(lib, excludeId: first.id)!;
      expect(next.id, isNot(first.id));
    }
  });

  test('categories cover expected groups', () {
    final cats =
        defaultCompetingResponses().map((r) => r.category).toSet();
    expect(cats, containsAll(['Breathing', 'Grounding', 'Movement', 'Reframe', 'Action']));
  });
}
