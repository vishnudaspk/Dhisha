import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Editorial wind vane hero — painted entirely via CustomPainter.
/// Upgraded to dynamically follow device heading and physical wind physics.
class WindVaneHero extends StatefulWidget {
  /// Meteorological "from" direction in degrees (0=N, 90=E, 180=S, 270=W).
  final double windDirectionDegrees;
  final double windSpeedMps;
  final double heading;

  const WindVaneHero({
    super.key,
    required this.windDirectionDegrees,
    required this.windSpeedMps,
    required this.heading,
  });

  @override
  State<WindVaneHero> createState() => _WindVaneHeroState();
}

class _WindVaneHeroState extends State<WindVaneHero>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0;

  double _currentAngle = 0;
  double _velocity = 0;
  double _cupAngle = 0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _toRad(widget.windDirectionDegrees - widget.heading);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    double t = elapsed.inMicroseconds / 1000000.0;
    double dt = t - _lastTime;
    if (dt > 0.1) dt = 0.1;
    _lastTime = t;

    // 1. Spin the anemometer cups based on wind speed.
    // Calmed down so it doesn't look like Jupiter.
    final rotationSpeed = 0.15 + widget.windSpeedMps * 0.4;
    _cupAngle += rotationSpeed * dt;

    // 2. Physics for the vane direction
    // Point vane in the wind TRAVEL direction (180 opposite of source)
    double target = _toRad(
      widget.windDirectionDegrees + 180.0 - widget.heading,
    );

    // Ensure we take the shortest angular path
    while (target - _currentAngle > math.pi) target -= 2 * math.pi;
    while (target - _currentAngle < -math.pi) target += 2 * math.pi;

    // Less violent wobble
    double wobbleIntensity = (widget.windSpeedMps / 12.0).clamp(0.05, 0.4);
    double wobble =
        (math.sin(t * 1.8) * 0.1 + math.sin(t * 4.2) * 0.05) * wobbleIntensity;
    target += wobble;

    // Overdamped spring parameters for a heavy, physical feel.
    const double k = 80.0; // Spring stiffness
    const double c = 12.0; // Damping

    double force = k * (target - _currentAngle) - c * _velocity;

    _velocity += force * dt;
    _currentAngle += _velocity * dt;

    setState(() {}); // Repaint
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WindVanePainter(
        angle: _currentAngle,
        cupAngle: _cupAngle,
        context: context,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WindVanePainter extends CustomPainter {
  final double angle; // radians — wind travel direction
  final double cupAngle; // radians — for anemometer spinning
  final BuildContext context;

  _WindVanePainter({
    required this.angle,
    required this.cupAngle,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.46; // slightly above centre

    // Using brilliant whites for maximum contrast against the blue background
    final Color blue = Colors.white;
    final Color cups = Colors.white;
    final Color ink = Colors.white.withAlpha(200);

    // ── SHADOW ELLIPSE (ground) ──────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 90), width: 80, height: 14),
      Paint()
        ..color = Colors.black.withAlpha(26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── ORBIT ELLIPSE (perspective ring) ─────────────────────────────────────
    final orbitPaint =
        Paint()
          ..color = blue.withAlpha(191)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final orbitRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 120,
      height: 28,
    );
    canvas.drawOval(orbitRect, orbitPaint);

    // ── POLE ─────────────────────────────────────────────────────────────────
    final polePaint =
        Paint()
          ..color = Colors.white.withAlpha(160) // Soft white pole
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    // Lower the top of the pole, lift the bottom of the pole slightly
    canvas.drawLine(Offset(cx, cy - 80), Offset(cx, cy + 90), polePaint);

    // ── CROSSBAR ─────────────────────────────────────────────────────────────
    canvas.drawLine(Offset(cx - 15, cy), Offset(cx + 15, cy), polePaint);

    // ── ARROW + FIN (rotates to wind travel direction) ───────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Arrow head — bold filled triangle pointing in wind travel direction
    // A distinct energetic coral/orange makes the direction instantly readable against the blue
    final Color headColor = const Color(0xFFFF6B4A);
    final arrowHead =
        Path()
          ..moveTo(0, -80) // tip
          ..lineTo(-18, -38) // left base
          ..lineTo(18, -38) // right base
          ..close();
    canvas.drawPath(arrowHead, Paint()..color = headColor);

    // Trapezoid fin on opposite side (tail)
    final fin =
        Path()
          ..moveTo(-12, 28)
          ..lineTo(12, 28)
          ..lineTo(18, 62)
          ..lineTo(-18, 62)
          ..close();
    canvas.drawPath(fin, Paint()..color = blue.withAlpha(150));

    canvas.restore();

    // ── ANEMOMETER CUPS (3 spinning half-spheres) ───────────────────────────
    List<_Cup> cupList = [];
    for (int i = 0; i < 3; i++) {
      double phase = cupAngle + i * (2 * math.pi / 3);
      double x = cx + 32 * math.cos(phase);
      double y = cy - 65 + 8 * math.sin(phase);
      double depth = math.sin(phase);
      cupList.add(_Cup(x, y, depth));
    }

    // Sort cups by depth (sin wave) so the ones in back are drawn first
    cupList.sort((a, b) => a.depth.compareTo(b.depth));

    for (var c in cupList) {
      double r = 8 + c.depth * 2; // cups in front look larger
      final currentColor = c.depth < 0 ? cups.withAlpha(150) : cups;

      // Connecting rod
      canvas.drawLine(
        Offset(cx, cy - 65), // center of anemometer hub
        Offset(c.x, c.y),
        Paint()
          ..color = ink.withAlpha(120)
          ..strokeWidth = 1.5,
      );

      canvas.drawCircle(Offset(c.x, c.y), r, Paint()..color = currentColor);
    }
  }

  @override
  bool shouldRepaint(_WindVanePainter old) =>
      old.angle != angle || old.cupAngle != cupAngle;
}

class _Cup {
  final double x, y, depth;
  _Cup(this.x, this.y, this.depth);
}
