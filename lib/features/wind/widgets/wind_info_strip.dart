import 'package:flutter/material.dart';
import '../../../shared/widgets/pill_card.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom strip showing Current Speed, Gust Speed, and Humidity
/// with clear, descriptive labels a first-time user can understand.
class WindInfoStrip extends StatelessWidget {
  final double currentSpeed;
  final double gustSpeed;
  final double humidity;

  const WindInfoStrip({
    super.key,
    required this.currentSpeed,
    required this.gustSpeed,
    required this.humidity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PillCard(
          icon: Icons.air,
          value: '${currentSpeed.toStringAsFixed(1)} km/h',
          color: AppColors.windAccent(context),
          label: 'WIND SPEED',
          description: 'Current ground-level wind speed',
        ),
        PillCard(
          icon: Icons.storm,
          value: '${gustSpeed.toStringAsFixed(1)} km/h',
          color: AppColors.windAccent(context),
          label: 'PEAK GUST',
          description: "Today's strongest wind burst",
        ),
        PillCard(
          icon: Icons.water_drop_outlined,
          value: '${humidity.toStringAsFixed(0)}%',
          color: AppColors.windAccent(context).withAlpha(179),
          label: 'HUMIDITY',
          description: 'Moisture level in the air',
        ),
      ],
    );
  }
}
