import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../../core/theme/app_theme.dart';

/// Editorial wind vane hero — painted entirely via CustomPainter.
/// Matches the (Not Boring) Weather "Air" anemometer aesthetic:
///   • vertical pole + crossbar (inkBlack)
///   • bold filled arrow head pointing INTO wind travel direction (windBlue)
///   • trapezoid fin on opposite side (windBlue)
///   • anemometer cups (2 circles, purple-grey)
///   • perspective orbit ellipse ring (windBlue stroke)
///   • soft ground shadow ellipse
///   • spring-animated direction rotation
class WindVaneHero extends StatefulWidget {
  /// Meteorological "from" direction in degrees (0=N, 90=E, 180=S, 270=W).
  final double windDirectionDegrees;

  const WindVaneHero({super.key, required this.windDirectionDegrees});

  @override
  State<WindVaneHero> createState() => _WindVaneHeroState();
}

class _WindVaneHeroState extends State<WindVaneHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SpringSimulation _spring;

  double _currentAngle = 0;
  double _currentVelocity = 0;
  double _targetAngle = 0;

  @override
  void initState() {
    super.initState();
    _targetAngle = _toRad(widget.windDirectionDegrees);
    _currentAngle = _targetAngle;
    _controller = AnimationController.unbounded(vsync: this)
      ..value = _currentAngle;
    _controller.addListener(() {
      setState(() => _currentAngle = _controller.value);
    });
  }

  @override
  void didUpdateWidget(WindVaneHero old) {
    super.didUpdateWidget(old);
    if (old.windDirectionDegrees != widget.windDirectionDegrees) {
      _targetAngle = _toRad(widget.windDirectionDegrees);
      _animateToTarget();
    }
  }

  void _animateToTarget() {
    _controller.stop();
    _currentVelocity = _controller.velocity;
    _spring = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 120, damping: 20),
      _controller.value,
      _targetAngle,
      _currentVelocity,
    );
    _controller.animateWith(_spring);
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WindVanePainter(
        angle: _currentAngle,
        context: context,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WindVanePainter extends CustomPainter {
  final double angle; // radians — wind travel direction
  final BuildContext context;

  _WindVanePainter({required this.angle, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.46; // slightly above centre

    final Color blue    = AppColors.windBlue;
    const Color cups    = Color(0xFF9B8FB5); // muted purple-grey
    final Color ink     = Theme.of(context).colorScheme.onSurface;

    // ── SHADOW ELLIPSE (ground) ──────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 90), width: 80, height: 14),
      Paint()
        ..color = Colors.black.withAlpha(26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── ORBIT ELLIPSE (perspective ring) ─────────────────────────────────────
    final orbitPaint = Paint()
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
    final polePaint = Paint()
      ..color = ink.withAlpha(217)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 100), Offset(cx, cy + 90), polePaint);

    // ── CROSSBAR ─────────────────────────────────────────────────────────────
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), polePaint);

    // ── ANEMOMETER CUPS (2 circles, top) ────────────────────────────────────
    final cupPaint = Paint()..color = cups;
    canvas.drawCircle(Offset(cx - 28, cy - 60), 12, cupPaint);
    canvas.drawCircle(Offset(cx + 28, cy - 60), 12, cupPaint);

    // ── ARROW + FIN (rotates to wind travel direction) ───────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Arrow head — bold filled triangle pointing in wind travel direction
    final arrowHead = Path()
      ..moveTo(0, -80)           // tip
      ..lineTo(-18, -38)         // left base
      ..lineTo(18, -38)          // right base
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = blue);

    // Trapezoid fin on opposite side
    final fin = Path()
      ..moveTo(-12, 28)
      ..lineTo(12, 28)
      ..lineTo(18, 62)
      ..lineTo(-18, 62)
      ..close();
    canvas.drawPath(fin, Paint()..color = blue.withAlpha(179));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WindVanePainter old) => old.angle != angle;
}
