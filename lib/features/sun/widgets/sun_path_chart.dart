import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/solar_calculator.dart';
import 'package:google_fonts/google_fonts.dart';

class SunPathChart extends StatefulWidget {
  final List<MonthlyArc> arcs;
  final SolarPosition currentPosition;

  const SunPathChart({
    super.key,
    required this.arcs,
    required this.currentPosition,
  });

  @override
  State<SunPathChart> createState() => _SunPathChartState();
}

class _SunPathChartState extends State<SunPathChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPosition.sunrise == null ||
        widget.currentPosition.sunset == null) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Polar day / Polar night',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _DaylightTimelinePainter(
            context: context,
            currentPosition: widget.currentPosition,
            animationProgress: _controller.value,
          ),
        );
      },
    );
  }
}

class _DaylightTimelinePainter extends CustomPainter {
  final BuildContext context;
  final SolarPosition currentPosition;
  final double animationProgress;

  _DaylightTimelinePainter({
    required this.context,
    required this.currentPosition,
    required this.animationProgress,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPosition.sunrise == null || currentPosition.sunset == null) {
      return;
    }

    final sunrise = currentPosition.sunrise!;
    final sunset = currentPosition.sunset!;
    final noon = currentPosition.solarNoon;

    final riseSec = sunrise.hour * 3600 + sunrise.minute * 60 + sunrise.second;
    final setSec = sunset.hour * 3600 + sunset.minute * 60 + sunset.second;
    
    // We map 00:00 to the left edge, 24:00 to the right edge.
    final double leftMargin = 28.0;
    final double rightMargin = 28.0;
    final double chartWidth = size.width - leftMargin - rightMargin;

    double timeToX(int seconds) {
      return leftMargin + (seconds / 86400.0) * chartWidth;
    }

    final riseX = timeToX(riseSec);
    final setX = timeToX(setSec);
    
    final barY = size.height - 30; // Y position of the main horizontal bar

    // 1. Draw the Base Bar (Night - Dark)
    final baseBarRect = RRect.fromLTRBR(
      leftMargin,
      barY - 4,
      size.width - rightMargin,
      barY + 4,
      const Radius.circular(4),
    );
    canvas.drawRRect(
      baseBarRect,
      Paint()
        ..color = AppColors.textSecondary(context).withAlpha(30)
        ..style = PaintingStyle.fill,
    );

    // 2. Draw the Daylight Segment (Accent color at 15% opacity)
    if (setX > riseX) {
      // Normal day
      final daySegment = RRect.fromLTRBR(
        riseX,
        barY - 4,
        setX,
        barY + 4,
        const Radius.circular(4),
      );
      canvas.drawRRect(
        daySegment,
        Paint()
          ..color = AppColors.sunAccent(context).withAlpha(40)
          ..style = PaintingStyle.fill,
      );
    }

    // 3. Current Time Dot (Animated to slide in)
    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
    final targetNowX = timeToX(nowSec);
    
    // Animate the dot position from left edge to its actual time
    final animatedNowX = leftMargin + (targetNowX - leftMargin) * animationProgress;

    // Dot ring (pulsing)
    final isNight = currentPosition.altitude <= 0;
    final dotColor = isNight ? const Color(0xFF2E7BFF) : AppColors.sunAccent(context);
    
    canvas.drawCircle(
      Offset(animatedNowX, barY),
      5 * animationProgress,
      Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill,
    );
    // Subtle pulse ring
    canvas.drawCircle(
      Offset(animatedNowX, barY),
      9 * animationProgress,
      Paint()
        ..color = dotColor.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (animationProgress < 0.9) return;

    // 4. Draw Time Labels below the bar
    void drawLabel(String labelText, String timeText, double x) {
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '$labelText ',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context).withAlpha(100),
              letterSpacing: 1.0,
            ),
          ),
          TextSpan(
            text: timeText,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary(context).withAlpha(150),
            ),
          ),
        ],
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      
      // Keep within bounds
      double paintX = x - tp.width / 2;
      if (paintX < leftMargin - 10) paintX = leftMargin - 10;
      if (paintX + tp.width > size.width - rightMargin + 10) {
        paintX = size.width - rightMargin + 10 - tp.width;
      }
      
      tp.paint(canvas, Offset(paintX, barY + 12));
    }

    drawLabel('RISE', _formatTime(sunrise), riseX);
    drawLabel('SET', _formatTime(sunset), setX);
    
    // Draw Noon label above the arc peak
    final noonSec = noon.hour * 3600 + noon.minute * 60 + noon.second;
    final noonX = timeToX(noonSec);
    
    // 5. Altitude Arc (parabola connecting riseX to setX, peaking at noonX)
    final arcHeight = size.height - 70; // Peak height above the bar
    final peakY = barY - arcHeight;

    final arcPath = Path();
    arcPath.moveTo(riseX, barY);
    
    // Quadratic bezier won't peak exactly at CP.
    // Instead, we use two cubic beziers or a simple parabola to ensure it passes through peakY at noonX.
    // Since this is just a sleek visual marker (timeline), a smooth curve peaking at noon is perfect.
    
    final cp1X = riseX + (noonX - riseX) / 2;
    final cp2X = noonX + (setX - noonX) / 2;
    
    // To make cubic bezier peak exactly at (noonX, peakY), the control points need to be higher.
    final cpY = peakY - (arcHeight * 0.3); 

    arcPath.cubicTo(cp1X, cpY, cp2X, cpY, setX, barY);

    canvas.drawPath(
      arcPath,
      Paint()
        ..color = AppColors.sunAccent(context).withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    
    // NOON Label at peak
    final noonSpan = TextSpan(
      children: [
        TextSpan(
          text: 'NOON ',
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context).withAlpha(120),
            letterSpacing: 1.0,
          ),
        ),
        TextSpan(
          text: _formatTime(noon),
          style: GoogleFonts.spaceMono(
            fontSize: 8,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary(context).withAlpha(180),
          ),
        ),
      ],
    );
    final noonTP = TextPainter(
      text: noonSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    noonTP.paint(canvas, Offset(noonX - noonTP.width / 2, peakY - noonTP.height - 4));
    
    // Draw current altitude on the arc if it's daytime
    if (!isNight) {
      // Find Y position for current X on the curve. Quick approximation:
      final t = (targetNowX - riseX) / (setX - riseX);
      if (t >= 0 && t <= 1) {
        // Curve formula for the cubic bezier we just drew is:
        // P(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
        // where P0=(riseX,barY), P1=(cp1X,cpY), P2=(cp2X,cpY), P3=(setX,barY)
        // Here we just need the Y coordinate:
        final ty = pow(1-t, 3) * barY + 3 * pow(1-t, 2) * t * cpY + 3 * (1-t) * t * t * cpY + pow(t, 3) * barY;
        
        canvas.drawCircle(
          Offset(targetNowX, ty),
          3,
          Paint()
            ..color = AppColors.sunAccent(context)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DaylightTimelinePainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress ||
      oldDelegate.currentPosition.altitude != currentPosition.altitude;
}
