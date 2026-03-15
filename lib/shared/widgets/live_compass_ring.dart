import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A live compass ring that:
///  • Draws the degree ring + N/E/S/W labels, counter-rotated by -heading so
///    cardinal directions always point correctly (geo-fixed ring).
///  • Has a fixed "device forward" indicator (triangle + line) that stays at
///    the 12 o'clock position regardless of rotation (represents the device).
///  • Wraps [child] widgets inside, which are also counter-rotated by -heading
///    so they stay geo-fixed even as the device turns.
///
/// Usage:
///   LiveCompassRing(
///     heading: 45.0,      // degrees (0 = N, 90 = E)
///     accentColor: AppColors.sunAccent(context),
///     child: YourWidget(),
///   )
class LiveCompassRing extends StatefulWidget {
  final double heading;
  final Widget? child;
  final Color accentColor;
  final double size;

  const LiveCompassRing({
    super.key,
    required this.heading,
    this.child,
    this.accentColor = const Color(0xFFFFB347),
    this.size = 280,
  });

  @override
  State<LiveCompassRing> createState() => _LiveCompassRingState();
}

class _LiveCompassRingState extends State<LiveCompassRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headingAnimation;
  double _prevHeading = 0;
  double _currentTarget = 0;

  @override
  void initState() {
    super.initState();
    _prevHeading = widget.heading;
    _currentTarget = widget.heading;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _headingAnimation = AlwaysStoppedAnimation(_prevHeading);
  }

  @override
  void didUpdateWidget(LiveCompassRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.heading - widget.heading).abs() > 0.1) {
      _prevHeading = _headingAnimation.value;

      // Shortest path wraparound
      var target = widget.heading;
      var diff = target - _prevHeading;
      if (diff > 180) target -= 360;
      if (diff < -180) target += 360;
      _currentTarget = target;

      _headingAnimation = Tween<double>(
        begin: _prevHeading,
        end: _currentTarget,
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
      animation: _headingAnimation,
      builder: (context, _) {
        final heading = _headingAnimation.value;
        final rotRad = -heading * pi / 180.0;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The rotating compass dial (rotates with device → geo-fixed labels)
              Transform.rotate(
                angle: rotRad,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _CompassDialPainter(
                    context: context,
                    accentColor: widget.accentColor,
                    heading: heading,
                  ),
                ),
              ),

              // Child content (geo-fixed: also counter-rotated so it doesn't spin)
              if (widget.child != null)
                Transform.rotate(angle: rotRad, child: widget.child),

              // Fixed device indicator overlay — always at 12 o'clock
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DeviceIndicatorPainter(
                  accentColor: widget.accentColor,
                ),
              ),

              // Heading readout
              Positioned(
                bottom: widget.size * 0.08,
                child: _HeadingLabel(
                  heading: ((heading % 360) + 360) % 360,
                  accentColor: widget.accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Compass dial painter ────────────────────────────────────────────────────

class _CompassDialPainter extends CustomPainter {
  final BuildContext context;
  final Color accentColor;
  final double heading;

  _CompassDialPainter({
    required this.context,
    required this.accentColor,
    required this.heading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 22;

    // Subtle outer glow ring
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = accentColor.withAlpha(18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Outer ring
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = AppColors.border(context).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner ring
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = AppColors.border(context).withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tick marks
    for (int deg = 0; deg < 360; deg += 5) {
      final angle = (deg - 90) * pi / 180;
      final isMajor = deg % 45 == 0;
      final isMid = deg % 15 == 0;
      final tickLen = isMajor ? 18.0 : (isMid ? 11.0 : 6.0);
      final tickWidth = isMajor ? 2.0 : (isMid ? 1.5 : 1.0);
      final tickColor =
          isMajor
              ? AppColors.textPrimary(context).withAlpha(200)
              : AppColors.textSecondary(context).withAlpha(isMid ? 140 : 80);

      canvas.drawLine(
        Offset(
          center.dx + (outerR - tickLen) * cos(angle),
          center.dy + (outerR - tickLen) * sin(angle),
        ),
        Offset(
          center.dx + outerR * cos(angle),
          center.dy + outerR * sin(angle),
        ),
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal labels (N E S W + intercardinals)
    final cardinals = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };

    for (final entry in cardinals.entries) {
      final deg = entry.key;
      final label = entry.value;
      final isMain = deg % 90 == 0;
      final angle = (deg - 90) * pi / 180;
      final labelR = outerR - (isMain ? 36 : 32);

      final labelPos = Offset(
        center.dx + labelR * cos(angle),
        center.dy + labelR * sin(angle),
      );

      // North special styling
      final isNorth = deg == 0;
      final textColor =
          isNorth
              ? accentColor
              : (isMain
                  ? AppColors.textPrimary(context).withAlpha(220)
                  : AppColors.textSecondary(context).withAlpha(140));

      final span = TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: isMain ? (isNorth ? 14 : 12) : 9,
          fontWeight: isMain ? FontWeight.w700 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      );

      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();

      // North glow
      if (isNorth) {
        final glowPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: accentColor.withAlpha(80),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        glowPainter.paint(
          canvas,
          Offset(
            labelPos.dx - glowPainter.width / 2,
            labelPos.dy - glowPainter.height / 2,
          ),
        );
      }

      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_CompassDialPainter old) => old.heading != heading;
}

// ─── Device indicator painter (fixed at top / 12 o'clock) ───────────────────

class _DeviceIndicatorPainter extends CustomPainter {
  final Color accentColor;

  const _DeviceIndicatorPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;

    // Triangle indicator at 12 o'clock pointing inward
    final tipY = center.dy - outerR + 2;
    final baseY = tipY + 16;

    final path =
        Path()
          ..moveTo(center.dx, tipY)
          ..lineTo(center.dx - 7, baseY)
          ..lineTo(center.dx + 7, baseY)
          ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Short line down from triangle
    canvas.drawLine(
      Offset(center.dx, baseY),
      Offset(center.dx, baseY + 10),
      Paint()
        ..color = accentColor.withAlpha(160)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DeviceIndicatorPainter old) => false;
}

// ─── Heading readout label ───────────────────────────────────────────────────

class _HeadingLabel extends StatelessWidget {
  final double heading;
  final Color accentColor;

  const _HeadingLabel({required this.heading, required this.accentColor});

  String get _cardinalLabel {
    final h = ((heading % 360) + 360) % 360;
    if (h < 22.5 || h >= 337.5) return 'N';
    if (h < 67.5) return 'NE';
    if (h < 112.5) return 'E';
    if (h < 157.5) return 'SE';
    if (h < 202.5) return 'S';
    if (h < 247.5) return 'SW';
    if (h < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(context).withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Facing ',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '${heading.toStringAsFixed(0)}°',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            _cardinalLabel,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
