// dart:math not needed
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/solar_calculator.dart';

/// A self-contained, glassmorphic sun-path panel.
///
/// Replaces both the old thin-line chart and the separate SunInfoStrip.
/// Draws a glowing parabolic arc for today's solar path, a live animated
/// sun dot, and embedded key-time labels — all inside one frosted card.
class SunPathChart extends StatefulWidget {
  final List<MonthlyArc> arcs; // kept for API compat, not plotted here
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
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _pulseController;
  late Animation<double> _drawAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _drawController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _drawAnim = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final solar = widget.currentPosition;
    final isNight = solar.altitude <= 0;
    final hasSun = solar.sunrise != null && solar.sunset != null;

    if (!hasSun) {
      return _PolarCard(isNight: isNight);
    }

    // ── Colour palette ────────────────────────────────────────────────
    // Night: deep indigo / silver-blue
    // Day:   warm amber / golden
    const Color arcDay   = Color(0xFFFFC857);
    const Color arcGlow  = Color(0xFFFF8C42);
    const Color arcNight = Color(0xFF7EB8F7);
    const Color glowNight = Color(0xFF4A90D9);

    final arcPrimary = isNight ? arcNight : arcDay;
    final arcSecondary = isNight ? glowNight : arcGlow;

    // Day-length string
    final rise = solar.sunrise!;
    final set  = solar.sunset!;
    final noon = solar.solarNoon;
    final dayDur = set.difference(rise);
    final dayHrs = dayDur.inHours;
    final dayMin = dayDur.inMinutes % 60;
    final dayLenStr = '${dayHrs}h ${dayMin.toString().padLeft(2, '0')}m';

    // Time format
    final fmt = DateFormat('HH:mm');
    final riseStr = fmt.format(rise);
    final noonStr = fmt.format(noon);
    final setStr  = fmt.format(set);

    // Daylight progress 0..1
    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
    final riseSec = rise.hour * 3600 + rise.minute * 60;
    final setSec  = set.hour  * 3600 + set.minute  * 60;
    final totalDaySec = (setSec - riseSec).clamp(1, 86400);
    final elapsedSec  = (nowSec - riseSec).clamp(0, totalDaySec);
    final progress = elapsedSec / totalDaySec; // 0 before sunrise, 1 after sunset

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isNight ? 12 : 18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha(30),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header row (section label + day length) ──────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '↓  PATH',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: Colors.white.withAlpha(80),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isNight
                              ? Icons.nights_stay_outlined
                              : Icons.wb_sunny_outlined,
                          color: arcPrimary.withAlpha(200),
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dayLenStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: arcPrimary.withAlpha(200),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'daylight',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white.withAlpha(70),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Arc painter ───────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_drawAnim, _pulseAnim]),
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(double.infinity, 110),
                      painter: _SolarArcPainter(
                        drawProgress: _drawAnim.value,
                        pulseValue: _pulseAnim.value,
                        sunrise: rise,
                        sunset: set,
                        solarNoon: noon,
                        currentAltitude: solar.altitude,
                        daylightProgress: isNight ? progress.clamp(0.0, 1.0) : progress,
                        arcPrimary: arcPrimary,
                        arcSecondary: arcSecondary,
                        isNight: isNight,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // ── Day-progress thin track ──────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: Colors.white.withAlpha(15),
                      ),
                      AnimatedBuilder(
                        animation: _drawAnim,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            widthFactor: (progress * _drawAnim.value).clamp(0.0, 1.0),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [arcSecondary.withAlpha(180), arcPrimary],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Three key-time anchors ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeAnchor(
                      label: 'RISE',
                      time: riseStr,
                      icon: Icons.wb_twilight_outlined,
                      color: arcSecondary,
                      align: CrossAxisAlignment.start,
                    ),
                    _TimeAnchor(
                      label: 'NOON',
                      time: noonStr,
                      icon: Icons.wb_sunny_outlined,
                      color: arcPrimary,
                      align: CrossAxisAlignment.center,
                    ),
                    _TimeAnchor(
                      label: 'SET',
                      time: setStr,
                      icon: Icons.nights_stay_outlined,
                      color: arcSecondary.withAlpha(180),
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Polar day / polar night fallback ─────────────────────────────────────────

class _PolarCard extends StatelessWidget {
  final bool isNight;
  const _PolarCard({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isNight ? 12 : 18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNight ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
                  color: Colors.white.withAlpha(80),
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  isNight ? 'Polar Night' : 'Polar Day',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(110),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Individual key-time label widget ─────────────────────────────────────────

class _TimeAnchor extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final CrossAxisAlignment align;

  const _TimeAnchor({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withAlpha(160), size: 11),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: Colors.white.withAlpha(70),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Custom painter: glowing solar arc ────────────────────────────────────────

class _SolarArcPainter extends CustomPainter {
  final double drawProgress;   // 0 → 1 (arc draws itself in)
  final double pulseValue;     // 0 → 1 (pulsing halo)
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final double currentAltitude;
  final double daylightProgress; // 0 = before/at sunrise, 1 = at/after sunset
  final Color arcPrimary;
  final Color arcSecondary;
  final bool isNight;

  _SolarArcPainter({
    required this.drawProgress,
    required this.pulseValue,
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.currentAltitude,
    required this.daylightProgress,
    required this.arcPrimary,
    required this.arcSecondary,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final riseSec = sunrise.hour * 3600 + sunrise.minute * 60;
    final setSec  = sunset.hour  * 3600 + sunset.minute  * 60;
    final noonSec = solarNoon.hour * 3600 + solarNoon.minute * 60;

    const double lm = 0;
    const double rm = 0;
    final double chartW = size.width - lm - rm;
    final double barY = size.height - 18;

    double timeToX(int sec) => lm + (sec / 86400.0) * chartW;

    final riseX = timeToX(riseSec);
    final setX  = timeToX(setSec);
    final noonX = timeToX(noonSec);

    // ── 1. Horizon base line ──────────────────────────────────────────
    final basePaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(lm, barY), Offset(size.width - rm, barY), basePaint);

    // ── 2. Daylight zone fill (gradient) ─────────────────────────────
    if (setX > riseX) {
      final fillRect = Rect.fromLTRB(riseX, barY - 90, setX, barY);
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            arcPrimary.withAlpha(isNight ? 10 : 20),
            arcPrimary.withAlpha(0),
          ],
        ).createShader(fillRect)
        ..style = PaintingStyle.fill;

      // Draw fill only under the arc (approximate with a path)
      final fillPath = Path();
      fillPath.moveTo(riseX, barY);
      final cp1X = riseX + (noonX - riseX) * 0.5;
      final cp2X = noonX + (setX - noonX) * 0.5;
      final cpY  = barY - 90 * 0.72;
      
      // Use same cubic bezier as arc
      fillPath.cubicTo(cp1X, cpY, cp2X, cpY, setX, barY);
      fillPath.lineTo(setX, barY);
      fillPath.lineTo(riseX, barY);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);

      // ── 3. The arc itself — clipped to drawProgress ───────────────
      final arcPath = Path();
      arcPath.moveTo(riseX, barY);
      arcPath.cubicTo(cp1X, cpY, cp2X, cpY, setX, barY);

      // Clip to draw only up to drawProgress
      final arcPainter = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [arcSecondary, arcPrimary, arcSecondary],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(riseX, 0, setX - riseX, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Measure path to clip by drawProgress
      final metrics = arcPath.computeMetrics();
      final clippedPath = Path();
      for (final metric in metrics) {
        final len = metric.length * drawProgress;
        if (len > 0) {
          clippedPath.addPath(
            metric.extractPath(0, len),
            Offset.zero,
          );
        }
        break;
      }

      // Glow layer (wider, softer)
      canvas.drawPath(
        clippedPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              arcSecondary.withAlpha(60),
              arcPrimary.withAlpha(80),
              arcSecondary.withAlpha(60),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(riseX, 0, setX - riseX, size.height))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round,
      );

      // Main arc line
      canvas.drawPath(clippedPath, arcPainter);

      // ── 4. Current position dot on arc ───────────────────────────
      if (drawProgress >= 0.85) {
        final t = daylightProgress.clamp(0.0, 1.0);
        // Cubic bezier point at parameter t
        // P(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
        final p0 = Offset(riseX, barY);
        final p1 = Offset(cp1X, cpY);
        final p2 = Offset(cp2X, cpY);
        final p3 = Offset(setX, barY);
        final dotPos = _cubicPoint(p0, p1, p2, p3, t);

        // Pulsing outer halo
        final halosRadius = 12.0 + 4.0 * pulseValue;
        canvas.drawCircle(
          dotPos,
          halosRadius,
          Paint()..color = arcPrimary.withAlpha((30 * (1 - pulseValue)).round()),
        );

        // Inner + outer glow rings
        canvas.drawCircle(
          dotPos,
          8.0,
          Paint()..color = arcPrimary.withAlpha(60),
        );

        // Filled dot
        canvas.drawCircle(
          dotPos,
          4.5,
          Paint()
            ..color = arcPrimary
            ..style = PaintingStyle.fill,
        );

        // White centre pip
        canvas.drawCircle(
          dotPos,
          1.8,
          Paint()..color = Colors.white,
        );
      }

      // ── 5. Tick marks at key times ────────────────────────────────
      if (drawProgress >= 0.95) {
        void drawTick(double x) {
          canvas.drawLine(
            Offset(x, barY - 5),
            Offset(x, barY + 5),
            Paint()
              ..color = Colors.white.withAlpha(40)
              ..strokeWidth = 0.8,
          );
        }
        drawTick(riseX);
        drawTick(noonX);
        drawTick(setX);
      }
    }

    // ── 6. Tiny "now" vertical needle on horizon bar ─────────────────
    if (drawProgress >= 0.9) {
      final now = DateTime.now();
      final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
      final nowX = timeToX(nowSec);
      if (nowX > lm && nowX < size.width - rm) {
        canvas.drawLine(
          Offset(nowX, barY - 8),
          Offset(nowX, barY + 8),
          Paint()
            ..color = Colors.white.withAlpha(120)
            ..strokeWidth = 1.0,
        );
        // Small label "NOW"
        final tp = TextPainter(
          text: TextSpan(
            text: 'NOW',
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.white.withAlpha(100),
              fontFamily: 'Inter',
              package: 'google_fonts',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        double labelX = nowX - tp.width / 2;
        labelX = labelX.clamp(lm, size.width - rm - tp.width);
        tp.paint(canvas, Offset(labelX, barY + 10));
      }
    }
  }

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1.0 - t;
    final x = mt * mt * mt * p0.dx +
        3 * mt * mt * t * p1.dx +
        3 * mt * t * t * p2.dx +
        t * t * t * p3.dx;
    final y = mt * mt * mt * p0.dy +
        3 * mt * mt * t * p1.dy +
        3 * mt * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_SolarArcPainter old) =>
      old.drawProgress != drawProgress ||
      old.pulseValue != pulseValue ||
      old.currentAltitude != currentAltitude;
}
