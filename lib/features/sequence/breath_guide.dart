import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/breath_pattern.dart';
import '../../services/chime_service.dart';

/// Expanding/shrinking breath orb inside a static full-breath ring,
/// with soft chimes on each phase change.
class BreathGuide extends StatefulWidget {
  const BreathGuide({
    super.key,
    required this.pattern,
    this.size = 200,
    this.chimesEnabled = true,
  });

  final BreathPattern pattern;
  final double size;
  final bool chimesEnabled;

  @override
  State<BreathGuide> createState() => _BreathGuideState();
}

class _BreathGuideState extends State<BreathGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final ChimeService _chime;
  final Stopwatch _watch = Stopwatch();
  String? _lastPhaseLabel;
  int _lastPhaseBucket = -1;

  @override
  void initState() {
    super.initState();
    _chime = ChimeService();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _watch.start();
    _ticker.repeat();
    // Opening chime + label
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cuePhase(force: true);
    });
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
    _cuePhase();
  }

  void _cuePhase({bool force = false}) {
    final t = _watch.elapsedMilliseconds / 1000.0;
    final label = widget.pattern.labelAt(t);
    // Bucket by cumulative phase index so repeated "Hold" still chimes.
    final bucket = _phaseBucketAt(t);
    if (!force && bucket == _lastPhaseBucket) return;
    _lastPhaseBucket = bucket;
    _lastPhaseLabel = label;

    if (widget.chimesEnabled) {
      unawaited(_chime.playBreathChime());
    }
    // Subtle haptic on phase change (not every frame).
    HapticFeedback.selectionClick();
  }

  int _phaseBucketAt(double tSec) {
    final cycle = widget.pattern.cycleSeconds;
    if (cycle <= 0) return 0;
    final t = tSec % cycle;
    var acc = 0.0;
    for (var i = 0; i < widget.pattern.phases.length; i++) {
      acc += widget.pattern.phases[i].durationSec;
      if (t < acc) {
        // Unique bucket per cycle + phase
        final cycles = tSec ~/ cycle;
        return cycles * 32 + i;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _ticker
      ..removeListener(_onTick)
      ..dispose();
    _watch.stop();
    unawaited(_chime.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = _watch.elapsedMilliseconds / 1000.0;
    final scale = widget.pattern.scaleAt(t);
    final label = widget.pattern.labelAt(t);
    final remaining = widget.pattern.phaseRemainingAt(t);
    _lastPhaseLabel ??= label;

    final outer = widget.size;
    final inner = outer * scale;

    return Semantics(
      liveRegion: true,
      label: '$label, $remaining seconds. ${widget.pattern.displayName}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: outer,
            height: outer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Static full-breath ring
                CustomPaint(
                  size: Size(outer, outer),
                  painter: _RingPainter(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 3,
                  ),
                ),
                // Soft outer wash
                Container(
                  width: outer * 0.96,
                  height: outer * 0.96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  ),
                ),
                // Expanding breath orb
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeInOut,
                  width: inner,
                  height: inner,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Phase label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black45),
                        ],
                      ),
                    ),
                    Text(
                      '$remaining',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black45),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.pattern.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - strokeWidth;
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
