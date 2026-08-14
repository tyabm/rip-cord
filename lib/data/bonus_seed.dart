import '../domain/models.dart';

/// Special categories unlocked for 24h after a high points-in-24h threshold.
/// IDs stable (`seed_bonus_*`). Aim: 15–30 second actions.
List<CompetingResponse> bonusCompetingResponses({int startSortOrder = 1000}) {
  final items = <({
    String id,
    String category,
    String phrase,
    String action,
  })>[
    // —— Mindfulness (3) ——
    (
      id: 'seed_bonus_body_scan',
      category: 'Mindfulness',
      phrase: 'Attention rests in the body, not the feed.',
      action:
          'Slow body scan: notice jaw, shoulders, and hands for about 20 seconds.',
    ),
    (
      id: 'seed_bonus_notice_breath',
      category: 'Mindfulness',
      phrase: 'Watch the breath; do not force it.',
      action: 'Notice natural breath for 5 cycles without changing it.',
    ),
    (
      id: 'seed_bonus_three_facts',
      category: 'Mindfulness',
      phrase: 'Facts over stories.',
      action:
          'Name 3 present-moment facts (not judgments), e.g. “chair under me.”',
    ),

    // —— Creative (3) ——
    (
      id: 'seed_bonus_silly_title',
      category: 'Creative',
      phrase: 'Play interrupts the urge loop.',
      action: 'Invent a silly 4-word title for this exact moment.',
    ),
    (
      id: 'seed_bonus_four_notes',
      category: 'Creative',
      phrase: 'Make something tiny and new.',
      action: 'Hum or whistle one made-up 4-note tune once through.',
    ),
    (
      id: 'seed_bonus_painter_line',
      category: 'Creative',
      phrase: 'See with fresh eyes.',
      action: 'Describe the room in one sentence as if briefing a painter.',
    ),

    // —— Writing (3) ——
    (
      id: 'seed_bonus_appreciative_sentence',
      category: 'Writing',
      phrase: 'Appreciation redirects attention.',
      action:
          'Write one appreciative sentence to someone (paper or unsent note).',
    ),
    (
      id: 'seed_bonus_best_self',
      category: 'Writing',
      phrase: 'Best self is a short instruction.',
      action:
          'One sentence: what would your best self do in the next hour?',
    ),
    (
      id: 'seed_bonus_three_word_diary',
      category: 'Writing',
      phrase: 'Three words can hold the moment.',
      action: 'Write a three-word diary line for “right now.”',
    ),

    // —— Values (3) ——
    (
      id: 'seed_bonus_value_action',
      category: 'Values',
      phrase: 'Values turn into motion.',
      action:
          'Name one core value; take one ~20s action aligned with it.',
    ),
    (
      id: 'seed_bonus_appreciative_note',
      category: 'Values',
      phrase: 'Connection over consumption.',
      action:
          'Draft a short appreciative note (mental or paper) for family or a friend.',
    ),
    (
      id: 'seed_bonus_kindness_step',
      category: 'Values',
      phrase: 'Kindness is a competing response.',
      action:
          'Name one small kindness for today and the first 15-second step.',
    ),
  ];

  return [
    for (var i = 0; i < items.length; i++)
      CompetingResponse(
        id: items[i].id,
        phrase: items[i].phrase,
        actionPrompt: items[i].action,
        category: items[i].category,
        enabled: true,
        sortOrder: startSortOrder + i,
        weight: 1,
        requiresBonusUnlock: true,
      ),
  ];
}
