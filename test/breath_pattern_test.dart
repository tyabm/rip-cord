import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/breath_pattern.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  test('box breathing scales through phases', () {
    final p = boxBreathing();
    expect(p.cycleSeconds, 16);
    expect(p.labelAt(0), 'Inhale');
    expect(p.labelAt(4), 'Hold');
    expect(p.labelAt(8), 'Exhale');
    expect(p.labelAt(12), 'Hold');
    expect(p.scaleAt(0), lessThan(0.4));
    expect(p.scaleAt(3.9), greaterThan(0.8));
    expect(p.scaleAt(8), greaterThan(0.8));
    expect(p.scaleAt(11.9), lessThan(0.4));
  });

  test('breathPatternFor maps breathing responses', () {
    final box = CompetingResponse(
      id: 'seed_box_breathing',
      phrase: 'x',
      actionPrompt: 'Box breathing: inhale 4',
      category: 'Breathing',
    );
    expect(breathPatternFor(box)?.id, 'box');

    final move = CompetingResponse(
      id: 'seed_calf_raises',
      phrase: 'Move',
      actionPrompt: 'Do calf raises',
      category: 'Movement',
    );
    expect(breathPatternFor(move), isNull);
  });
}
