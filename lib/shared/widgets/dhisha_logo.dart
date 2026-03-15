import 'dart:math';
import 'package:flutter/material.dart';

class DhishaLogo extends StatelessWidget {
  final double size;
  final Color foregroundColor;
  final Color accentColor;
  final double progress; // 0.0 to 1.0 for the stroke drawing
  final double pointerOpacity;
  final double pointerScale;

  const DhishaLogo({
    super.key,
    required this.size,
    required this.foregroundColor,
    required this.accentColor,
    this.progress = 1.0,
    this.pointerOpacity = 1.0,
    this.pointerScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DhishaLogoPainter(
        color: foregroundColor,
        accent: accentColor,
        progress: progress,
        pointerOpacity: pointerOpacity,
        pointerScale: pointerScale,
      ),
    );
  }
}

class _DhishaLogoPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final double progress;
  final double pointerOpacity;
  final double pointerScale;

  _DhishaLogoPainter({
    required this.color,
    required this.accent,
    required this.progress,
    required this.pointerOpacity,
    required this.pointerScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Circle
    final circlePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final sweepAngle = pi * 2 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at North
      sweepAngle,
      false,
      circlePaint,
    );

    // 2. Crosshairs (N-S, E-W)
    if (progress > 0.5) {
      final lineProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final linePaint =
          Paint()
            ..color = color.withAlpha((lineProgress * 255).toInt())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

      // N-S
      canvas.drawLine(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        linePaint,
      );
      // E-W
      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        linePaint,
      );
    }

    // 3. Pointer (NNW ~ 345 deg)
    if (pointerOpacity > 0) {
      final pointerPaint =
          Paint()
            ..color = accent.withAlpha((pointerOpacity * 255).toInt())
            ..style = PaintingStyle.fill;

      // 345 degrees = -15 degrees from North (-90) = -105 degrees
      final angle = -105 * pi / 180;
      final perp = angle + pi / 2;
      final pointerPath = Path();

      // Tip points to edge
      final tip = Offset(
        center.dx + radius * 0.95 * cos(angle),
        center.dy + radius * 0.95 * sin(angle),
      );

      // Base is wider
      final baseLeft = Offset(
        center.dx + radius * 0.55 * cos(angle) + 4 * cos(perp),
        center.dy + radius * 0.55 * sin(angle) + 4 * sin(perp),
      );
      final baseRight = Offset(
        center.dx + radius * 0.55 * cos(angle) - 4 * cos(perp),
        center.dy + radius * 0.55 * sin(angle) - 4 * sin(perp),
      );

      pointerPath.moveTo(tip.dx, tip.dy);
      pointerPath.lineTo(baseLeft.dx, baseLeft.dy);
      pointerPath.lineTo(baseRight.dx, baseRight.dy);
      pointerPath.close();

      canvas.save();
      final pCenter = Offset(
        center.dx + radius * 0.75 * cos(angle),
        center.dy + radius * 0.75 * sin(angle),
      );
      canvas.translate(pCenter.dx, pCenter.dy);
      canvas.scale(pointerScale);
      canvas.translate(-pCenter.dx, -pCenter.dy);

      canvas.drawPath(pointerPath, pointerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DhishaLogoPainter old) {
    return old.color != color ||
        old.accent != accent ||
        old.progress != progress ||
        old.pointerOpacity != pointerOpacity ||
        old.pointerScale != pointerScale;
  }
}
