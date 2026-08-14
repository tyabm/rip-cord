import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Compact HSV hue wheel + brightness slider for theme seed picking.
class BasicColorWheel extends StatefulWidget {
  const BasicColorWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.size = 200,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final double size;

  @override
  State<BasicColorWheel> createState() => _BasicColorWheelState();
}

class _BasicColorWheelState extends State<BasicColorWheel> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant BasicColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _emit(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onChanged(hsv.toColor());
  }

  void _onPan(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final outer = size.width / 2;
    final inner = outer * 0.55;
    if (dist < inner * 0.85 || dist > outer) return;

    var angle = math.atan2(dy, dx);
    // 0 at top going clockwise-ish for hue
    var hue = (angle * 180 / math.pi + 90) % 360;
    if (hue < 0) hue += 360;
    final sat = ((dist - inner) / (outer - inner)).clamp(0.35, 1.0);
    _emit(_hsv.withHue(hue).withSaturation(sat));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onPanDown: (d) => _onPan(d.localPosition, Size(size, size)),
              onPanUpdate: (d) => _onPan(d.localPosition, Size(size, size)),
              child: CustomPaint(
                size: Size(size, size),
                painter: _HueWheelPainter(
                  hue: _hsv.hue,
                  saturation: _hsv.saturation,
                  value: _hsv.value,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hsv.toColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${_hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjusted for light/dark so buttons stay readable.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Brightness', style: theme.textTheme.labelMedium),
            Expanded(
              child: Slider(
                value: _hsv.value.clamp(0.2, 1.0),
                min: 0.2,
                max: 1.0,
                onChanged: (v) => _emit(_hsv.withValue(v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HueWheelPainter extends CustomPainter {
  _HueWheelPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * 0.55;
    const steps = 180;

    for (var i = 0; i < steps; i++) {
      final h0 = i / steps * 360;
      final h1 = (i + 1) / steps * 360;
      final a0 = (h0 - 90) * math.pi / 180;
      final a1 = (h1 - 90) * math.pi / 180;
      final path = Path()
        ..moveTo(
          center.dx + math.cos(a0) * inner,
          center.dy + math.sin(a0) * inner,
        )
        ..lineTo(
          center.dx + math.cos(a0) * outer,
          center.dy + math.sin(a0) * outer,
        )
        ..lineTo(
          center.dx + math.cos(a1) * outer,
          center.dy + math.sin(a1) * outer,
        )
        ..lineTo(
          center.dx + math.cos(a1) * inner,
          center.dy + math.sin(a1) * inner,
        )
        ..close();
      final paint = Paint()
        ..color = HSVColor.fromAHSV(1, h0, 1, value.clamp(0.3, 1)).toColor()
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    // Inner disc
    canvas.drawCircle(
      center,
      inner - 2,
      Paint()..color = HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
    );
    canvas.drawCircle(
      center,
      inner - 2,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Selection marker on ring
    final angle = (hue - 90) * math.pi / 180;
    final r = inner + (outer - inner) * saturation.clamp(0.35, 1.0);
    final marker = Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
    canvas.drawCircle(marker, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      marker,
      6,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, value).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HueWheelPainter oldDelegate) =>
      oldDelegate.hue != hue ||
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value;
}
