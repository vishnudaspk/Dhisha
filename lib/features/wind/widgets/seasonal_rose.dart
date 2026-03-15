import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/wind_statistics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/physics.dart';

class SeasonalRose extends StatefulWidget {
  final Map<Season, SeasonalWindData> data;

  const SeasonalRose({super.key, required this.data});

  @override
  State<SeasonalRose> createState() => _SeasonalRoseState();
}

class _SeasonalRoseState extends State<SeasonalRose>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _summerAnim;
  late Animation<double> _monsoonAnim;
  late Animation<double> _winterAnim;
  late Animation<double> _springAnim;

  Season? _selectedSeason;
  late AnimationController _springController;
  double _springScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _summerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
    );
    _monsoonAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.68, curve: Curves.easeOutQuart),
    );
    _winterAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.86, curve: Curves.easeOutQuart),
    );
    _springAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuart),
    );

    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(() {
      setState(() {
        _springScale = _springController.value;
      });
    });

    _controller.forward();
  }

  void _handleTap(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Calculate angle in degrees (0 is North, clockwise)
    var angle = atan2(dy, dx) * 180 / pi + 90;
    if (angle < 0) angle += 360;

    // Find closest petal by angle
    Season? closest;
    double minDiff = 360;

    for (final entry in widget.data.entries) {
      final dataAngle = entry.value.direction;
      var diff = (dataAngle - angle).abs();
      if (diff > 180) diff = 360 - diff;

      if (diff < minDiff) {
        minDiff = diff;
        closest = entry.key;
      }
    }

    // If within ~45 degrees of a petal, select it
    if (closest != null && minDiff <= 45) {
      if (_selectedSeason == closest) {
        _selectedSeason = null; // deselect
      } else {
        _selectedSeason = closest;
        _animateSpringTension();
      }
    } else {
      _selectedSeason = null;
    }
    setState(() {});
  }

  void _animateSpringTension() {
    _springController.value = 1.05; // start slightly expanded
    final spring = SpringDescription(mass: 1.0, stiffness: 200, damping: 15);
    final simulation = SpringSimulation(spring, 1.05, 1.0, 0);
    _springController.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _springController]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTapUp:
                  (details) =>
                      _handleTap(details.localPosition, const Size(260, 260)),
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _SeasonalRosePainter(
                  context: context,
                  data: widget.data,
                  summerScale: _summerAnim.value,
                  monsoonScale: _monsoonAnim.value,
                  winterScale: _winterAnim.value,
                  springScale: _springAnim.value,
                  selectedSeason: _selectedSeason,
                  interactiveScale: _springScale,
                ),
              ),
            ),
            if (_selectedSeason != null && widget.data[_selectedSeason] != null)
              _buildDetailCard(
                widget.data[_selectedSeason!]!,
                _selectedSeason!,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailCard(SeasonalWindData data, Season season) {
    final seasonName = season.toString().split('.').last.toUpperCase();
    return Positioned(
      bottom: -10, // Float right below
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textPrimary(context).withAlpha(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seasonName,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.speed.toStringAsFixed(1)} m/s',
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 24,
              color: AppColors.textPrimary(context).withAlpha(20),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GUSTS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.gusts.toStringAsFixed(1),
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonalRosePainter extends CustomPainter {
  final BuildContext context;
  final Map<Season, SeasonalWindData> data;
  final double summerScale;
  final double monsoonScale;
  final double winterScale;
  final double springScale;
  final Season? selectedSeason;
  final double interactiveScale;

  _SeasonalRosePainter({
    required this.context,
    required this.data,
    required this.summerScale,
    required this.monsoonScale,
    required this.winterScale,
    required this.springScale,
    required this.selectedSeason,
    required this.interactiveScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 40;

    // Ring circles: 0.5dp stroke, 12% opacity
    final bgPaint =
        Paint()
          ..color = AppColors.textPrimary(context).withAlpha(30) // 12%
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * i / 3, bgPaint);
    }

    _drawCompassLabels(canvas, center, maxRadius);

    final maxSpeed = data.values
        .map((d) => d.speed)
        .fold<double>(1.0, (a, b) => a > b ? a : b);

    for (final season in Season.values) {
      final seasonData = data[season];
      if (seasonData == null) continue;

      final direction = seasonData.direction;
      final normalizedSpeed = (seasonData.speed / maxSpeed).clamp(0.2, 1.0);

      double scale = 1.0;
      switch (season) {
        case Season.summer:
          scale = summerScale;
          break;
        case Season.monsoon:
          scale = monsoonScale;
          break;
        case Season.winter:
          scale = winterScale;
          break;
        case Season.spring:
          scale = springScale;
          break;
      }

      final petalLength = maxRadius * normalizedSpeed * scale;
      final angle = (direction - 90) * pi / 180;

      final isSelected = selectedSeason == season;
      final extraScale = isSelected ? interactiveScale : 1.0;
      final drawLength = petalLength * extraScale + (isSelected ? 8.0 : 0.0);

      final petalColor =
          isSelected
              ? AppColors.sunAccent(context)
              : AppColors.textPrimary(context);
      _drawPetal(canvas, center, angle, drawLength, petalColor, isSelected);

      // Draw season label line/text if resting and scale > 0.99
      if (scale > 0.99) {
        _drawPetalLabel(canvas, center, angle, drawLength, season, isSelected);
      }
    }

    // Center point: 4dp filled circle, monochrome
    canvas.drawCircle(
      center,
      4,
      Paint()..color = AppColors.textPrimary(context),
    );
  }

  void _drawCompassLabels(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final style = GoogleFonts.inter(
      color: AppColors.textPrimary(context).withAlpha(102), // 40%
      fontSize: 10,
      fontWeight: FontWeight.w400,
    );

    void paintText(String text, Offset pos) {
      textPainter.text = TextSpan(text: text, style: style);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    paintText('N', Offset(center.dx, center.dy - radius - 15));
    paintText('S', Offset(center.dx, center.dy + radius + 15));
    paintText('E', Offset(center.dx + radius + 15, center.dy));
    paintText('W', Offset(center.dx - radius - 15, center.dy));
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    Color baseColor,
    bool isSelected,
  ) {
    if (length <= 0) return;

    final perpAngle = angle + pi / 2;
    final halfWidth = isSelected ? 16.0 : 14.0;

    final tip = Offset(
      center.dx + length * cos(angle),
      center.dy + length * sin(angle),
    );

    final left = Offset(
      center.dx + halfWidth * cos(perpAngle),
      center.dy + halfWidth * sin(perpAngle),
    );

    final right = Offset(
      center.dx - halfWidth * cos(perpAngle),
      center.dy - halfWidth * sin(perpAngle),
    );

    final path = Path();
    path.moveTo(left.dx, left.dy);
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(right.dx, right.dy);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor.withAlpha(
          isSelected ? 51 : 38,
        ) // slightly more opaque if selected
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor.withAlpha(isSelected ? 200 : 153)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _drawPetalLabel(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    Season season,
    bool isSelected,
  ) {
    final tip = Offset(
      center.dx + (length + 4) * cos(angle),
      center.dy + (length + 4) * sin(angle),
    );
    final endPoint = Offset(
      center.dx + (length + 16) * cos(angle),
      center.dy + (length + 16) * sin(angle),
    );

    // Leader line
    final linePaint =
        Paint()
          ..color =
              isSelected
                  ? AppColors.sunAccent(context).withAlpha(128)
                  : AppColors.textPrimary(context).withAlpha(50)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
    canvas.drawLine(tip, endPoint, linePaint);

    // Season name and month range
    final names = {
      Season.summer: ('SUMMER', 'Jun–Aug'),
      Season.monsoon: ('MONSOON', 'Jul–Sep'),
      Season.winter: ('WINTER', 'Dec–Feb'),
      Season.spring: ('SPRING', 'Mar–May'),
    };
    final (name, months) = names[season]!;

    final nameColor =
        isSelected
            ? AppColors.sunAccent(context)
            : AppColors.textPrimary(context).withAlpha(180);
    final monthColor =
        isSelected
            ? AppColors.sunAccent(context).withAlpha(160)
            : AppColors.textPrimary(context).withAlpha(90);

    final nameTP = TextPainter(
      text: TextSpan(
        text: name,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: nameColor,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final monthTP = TextPainter(
      text: TextSpan(
        text: months,
        style: GoogleFonts.inter(
          fontSize: 7,
          fontWeight: FontWeight.w400,
          color: monthColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position: extend outward from petal tip
    final isRight = cos(angle) >= 0;
    final nameX = isRight ? endPoint.dx + 3 : endPoint.dx - nameTP.width - 3;
    final monthX = isRight ? endPoint.dx + 3 : endPoint.dx - monthTP.width - 3;
    final nameY = endPoint.dy - nameTP.height;
    final monthY = nameY + nameTP.height + 1;

    nameTP.paint(canvas, Offset(nameX, nameY));
    monthTP.paint(canvas, Offset(monthX, monthY));
  }

  @override
  bool shouldRepaint(_SeasonalRosePainter old) =>
      old.summerScale != summerScale ||
      old.monsoonScale != monsoonScale ||
      old.winterScale != winterScale ||
      old.springScale != springScale ||
      old.selectedSeason != selectedSeason ||
      old.interactiveScale != interactiveScale;
}
