import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AltitudeGauge extends StatefulWidget {
  final double altitude;
  final double azimuth;

  const AltitudeGauge({
    super.key,
    required this.altitude,
    required this.azimuth,
  });

  @override
  State<AltitudeGauge> createState() => _AltitudeGaugeState();
}

class _AltitudeGaugeState extends State<AltitudeGauge>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _nightController;
  late Animation<double> _nightAnim;
  double _currentAltitude = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _controller.addListener(() {
      setState(() {
        _currentAltitude = _controller.value;
      });
    });

    _nightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _nightAnim = CurvedAnimation(
      parent: _nightController,
      curve: Curves.easeInOut,
    );

    if (widget.altitude <= 0) {
      _nightController.value = 1.0;
    }

    _animateTo(widget.altitude);
  }

  void _animateTo(double target) {
    if (_controller.value == target) return;
    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);
    final simulation = SpringSimulation(
      spring,
      _currentAltitude,
      target,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  void didUpdateWidget(AltitudeGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.altitude != widget.altitude) {
      _animateTo(widget.altitude);
    }

    final isNightNow = widget.altitude <= 0;
    final wasNight = oldWidget.altitude <= 0;
    if (isNightNow && !wasNight) {
      _nightController.forward();
    } else if (!isNightNow && wasNight) {
      _nightController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _nightController]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 220,
          color:
              Colors.transparent, // Rule 4, 5: No card background, no shadows
          child: CustomPaint(
            painter: _MinimalAltitudePainter(
              context: context,
              altitude: _currentAltitude,
              nightProgress: _nightAnim.value,
            ),
          ),
        );
      },
    );
  }
}

class _MinimalAltitudePainter extends CustomPainter {
  final BuildContext context;
  final double altitude;
  final double nightProgress;

  _MinimalAltitudePainter({
    required this.context,
    required this.altitude,
    required this.nightProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 - 25.0;

    // Background arc (max 8% opacity)
    final bgPaint =
        Paint()
          ..color = AppColors.sunAccent(context).withAlpha(20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Cardinal direction indicators (N, E, S, W)
    final directions = ['N', 'E', 'S', 'W'];
    final dirAngles = [-pi / 2, 0.0, pi / 2, pi]; // Top, Right, Bottom, Left
    for (int i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context).withAlpha(115), // 45% opacity
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offsetDist = radius + 14;
      final dx = center.dx + offsetDist * cos(dirAngles[i]) - tp.width / 2;
      final dy = center.dy + offsetDist * sin(dirAngles[i]) - tp.height / 2;
      tp.paint(canvas, Offset(dx, dy));
    }

    // Tick marks
    final tickPaint =
        Paint()
          ..color = AppColors.textPrimary(context).withAlpha(128)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.butt;

    for (int i = 0; i <= 180; i += 10) {
      final angle = pi + (i * pi / 180);
      final isMajor = i % 30 == 0;
      final tickLength = isMajor ? 6.0 : 3.0;

      final innerRad = radius;
      final outerRad = radius + tickLength;

      canvas.drawLine(
        Offset(
          center.dx + innerRad * cos(angle),
          center.dy + innerRad * sin(angle),
        ),
        Offset(
          center.dx + outerRad * cos(angle),
          center.dy + outerRad * sin(angle),
        ),
        tickPaint,
      );
    }

    // Needle
    final clampedAlt = altitude.clamp(0.0, 180.0);
    final needleAngle = pi + (clampedAlt * pi / 180);

    final needleRadius = radius - 8;
    final needlePaint =
        Paint()
          ..color = AppColors.sunAccent(context)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      center,
      Offset(
        center.dx + needleRadius * cos(needleAngle),
        center.dy + needleRadius * sin(needleAngle),
      ),
      needlePaint,
    );

    // Labels inside (Rule 5)
    final tpAltValue = TextPainter(
      text: TextSpan(
        text: '${altitude.toStringAsFixed(1)}°',
        style: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: -1.0,
          color: AppColors.textPrimary(context),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tpAltLabel = TextPainter(
      text: TextSpan(
        text: 'ALTITUDE',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary(context).withAlpha(115),
          letterSpacing: 1.32,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final valueOffset = Offset(
      center.dx - tpAltValue.width / 2,
      center.dy - radius / 2 - 4,
    );
    tpAltLabel.paint(
      canvas,
      Offset(center.dx - tpAltLabel.width / 2, center.dy - radius / 2 - 24),
    );
    tpAltValue.paint(canvas, valueOffset);

    // Crossfade Sun/Moon icons
    final dayOpacity = (1.0 - nightProgress).clamp(0.0, 1.0);
    final nightOpacity = nightProgress.clamp(0.0, 1.0);
    final iconX = valueOffset.dx + tpAltValue.width + 6;
    final iconY = valueOffset.dy + 8;

    if (dayOpacity > 0) {
      final tpSun = TextPainter(
        text: TextSpan(
          text: '☀',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: AppColors.sunAccent(
              context,
            ).withAlpha((dayOpacity * 255).round()),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpSun.paint(canvas, Offset(iconX, iconY));
    }

    if (nightOpacity > 0) {
      final tpMoon = TextPainter(
        text: TextSpan(
          text: '☽',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: const Color(
              0xFF2E7BFF,
            ).withAlpha(((0.6 * nightOpacity) * 255).round()),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpMoon.paint(canvas, Offset(iconX, iconY));
    }
  }

  @override
  bool shouldRepaint(_MinimalAltitudePainter oldDelegate) =>
      oldDelegate.altitude != altitude ||
      oldDelegate.nightProgress != nightProgress;
}
