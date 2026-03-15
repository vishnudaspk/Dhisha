import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../../core/theme/app_theme.dart';

class WindCompass extends StatefulWidget {
  final double primaryDirection;
  final double secondaryDirection;

  const WindCompass({
    super.key,
    required this.primaryDirection,
    required this.secondaryDirection,
  });

  @override
  State<WindCompass> createState() => _WindCompassState();
}

class _WindCompassState extends State<WindCompass>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  double _primaryDir = 0;
  double _secondaryDir = 0;

  @override
  void initState() {
    super.initState();
    _primaryController = AnimationController.unbounded(vsync: this);
    _secondaryController = AnimationController.unbounded(vsync: this);

    _primaryController.addListener(() {
      setState(() {
        _primaryDir = _primaryController.value;
      });
    });
    _secondaryController.addListener(() {
      setState(() {
        _secondaryDir = _secondaryController.value;
      });
    });

    _animatePrimary(widget.primaryDirection);
    _animateSecondary(widget.secondaryDirection);
  }

  void _animatePrimary(double target) {
    double diff = target - _primaryDir;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final targetVal = _primaryDir + diff;

    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);
    final simulation = SpringSimulation(
      spring,
      _primaryDir,
      targetVal,
      _primaryController.velocity,
    );
    _primaryController.animateWith(simulation);
  }

  void _animateSecondary(double target) {
    double diff = target - _secondaryDir;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final targetVal = _secondaryDir + diff;

    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 22);
    final simulation = SpringSimulation(
      spring,
      _secondaryDir,
      targetVal,
      _secondaryController.velocity,
    );
    _secondaryController.animateWith(simulation);
  }

  @override
  void didUpdateWidget(WindCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryDirection != widget.primaryDirection) {
      _animatePrimary(widget.primaryDirection);
    }
    if (oldWidget.secondaryDirection != widget.secondaryDirection) {
      _animateSecondary(widget.secondaryDirection);
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _WindArrowsPainter(
        context: context,
        primaryDirection: _primaryDir,
        secondaryDirection: _secondaryDir,
      ),
    );
  }
}

class _WindArrowsPainter extends CustomPainter {
  final BuildContext context;
  final double primaryDirection;
  final double secondaryDirection;

  _WindArrowsPainter({
    required this.context,
    required this.primaryDirection,
    required this.secondaryDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowLen = size.width / 2 * 0.85;

    // Outer 0.5dp tick ring
    final tickPaint =
        Paint()
          ..color = AppColors.textPrimary(context).withAlpha(40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 0; i < 360; i += 10) {
      final isMajor = i % 90 == 0;
      final tLen = isMajor ? 8.0 : 4.0;
      final angle = (i - 90) * pi / 180;

      canvas.drawLine(
        Offset(
          center.dx + (arrowLen) * cos(angle),
          center.dy + (arrowLen) * sin(angle),
        ),
        Offset(
          center.dx + (arrowLen - tLen) * cos(angle),
          center.dy + (arrowLen - tLen) * sin(angle),
        ),
        tickPaint,
      );
    }

    // Eye of the Wind (Origin)
    final originAngle = (primaryDirection - 90) * pi / 180;

    final eyePaint =
        Paint()
          ..color = AppColors.windAccent(context)
          ..style = PaintingStyle.fill;

    // Solid 8dp dot at origin
    final originCenter = Offset(
      center.dx + (arrowLen - 20) * cos(originAngle),
      center.dy + (arrowLen - 20) * sin(originAngle),
    );
    canvas.drawCircle(originCenter, 4, eyePaint);

    // 4 directional ticks pointing towards center
    final crossPaint =
        Paint()
          ..color = AppColors.windAccent(context)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.butt;

    final tickLen = 4.0;
    for (int i = 0; i < 4; i++) {
      final tickAngle = originAngle + (i * pi / 2);
      canvas.drawLine(
        Offset(
          originCenter.dx + 4 * cos(tickAngle),
          originCenter.dy + 4 * sin(tickAngle),
        ),
        Offset(
          originCenter.dx + (4 + tickLen) * cos(tickAngle),
          originCenter.dy + (4 + tickLen) * sin(tickAngle),
        ),
        crossPaint,
      );
    }

    // Secondary eye (just a tiny dot for context)
    if (secondaryDirection >= 0) {
      final secAngle = (secondaryDirection - 90) * pi / 180;
      final secCenter = Offset(
        center.dx + (arrowLen - 20) * cos(secAngle),
        center.dy + (arrowLen - 20) * sin(secAngle),
      );
      canvas.drawCircle(
        secCenter,
        2,
        Paint()..color = AppColors.textPrimary(context).withAlpha(100),
      );
    }
  }

  @override
  bool shouldRepaint(_WindArrowsPainter old) =>
      old.primaryDirection != primaryDirection ||
      old.secondaryDirection != secondaryDirection;
}
