import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/pill_card.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom strip showing Sunrise, Solar Noon, and Sunset times
/// with clear, descriptive labels a first-time user can understand.
class SunInfoStrip extends StatelessWidget {
  final DateTime? sunrise;
  final DateTime solarNoon;
  final DateTime? sunset;

  const SunInfoStrip({
    super.key,
    this.sunrise,
    required this.solarNoon,
    this.sunset,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PillCard(
          icon: Icons.wb_twilight,
          value: sunrise != null ? timeFormat.format(sunrise!) : '--:--',
          color: AppColors.sunAccent(context),
          label: 'SUNRISE',
          description: 'Sun appears on the horizon',
        ),
        PillCard(
          icon: Icons.wb_sunny_rounded,
          value: timeFormat.format(solarNoon),
          color: AppColors.sunAccent(context),
          label: 'SOLAR NOON',
          description: 'Sun at highest point in sky',
        ),
        PillCard(
          icon: Icons.nights_stay_outlined,
          value: sunset != null ? timeFormat.format(sunset!) : '--:--',
          color: AppColors.sunAccent(context).withAlpha(179),
          label: 'SUNSET',
          description: 'Sun dips below the horizon',
        ),
      ],
    );
  }
}
