import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/wind_provider.dart';
import '../widgets/wind_compass.dart';
import '../widgets/seasonal_rose.dart';
import '../widgets/wind_speed_bar.dart';
import '../widgets/wind_info_strip.dart';
import '../widgets/wind_flow_background.dart';

import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_compass_ring.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/heading_provider.dart';

class WindScreen extends ConsumerWidget {
  const WindScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseForecastAsync = ref.watch(windForecastProvider);
    final seasonalAsync = ref.watch(seasonalWindProvider);
    final headingAsync = ref.watch(headingProvider);
    final heading = headingAsync.valueOrNull ?? 0.0;

    return baseForecastAsync.when(
      loading:
          () =>
              Center(child: LoadingRadar(color: AppColors.windAccent(context))),
      error: (error, _) => _buildError(context, error, ref),
      data: (baseForecast) {
        // Gradient origin computed from wind direction
        final rad = (baseForecast.primaryDirection - 90) * (pi / 180.0);
        final gradientCenter = Alignment(cos(rad) * 0.8, sin(rad) * 0.8);

        return Stack(
          children: [
            // Full-screen ambient gradient layer
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: gradientCenter,
                    radius: 1.4,
                    colors: [
                      AppColors.windAccent(context).withAlpha(30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Flowing wind strokes (Full Screen)
            Positioned.fill(
              child: WindFlowBackground(
                windDirectionDegrees: baseForecast.currentWindDirection,
                windSpeedMps: baseForecast.currentSpeed,
                heading: heading,
              ),
            ),

            // Scroll content on top
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Live Wind Direction',
                    subtitle:
                        'Rotate your phone to align the compass with True North.\nThe marker shows the dominant wind direction at your site.',
                    color: AppColors.windAccent(context),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WindSpeedBar(speed: baseForecast.currentSpeed),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LiveCompassRing(
                              heading: heading,
                              accentColor: AppColors.windAccent(context),
                              size: 260,
                              child: WindCompass(
                                primaryDirection: baseForecast.primaryDirection,
                                secondaryDirection: baseForecast.secondaryDirection,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'FROM ${_getCardinalDirection(baseForecast.primaryDirection)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: AppColors.textPrimary(
                                  context,
                                ).withAlpha(153),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _SectionHeader(
                    title: 'Seasonal Wind Pattern',
                    subtitle:
                        'Historical wind directions grouped by season.\nPetal length shows relative wind strength for each period.',
                    color: AppColors.windAccent(context),
                  ),
                  const SizedBox(height: 32),

                  seasonalAsync.when(
                    data:
                        (seasonalData) =>
                            Center(child: SeasonalRose(data: seasonalData)),
                    loading:
                        () => SizedBox(
                          height: 220,
                          child: Center(
                            child: LoadingRadar(
                              color: AppColors.windAccent(context),
                              size: 60,
                            ),
                          ),
                        ),
                    error: (_, __) => const SizedBox(height: 220),
                  ),
                  const SizedBox(height: 32),

                  _SectionHeader(
                    title: 'Current Readings',
                    subtitle:
                        "Today's wind and atmospheric measurements at your location.",
                    color: AppColors.windAccent(context),
                  ),
                  const SizedBox(height: 32),

                  WindInfoStrip(
                    currentSpeed: baseForecast.currentSpeed,
                    gustSpeed: baseForecast.gustSpeed,
                    humidity: baseForecast.humidity,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCardinalDirection(double degrees) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N',
    ];
    final index = ((degrees % 360) / 22.5).round();
    return directions[index];
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error(context),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Wind Data',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context).withAlpha(120),
                fontSize: 10,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ref.invalidate(windForecastProvider);
                ref.invalidate(seasonalWindProvider);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.windAccent(context),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: AppColors.windAccent(context),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.windAccent(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        _HelpButton(title: title, explanation: subtitle),
      ],
    );
  }
}

class _HelpButton extends StatelessWidget {
  final String title;
  final String explanation;

  const _HelpButton({required this.title, required this.explanation});

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  explanation,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: AppColors.textPrimary(context).withAlpha(180),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.windAccent(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHelp(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            '?',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context).withAlpha(102),
            ),
          ),
        ),
      ),
    );
  }
}
