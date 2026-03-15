import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A massive animated sun (or moon) circle — the editorial hero element for
/// the Sun tab, inspired by (Not Boring) Weather.
///
/// The circle's vertical position shifts based on [altitude]:
///   • altitude = 90° (zenith):  circle centre sits at 20% from screen top.
///   • altitude = 0  (horizon):  circle is 60% occluded below the bottom.
///   • altitude < 0  (night):    morphs to a cool moon disc.
class SunHeroCircle extends StatefulWidget {
  final double altitude; // -90 to 90 degrees

  const SunHeroCircle({super.key, required this.altitude});

  @override
  State<SunHeroCircle> createState() => _SunHeroCircleState();
}

class _SunHeroCircleState extends State<SunHeroCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _altAnim;
  double _prevAlt = 0;

  @override
  void initState() {
    super.initState();
    _prevAlt = widget.altitude;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _altAnim = AlwaysStoppedAnimation(_prevAlt);
  }

  @override
  void didUpdateWidget(SunHeroCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.altitude != widget.altitude) {
      _altAnim = Tween<double>(
        begin: _prevAlt,
        end: widget.altitude,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _prevAlt = widget.altitude;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.altitude <= 0;
    return AnimatedBuilder(
      animation: _altAnim,
      builder: (context, _) {
        return CustomPaint(
          painter: _SunCirclePainter(
            altitude: _altAnim.value,
            isNight: isNight,
            context: context,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SunCirclePainter extends CustomPainter {
  final double altitude;
  final bool isNight;
  final BuildContext context;

  _SunCirclePainter({
    required this.altitude,
    required this.isNight,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Circle diameter = 72% of screen width
    final diameter = size.width * 0.72;
    final radius = diameter / 2;

    // Y offset: alt 90° → top 20%, alt 0° → 60% occluded below, alt <0 → clamp
    // Map altitude from [90, -20] → [top20% - radius, bottom + radius*0.6]
    final topAnchor = size.height * 0.05 + radius;   // zenith: circle top at 5%
    final horizonAnchor = size.height * 0.6 + radius; // horizon: 60% cut off below

    final altFraction = (altitude.clamp(-10.0, 90.0) + 10) / 100.0;
    final cy = horizonAnchor + (topAnchor - horizonAnchor) * altFraction;
    final center = Offset(size.width / 2, cy);

    // ── COLOR ─────────────────────────────────────────────────────────────────
    final Color circleColor;
    final Color sunCenter;
    if (isNight) {
      circleColor = const Color(0xFF8FA8C8); // cool moonlight grey-blue
      sunCenter   = const Color(0xFFA8BDD4);
    } else {
      circleColor = AppColors.sunRed;
      sunCenter   = const Color(0xFFFF6B47);
    }

    // ── GRADIENT + GRAINY CIRCLE ──────────────────────────────────────────────
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [sunCenter, circleColor],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, fillPaint);

    // Grain texture — fixed seed (42) for consistency
    final random = math.Random(42);
    final grainAlphaInt = isNight ? 8 : 10;
    final grainPaint = Paint()
      ..color = Colors.black.withAlpha(grainAlphaInt);
    const grainDots = 2200;
    for (int i = 0; i < grainDots; i++) {
      final dx = center.dx + (random.nextDouble() - 0.5) * diameter;
      final dy = center.dy + (random.nextDouble() - 0.5) * diameter;
      if ((Offset(dx, dy) - center).distance <= radius) {
        canvas.drawCircle(Offset(dx, dy), 0.6, grainPaint);
      }
    }

    // Outer glow for moon mode
    if (isNight) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = const Color(0xFF8FA8C8).withAlpha(26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunCirclePainter old) =>
      old.altitude != altitude || old.isNight != isNight;
}
