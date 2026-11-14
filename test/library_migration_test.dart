import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/bonus_seed.dart';
import 'package:rip_cord/data/library_merge.dart';
import 'package:rip_cord/data/seed.dart';
import 'package:rip_cord/domain/free_period.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  test('merge keeps edits and adds missing former bonus prompts', () {
    final edited = CompetingResponse(
      id: 'seed_bonus_body_scan',
      phrase: 'Edited body scan',
      actionPrompt: 'My own scan',
      category: 'Mindfulness',
      enabled: false,
      sortOrder: 2,
    );
    final custom = CompetingResponse(
      id: 'custom-1',
      phrase: 'My own line',
      category: 'Custom',
      enabled: true,
      sortOrder: 1,
    );
    final regularEdit = CompetingResponse(
      id: 'seed_box_breathing',
      phrase: 'My box breath line',
      actionPrompt: 'One box, my way',
      category: 'Breathing',
      sortOrder: 0,
    );

    final merged = mergeMissingResponses(
      [regularEdit, custom, edited],
      defaultCompetingResponses(),
    );

    expect(merged.firstWhere((r) => r.id == edited.id).phrase, 'Edited body scan');
    expect(merged.firstWhere((r) => r.id == edited.id).enabled, isFalse);
    expect(merged.firstWhere((r) => r.id == custom.id).phrase, 'My own line');
    expect(
      merged.firstWhere((r) => r.id == regularEdit.id).phrase,
      'My box breath line',
    );

    final ids = merged.map((r) => r.id).toList();
    expect(ids.where((id) => id == edited.id).length, 1);
    expect(
      ids,
      containsAll(bonusCompetingResponses().map((r) => r.id)),
    );
  });

  test('former bonus prompts are ordinary enabled rotation members', () {
    final bonus = bonusCompetingResponses();
    expect(bonus, hasLength(12));
    expect(
      bonus.map((r) => r.category).toSet(),
      containsAll(['Mindfulness', 'Creative', 'Writing', 'Values']),
    );

    final lib = defaultCompetingResponses();
    expect(lib.map((r) => r.id), containsAll(bonus.map((r) => r.id)));
    final picked = pickWeightedResponse(
      bonus.map((r) => r.copyWith(enabled: true)).toList(),
    );
    expect(picked, isNotNull);
  });
}
