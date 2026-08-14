import 'models.dart';

/// One timed segment of a guided breath cycle.
class BreathPhase {
  const BreathPhase({
    required this.label,
    required this.durationSec,
    required this.startScale,
    required this.endScale,
  });

  final String label;
  final int durationSec;
  /// 0–1 relative fill of the outer “full breath” circle.
  final double startScale;
  final double endScale;

  bool get isHold =>
      (endScale - startScale).abs() < 0.001 && label.toLowerCase().contains('hold');
}

/// Multi-phase pattern for the expanding/shrinking breath orb.
class BreathPattern {
  const BreathPattern({
    required this.id,
    required this.phases,
    this.displayName = 'Breathing',
  });

  final String id;
  final String displayName;
  final List<BreathPhase> phases;

  int get cycleSeconds =>
      phases.fold<int>(0, (sum, p) => sum + p.durationSec);

  /// Scale (0–1) at [t] seconds into the repeating cycle.
  double scaleAt(double tSec) {
    if (phases.isEmpty || cycleSeconds <= 0) return 0.5;
    var t = tSec % cycleSeconds;
    for (final p in phases) {
      if (t < p.durationSec) {
        final u = p.durationSec == 0 ? 1.0 : (t / p.durationSec);
        // Ease in-out for inhale/exhale.
        final eased = u * u * (3 - 2 * u);
        return p.startScale + (p.endScale - p.startScale) * eased;
      }
      t -= p.durationSec;
    }
    return phases.last.endScale;
  }

  /// Active phase label at [t] seconds into the cycle.
  String labelAt(double tSec) {
    if (phases.isEmpty || cycleSeconds <= 0) return '';
    var t = tSec % cycleSeconds;
    for (final p in phases) {
      if (t < p.durationSec) return p.label;
      t -= p.durationSec;
    }
    return phases.last.label;
  }

  /// Seconds remaining in the current phase.
  int phaseRemainingAt(double tSec) {
    if (phases.isEmpty || cycleSeconds <= 0) return 0;
    var t = tSec % cycleSeconds;
    for (final p in phases) {
      if (t < p.durationSec) {
        return (p.durationSec - t).ceil().clamp(1, p.durationSec);
      }
      t -= p.durationSec;
    }
    return 1;
  }
}

const double _min = 0.32;
const double _max = 0.92;

BreathPattern boxBreathing() => const BreathPattern(
      id: 'box',
      displayName: 'Box breathing',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 4, startScale: _min, endScale: _max),
        BreathPhase(label: 'Hold', durationSec: 4, startScale: _max, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 4, startScale: _max, endScale: _min),
        BreathPhase(label: 'Hold', durationSec: 4, startScale: _min, endScale: _min),
      ],
    );

BreathPattern pacedBreathing() => const BreathPattern(
      id: 'paced',
      displayName: 'Paced breathing',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 4, startScale: _min, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 6, startScale: _max, endScale: _min),
      ],
    );

BreathPattern physiologicalSigh() => const BreathPattern(
      id: 'sigh',
      displayName: 'Physiological sigh',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 1, startScale: _min, endScale: 0.65),
        BreathPhase(label: 'Inhale', durationSec: 1, startScale: 0.65, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 5, startScale: _max, endScale: _min),
      ],
    );

BreathPattern coherentBreathing() => const BreathPattern(
      id: 'coherent',
      displayName: 'Even breath',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 5, startScale: _min, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 5, startScale: _max, endScale: _min),
      ],
    );

BreathPattern fourSevenEight() => const BreathPattern(
      id: '478',
      displayName: '4-7-8',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 4, startScale: _min, endScale: _max),
        BreathPhase(label: 'Hold', durationSec: 7, startScale: _max, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 8, startScale: _max, endScale: _min),
      ],
    );

BreathPattern longerExhale() => const BreathPattern(
      id: 'exhale_long',
      displayName: 'Long exhale',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 3, startScale: _min, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 6, startScale: _max, endScale: _min),
      ],
    );

BreathPattern gentleDefault() => const BreathPattern(
      id: 'gentle',
      displayName: 'Gentle breath',
      phases: [
        BreathPhase(label: 'Inhale', durationSec: 4, startScale: _min, endScale: _max),
        BreathPhase(label: 'Hold', durationSec: 2, startScale: _max, endScale: _max),
        BreathPhase(label: 'Exhale', durationSec: 4, startScale: _max, endScale: _min),
      ],
    );

/// Resolve a pattern from a competing response (Breathing category preferred).
BreathPattern? breathPatternFor(CompetingResponse response) {
  final isBreathing = response.category == 'Breathing' ||
      _looksLikeBreathing(response.phrase) ||
      _looksLikeBreathing(response.actionPrompt ?? '');
  if (!isBreathing) return null;

  final id = response.id.toLowerCase();
  final text =
      '${response.phrase} ${response.actionPrompt ?? ''}'.toLowerCase();

  if (id.contains('box') || text.contains('box breathing')) {
    return boxBreathing();
  }
  if (id.contains('physiological') || text.contains('physiological sigh')) {
    return physiologicalSigh();
  }
  if (id.contains('478') || text.contains('4-7-8') || text.contains('4–7–8')) {
    return fourSevenEight();
  }
  if (id.contains('coherent') ||
      (text.contains('inhale 5') && text.contains('out 5'))) {
    return coherentBreathing();
  }
  if (id.contains('paced') ||
      (text.contains('inhale 4') && text.contains('exhale 6'))) {
    return pacedBreathing();
  }
  if (id.contains('exhale_longer') ||
      text.contains('exhale 6') ||
      text.contains('longer exhale')) {
    return longerExhale();
  }
  // PMR / other breathing-category: gentle guide still helps pacing.
  return gentleDefault();
}

bool _looksLikeBreathing(String s) {
  final t = s.toLowerCase();
  return t.contains('breath') ||
      t.contains('inhale') ||
      t.contains('exhale') ||
      t.contains('sigh');
}
