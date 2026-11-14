import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/urge_drill.dart';

void main() {
  test('practice timer stays under a minute', () {
    expect(drillPracticeSeconds, inInclusiveRange(1, 59));
  });

  test('actions are a short fixed list with unique ids', () {
    expect(drillActions.length, inInclusiveRange(4, 8));
    expect(drillActions.map((a) => a.id).toSet(), hasLength(drillActions.length));
    expect(urgeNameChips, isNotEmpty);
    for (final action in drillActions) {
      expect(action.label.trim(), isNotEmpty);
      expect(action.instruction.trim(), isNotEmpty);
    }
  });

  test('log phrase records the urge and the action', () {
    expect(
      drillLogPhrase('  Scroll ', 'Squeeze fists'),
      'Drill · Scroll — Squeeze fists',
    );
  });
}
