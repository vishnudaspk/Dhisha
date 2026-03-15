import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../../core/theme/app_theme.dart';

class AzimuthCompass extends StatefulWidget {
  final double azimuth;
  final double altitude;

  const AzimuthCompass({
    super.key,
    required this.azimuth,
    required this.altitude,
  });

  @override
  State<AzimuthCompass> createState() => _AzimuthCompassState();
}

class _AzimuthCompassState extends State<AzimuthCompass>
    with TickerProviderStateMixin {
  late AnimationController _azController;
  late AnimationController _altController;
  
  double _currentAzimuth = 0;
  double _currentAltitude = 0;

  @override
  void initState() {
    super.initState();
    _azController = AnimationController.unbounded(vsync: this);
    _altController = AnimationController.unbounded(vsync: this);
    
    _azController.addListener(() {
      setState(() {
        _currentAzimuth = _azController.value;
      });
    });
    _altController.addListener(() {
      setState(() {
        _currentAltitude = _altController.value;
      });
    });
    
    _animateAzimuth(widget.azimuth);
    _animateAltitude(widget.altitude);
  }

  void _animateAzimuth(double target) {
    double diff = target - _currentAzimuth;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final targetVal = _currentAzimuth + diff;

    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);
    final simulation = SpringSimulation(
      spring,
      _currentAzimuth,
      targetVal,
      _azController.velocity,
    );
    _azController.animateWith(simulation);
  }

  void _animateAltitude(double target) {
    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);
    final simulation = SpringSimulation(
      spring,
      _currentAltitude,
      target,
      _altController.velocity,
    );
    _altController.animateWith(simulation);
  }

  @override
  void didUpdateWidget(AzimuthCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.azimuth != widget.azimuth) {
      _animateAzimuth(widget.azimuth);
    }
    if (oldWidget.altitude != widget.altitude) {
      _animateAltitude(widget.altitude);
    }
  }

  @override
  void dispose() {
    _azController.dispose();
    _altController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _AzimuthPainter(
        context: context,
        azimuth: _currentAzimuth,
        altitude: _currentAltitude,
      ),
    );
  }
}

class _AzimuthPainter extends CustomPainter {
  final BuildContext context;
  final double azimuth;
  final double altitude;

  _AzimuthPainter({
    required this.context,
    required this.azimuth,
    required this.altitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 0.85;

    final primaryColor = AppColors.textPrimary(context);
    final accentColor = AppColors.sunAccent(context);

    // ─── BACKGROUND RINGS (Altitude Scale) ───────────────────────────────────
    final ringPaint = Paint()
      ..color = primaryColor.withAlpha(20) // very faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric rings: Horizon (0°), 30°, 60°
    canvas.drawCircle(center, maxRadius, ringPaint); // 0° Horizon
    canvas.drawCircle(center, maxRadius * 0.666, ringPaint); // 30°
    canvas.drawCircle(center, maxRadius * 0.333, ringPaint); // 60°
    
    // Tiny center dot (90° Zenith)
    canvas.drawCircle(
      center, 
      1.5, 
      Paint()..color = primaryColor.withAlpha(60)..style = PaintingStyle.fill
    );

    // ─── CROSSHAIRS ──────────────────────────────────────────────────────────
    final crosshairPaint = Paint()
      ..color = primaryColor.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crosshairPaint,
    );

    // ─── TICKS AROUND HORIZON ────────────────────────────────────────────────
    final tickPaint = Paint()
      ..color = primaryColor.withAlpha(40)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 72; i++) { // Every 5 degrees
      final isMajor = i % 9 == 0; // Every 45 degrees
      final angle = i * 5 * pi / 180;
      final tickLen = isMajor ? 6.0 : 3.0;
      
      tickPaint.color = primaryColor.withAlpha(isMajor ? 80 : 30);
      tickPaint.strokeWidth = isMajor ? 1.5 : 1.0;

      canvas.drawLine(
        Offset(
          center.dx + (maxRadius - tickLen) * cos(angle),
          center.dy + (maxRadius - tickLen) * sin(angle),
        ),
        Offset(
          center.dx + maxRadius * cos(angle),
          center.dy + maxRadius * sin(angle),
        ),
        tickPaint,
      );
    }

    // ─── SUN POSITION ────────────────────────────────────────────────────────
    // Polar coordinate mapping:
    // Angle = azimuth (0° is North/UP, so subtract 90°)
    // Radius = 90° altitude is center (0), 0° altitude is maxRadius.
    // Negative altitudes (night) go outside the horizon ring.
    final normalizedAzimuth = azimuth % 360;
    final sunAngle = (normalizedAzimuth - 90) * pi / 180;
    
    // Distance from center representing altitude
    final altRatio = (90.0 - altitude) / 90.0;
    final sunRadius = maxRadius * altRatio;

    final sunOffset = Offset(
      center.dx + sunRadius * cos(sunAngle),
      center.dy + sunRadius * sin(sunAngle),
    );

    // Connect center to sun with an elegant line
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        center,
        sunOffset,
        [accentColor.withAlpha(0), accentColor.withAlpha(120)],
      )
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (altitude > -18.0) { // Don't draw line if it's deep night
      canvas.drawLine(center, sunOffset, linePaint);
    }

    // Draw the Sun marker (glow + core)
    final isNight = altitude <= 0;
    final sunColor = isNight ? primaryColor.withAlpha(100) : accentColor;

    canvas.drawCircle(
      sunOffset,
      8,
      Paint()
        ..color = sunColor.withAlpha(isNight ? 20 : 60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      sunOffset,
      4,
      Paint()
        ..color = sunColor
        ..style = PaintingStyle.fill,
    );

    // Inner empty cut-out to make it look like a lens/reticle
    canvas.drawCircle(
      sunOffset,
      2,
      Paint()
        ..color = AppColors.surface(context)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_AzimuthPainter old) =>
      old.azimuth != azimuth || old.altitude != altitude;
}
