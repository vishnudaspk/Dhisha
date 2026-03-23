import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated solar/lunar hero element.
///
/// • Daytime  → glowing warm sun disc with translucent halo rays
/// • Night    → proper crescent moon drawn by subtracting an offset circle
///              from the main lunar disc; a few soft star dots scatter the sky
///
/// The disc position shifts vertically based on [altitude] so it rises
/// and sets across the hero area.
class SunHeroCircle extends StatefulWidget {
  final double altitude; // –90 to +90 degrees

  const SunHeroCircle({super.key, required this.altitude});

  @override
  State<SunHeroCircle> createState() => _SunHeroCircleState();
}

class _SunHeroCircleState extends State<SunHeroCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _altAnim;
  double _prevAlt = 0;

  @override
  void initState() {
    super.initState();
    _prevAlt = widget.altitude;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _altAnim = AlwaysStoppedAnimation(_prevAlt);
  }

  @override
  void didUpdateWidget(SunHeroCircle old) {
    super.didUpdateWidget(old);
    if (old.altitude != widget.altitude) {
      _altAnim = Tween<double>(begin: _prevAlt, end: widget.altitude)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _prevAlt = widget.altitude;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _altAnim,
      builder: (_, __) => CustomPaint(
        painter: _SkyBodyPainter(altitude: _altAnim.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SkyBodyPainter extends CustomPainter {
  final double altitude;

  const _SkyBodyPainter({required this.altitude});

  bool get isNight => altitude <= 0;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Disc vertical position ─────────────────────────────────────────────
    // altitude 90° → disc centred at top 20%
    // altitude  0° → disc centred at 65% (rising/setting on horizon area)
    // altitude <0° → disc drifts slightly further down (moon below horizon)
    final diameter = size.width * 0.68;
    final radius   = diameter / 2;

    final topAnchor     = size.height * 0.06 + radius;
    final horizonAnchor = size.height * 0.60 + radius;
    final nightAnchor   = size.height * 0.20 + radius; // Rises into the sky

    final double cy;
    if (!isNight) {
      final frac = altitude.clamp(0.0, 90.0) / 90.0;
      cy = horizonAnchor + (topAnchor - horizonAnchor) * frac;
    } else {
      // Moon rises up as altitude decreases further below 0
      final frac = (altitude.clamp(-90.0, 0.0) / -90.0);
      cy = horizonAnchor - (horizonAnchor - nightAnchor) * frac;
    }

    final center = Offset(size.width / 2, cy);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (isNight) {
      _drawStars(canvas, size, center, radius);
      _drawMoon(canvas, center, radius);
    } else {
      _drawSun(canvas, center, radius, altitude);
    }

    canvas.restore();
  }

  // ── Night sky ──────────────────────────────────────────────────────────────

  void _drawStars(Canvas canvas, Size size, Offset moonCenter, double moonR) {
    final rng = math.Random(137);
    final starPaint = Paint()..color = Colors.white.withAlpha(180);
    // Scatter 60 tiny stars that avoid the moon disc
    int drawn = 0;
    while (drawn < 60) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.75;
      if ((Offset(x, y) - moonCenter).distance < moonR + 24) continue;
      final r = rng.nextDouble() * 0.9 + 0.3;
      canvas.drawCircle(Offset(x, y), r, starPaint);
      drawn++;
    }
  }

  void _drawMoon(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * math.pi / 180.0); // Tilt 45 degrees clockwise
    canvas.translate(-center.dx, -center.dy);

    // Crescent: lunar disc minus an offset circle (shadow planet)
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Shadow circle offset creates the crescent bite
    // Flipped on vertical axis (using - instead of + for dx)
    final biteCenter = Offset(center.dx - radius * 0.45, center.dy + radius * 0.20);
    final biteRadius = radius * 0.88;
    final bitePath = Path()
      ..addOval(Rect.fromCircle(center: biteCenter, radius: biteRadius));

    final crescent = Path.combine(PathOperation.difference, moonPath, bitePath);

    // Creamy textured gradient mimicking the actual moon
    final gradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.0,
      colors: [
        const Color(0xFFFFFEE0), // bright cream core
        const Color(0xFFFFE8A1), // warm yellow
        const Color(0xFFD4B15C), // shadowed crust
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawPath(
      crescent,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // Soft pearlescent glow (creamy hue)
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..color = const Color(0xFFFFE8A1).withAlpha(24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.fill,
    );

    // Fine grain texture on the moon for realism
    canvas.save();
    canvas.clipPath(crescent);
    final rng = math.Random(101);
    final grainPaint = Paint()..color = Colors.black.withAlpha(12);
    for (int i = 0; i < 800; i++) {
      final dx = center.dx + (rng.nextDouble() - 0.5) * radius * 2;
      final dy = center.dy + (rng.nextDouble() - 0.5) * radius * 2;
      if ((Offset(dx, dy) - center).distance <= radius) {
        canvas.drawCircle(Offset(dx, dy), 0.6, grainPaint);
      }
    }
    canvas.restore(); // restore clip

    canvas.restore(); // restore 45-degree rotation
  }

  // ── Daytime sun ────────────────────────────────────────────────────────────

  void _drawSun(Canvas canvas, Offset center, double radius, double altitude) {
    // Intensity ramps up with altitude: deep warm amber at horizon, bright white at zenith
    final t = (altitude / 90.0).clamp(0.0, 1.0);
    final innerColor = Color.lerp(const Color(0xFFFF8C42), const Color(0xFFFFF3B0), t)!;
    final outerColor = Color.lerp(const Color(0xFFFF5722), const Color(0xFFFFCC02), t)!;

    // Outer atmosphere glow (large, very soft)
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()
        ..color = outerColor.withAlpha(18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
        ..style = PaintingStyle.fill,
    );

    // Mid glow ring
    canvas.drawCircle(
      center,
      radius * 1.12,
      Paint()
        ..color = outerColor.withAlpha(28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.fill,
    );

    // Main solar disc with radial gradient
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [innerColor, outerColor],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(rect)..style = PaintingStyle.fill,
    );

    // Fine grain texture
    final rng = math.Random(42);
    final grainPaint = Paint()..color = Colors.black.withAlpha(8);
    for (int i = 0; i < 1800; i++) {
      final dx = center.dx + (rng.nextDouble() - 0.5) * radius * 2;
      final dy = center.dy + (rng.nextDouble() - 0.5) * radius * 2;
      if ((Offset(dx, dy) - center).distance <= radius) {
        canvas.drawCircle(Offset(dx, dy), 0.5, grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SkyBodyPainter old) => old.altitude != altitude;
}
