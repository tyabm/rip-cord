/// Timed portion of the urge drill. Naming the urge is untimed and quick;
/// the physical action itself stays under a minute.
const int drillPracticeSeconds = 30;

const List<String> urgeNameChips = [
  'Scroll',
  'Check',
  'Snack',
  'Worry',
  'Buy',
  'Numb out',
];

class DrillAction {
  const DrillAction({
    required this.id,
    required this.label,
    required this.instruction,
  });

  final String id;
  final String label;
  final String instruction;
}

const List<DrillAction> drillActions = [
  DrillAction(
    id: 'fists',
    label: 'Squeeze fists',
    instruction:
        'Squeeze both fists hard for a few seconds, then open and shake them out.',
  ),
  DrillAction(
    id: 'feet',
    label: 'Press feet',
    instruction: 'Press both feet into the floor, hold, then let them go heavy.',
  ),
  DrillAction(
    id: 'shoulders',
    label: 'Drop shoulders',
    instruction: 'Lift your shoulders toward your ears, then drop and unclench them.',
  ),
  DrillAction(
    id: 'jaw',
    label: 'Unclench jaw',
    instruction: 'Let your jaw hang loose and breathe out slowly three times.',
  ),
  DrillAction(
    id: 'reach',
    label: 'Stand and reach',
    instruction: 'Stand up, reach both arms overhead, then lower them.',
  ),
  DrillAction(
    id: 'chest',
    label: 'Hand on chest',
    instruction: 'Put a hand on your chest and feel three slow breaths.',
  ),
];

String drillLogPhrase(String urge, String actionLabel) {
  return 'Drill · ${urge.trim()} — $actionLabel';
}
