import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Vertical wind speed bar gauge with three color-coded threshold zones.
/// Calm (green), Moderate (amber), Strong (red).
/// Icon markers instead of numbers.
class WindSpeedBar extends StatefulWidget {
  final double speed; // km/h
  final double maxSpeed; // km/h (scale max)

  const WindSpeedBar({super.key, required this.speed, this.maxSpeed = 72});

  @override
  State<WindSpeedBar> createState() => _WindSpeedBarState();
}

class _WindSpeedBarState extends State<WindSpeedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fillAnimation = Tween<double>(
      begin: 0,
      end: (widget.speed / widget.maxSpeed).clamp(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(WindSpeedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: (widget.speed / widget.maxSpeed).clamp(0, 1),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
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
    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, _) {
        return SizedBox(
          width: 50,
          height: 200,
          child: CustomPaint(
            painter: _WindSpeedBarPainter(
              context: context,
              fillLevel: _fillAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class _WindSpeedBarPainter extends CustomPainter {
  final BuildContext context;
  final double fillLevel;

  _WindSpeedBarPainter({required this.context, required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 20.0;
    final barHeight = size.height - 40;
    final barLeft = (size.width - barWidth) / 2;
    final barTop = 20.0;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      const Radius.circular(10),
    );

    // Background
    canvas.drawRRect(barRect, Paint()..color = AppColors.border(context));

    // Fill level (from bottom up)
    final fillHeight = barHeight * fillLevel;
    final fillTop = barTop + barHeight - fillHeight;

    // Determine color based on fill level
    Color fillColor;
    if (fillLevel < 0.33) {
      fillColor = AppColors.calm;
    } else if (fillLevel < 0.66) {
      fillColor = AppColors.moderate;
    } else {
      fillColor = AppColors.strong;
    }

    // Gradient fill
    final fillRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(barLeft, fillTop, barWidth, fillHeight),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
      topLeft:
          fillHeight >= barHeight ? const Radius.circular(10) : Radius.zero,
      topRight:
          fillHeight >= barHeight ? const Radius.circular(10) : Radius.zero,
    );

    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [fillColor, fillColor.withAlpha(179)],
          ).createShader(fillRect.outerRect);

    canvas.drawRRect(fillRect, gradientPaint);

    // Glow
    final glowPaint =
        Paint()
          ..color = fillColor.withAlpha(51)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(fillRect, glowPaint);

    // Zone markers (icon indicators on the left side)
    final iconSize = 12.0;

    // Calm zone marker (leaf) - bottom third
    _drawLeafIcon(
      canvas,
      Offset(barLeft - 14, barTop + barHeight * 0.83),
      iconSize,
      AppColors.calm,
    );

    // Moderate zone marker (flag) - middle third
    _drawFlagIcon(
      canvas,
      Offset(barLeft - 14, barTop + barHeight * 0.50),
      iconSize,
      AppColors.moderate,
    );

    // Strong zone marker (warning triangle) - top third
    _drawWarningIcon(
      canvas,
      Offset(barLeft - 14, barTop + barHeight * 0.17),
      iconSize,
      AppColors.strong,
    );

    // Zone separator lines
    final sepPaint =
        Paint()
          ..color = AppColors.textSecondary(context).withAlpha(51)
          ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(barLeft, barTop + barHeight * 0.33),
      Offset(barLeft + barWidth, barTop + barHeight * 0.33),
      sepPaint,
    );
    canvas.drawLine(
      Offset(barLeft, barTop + barHeight * 0.66),
      Offset(barLeft + barWidth, barTop + barHeight * 0.66),
      sepPaint,
    );
  }

  void _drawLeafIcon(Canvas canvas, Offset center, double size, Color color) {
    final path =
        Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..quadraticBezierTo(
            center.dx + size / 2,
            center.dy,
            center.dx,
            center.dy + size / 2,
          )
          ..quadraticBezierTo(
            center.dx - size / 2,
            center.dy,
            center.dx,
            center.dy - size / 2,
          );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withAlpha(179)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawFlagIcon(Canvas canvas, Offset center, double size, Color color) {
    // Pole
    canvas.drawLine(
      Offset(center.dx - size / 4, center.dy - size / 2),
      Offset(center.dx - size / 4, center.dy + size / 2),
      Paint()
        ..color = color.withAlpha(179)
        ..strokeWidth = 1,
    );
    // Flag
    final path =
        Path()
          ..moveTo(center.dx - size / 4, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy - size / 4)
          ..lineTo(center.dx - size / 4, center.dy)
          ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withAlpha(179)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawWarningIcon(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
  ) {
    final path =
        Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy + size / 3)
          ..lineTo(center.dx - size / 2, center.dy + size / 3)
          ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withAlpha(179)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Exclamation dot
    canvas.drawCircle(
      Offset(center.dx, center.dy + size / 6),
      1.2,
      Paint()..color = color.withAlpha(179),
    );
  }

  @override
  bool shouldRepaint(_WindSpeedBarPainter oldDelegate) =>
      oldDelegate.fillLevel != fillLevel;
}
