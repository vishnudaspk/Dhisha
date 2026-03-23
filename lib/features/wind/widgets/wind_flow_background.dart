import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Dhisha — Aerodynamic Wind Tunnel Background
///
/// Design goals:
///  • Strict Dieter Rams minimalist aesthetic, matching a high-end physical instrument.
///  • No decorative particle blobs, no cartoon arrows.
///  • Uses physical aero-elastic fluid strings (tufts) suspended in an infinite tunnel.
///  • Strings stretch and whip dynamically based on mathematical wind speed turbulence.
///  • Transverse calibration struts provide a measurable sense of velocity.
class WindFlowBackground extends StatefulWidget {
  final double windDirectionDegrees;
  final double windSpeedMps;
  final double heading;

  const WindFlowBackground({
    super.key,
    required this.windDirectionDegrees,
    required this.windSpeedMps,
    required this.heading,
  });

  @override
  State<WindFlowBackground> createState() => _State();
}

class _State extends State<WindFlowBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0;
  double _elapsed = 0;

  final ValueNotifier<int> _tick = ValueNotifier(0);

  double _smoothHeading = 0;
  bool _headingInit = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _lastTime).clamp(0.0, 0.05);
    _lastTime = t;
    _elapsed = t;

    // Smooth heading via snappier spherical spring
    if (!_headingInit) {
      _smoothHeading = widget.heading;
      _headingInit = true;
    } else {
      double d = (widget.heading - _smoothHeading) % 360.0;
      if (d > 180) d -= 360;
      if (d < -180) d += 360;
      _smoothHeading = (_smoothHeading + d * dt * 8.0) % 360.0;
    }

    _tick.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final Color inkColor =
        isLight ? const Color(0xFF1A3A5C) : const Color(0xFF7AAEE8);

    return ValueListenableBuilder<int>(
      valueListenable: _tick,
      builder:
          (context, tick, child) => CustomPaint(
            size: Size.infinite,
            painter: _InstrumentPainter(
              windDir: widget.windDirectionDegrees,
              windSpeed: widget.windSpeedMps,
              headingRad: _smoothHeading * pi / 180.0,
              inkColor: inkColor,
              time: _elapsed,
            ),
          ),
    );
  }
}

class _InstrumentPainter extends CustomPainter {
  final double windDir;
  final double windSpeed;
  final double headingRad;
  final Color inkColor;
  final double time;

  _InstrumentPainter({
    required this.windDir,
    required this.windSpeed,
    required this.headingRad,
    required this.inkColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Expand the bounding box substantially so edges never pop onscreen during rotation
    final span = sqrt(w * w + h * h) * 1.3;

    canvas.save();
    canvas.translate(w / 2, h / 2);

    // Rotate so that the local +Y axis exactly matches the physical wind travel direction.
    // Mathematical rotation maps wind meteorological origin against the physical compass view.
    canvas.rotate((windDir - (headingRad * 180.0 / pi)) * pi / 180.0);

    final speedN = (windSpeed / 15.0).clamp(0.0, 1.0);

    // ── 1. Calibration Struts (Transverse panning grid) ───────────────────
    final strutPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..color = inkColor.withValues(alpha: 0.05)
          ..strokeWidth = 0.5;

    final travelVelocity = 18.0 + windSpeed * 8.0;
    const strutSpacing = 160.0;

    // Smoothly scroll the visual lattice across the screen based on time,
    // wrapping seamlessly to create an infinitely infinite plane.
    final scrollOffset = (time * travelVelocity) % strutSpacing;

    for (
      double y = -span / 2 - strutSpacing;
      y <= span / 2 + strutSpacing;
      y += strutSpacing
    ) {
      final drawY = y + scrollOffset;
      if (drawY > -span / 2 && drawY < span / 2) {
        canvas.drawLine(
          Offset(-span / 2, drawY),
          Offset(span / 2, drawY),
          strutPaint,
        );
      }
    }

    // ── 2. Aerodynamic fluid strings (Longitudinal waving lines) ──────────
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    const strings = 13; // Higher density for scientific instrument feel
    final gap = span / (strings - 1);

    // Physical wobble parameters
    // Calm wind = perfectly rigid piano wire.
    // Gale force = flailing whip lines.
    final turbulence = 2.0 + speedN * 55.0;
    final wavePropagationSpeed = 1.0 + windSpeed * 0.45;

    for (int i = 0; i < strings; i++) {
      final baseX = -span / 2 + i * gap;
      final path = Path();

      const step = 20.0;
      bool first = true;

      for (double y = -span / 2; y <= span / 2; y += step) {
        // Wave travels physically down the string (+Y direction) over time.
        // It creates a brilliant fluid illusion.
        final phase = y * 0.012 - time * wavePropagationSpeed;

        // Harmonic interference simulates complex fluid aerodynamic eddies
        final w1 = sin(phase + i * 1.34) * 0.45;
        final w2 = cos(phase * 1.62 - i * 0.83) * 0.35;
        final w3 = sin(phase * 0.38 + i * 2.11) * 0.15;
        final w4 =
            sin(phase * 2.8 + i * 3.7) *
            0.05; // high frequency flutter for extreme winds

        final wobble = (w1 + w2 + w3 + w4) * turbulence;
        final px = baseX + wobble;

        if (first) {
          path.moveTo(px, y);
          first = false;
        } else {
          path.lineTo(px, y);
        }
      }

      // Edge strings fade out elegantly out to frame the dial
      final edgeFade = sin((i / (strings - 1)) * pi);
      final opacity = (0.02 + edgeFade * 0.18).clamp(0.0, 1.0);

      linePaint.color = inkColor.withValues(alpha: opacity);
      linePaint.strokeWidth = 0.5 + edgeFade * 0.9;

      canvas.drawPath(path, linePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InstrumentPainter old) => true;
}
