import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/sun_provider.dart';
import '../widgets/azimuth_compass.dart';
import '../widgets/sun_path_chart.dart';
import '../widgets/sun_info_strip.dart';
import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_compass_ring.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/heading_provider.dart';

class SunScreen extends ConsumerWidget {
  const SunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseSolarAsync = ref.watch(baseSolarPositionProvider);
    final arcsAsync = ref.watch(sunPathArcsProvider);
    final headingAsync = ref.watch(headingProvider);
    final heading = headingAsync.valueOrNull ?? 0.0;

    return baseSolarAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading:
          () =>
              Center(child: LoadingRadar(color: AppColors.sunAccent(context))),
      error: (error, _) => _buildError(context, error, ref),
      data: (baseSolar) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Sun Position',
                subtitle:
                    'Altitude: how high the sun is above the horizon (0° = horizon, 90° = overhead).\nAzimuth: compass bearing to the sun — rotate your phone to align with True North.',
                color: AppColors.sunAccent(context),
              ),
              const SizedBox(height: 32),

              Consumer(
                builder: (context, ref, child) {
                  final liveSolarAsync = ref.watch(liveSolarPositionProvider);
                  final solar = liveSolarAsync.valueOrNull ?? baseSolar;

                  const directions = [
                    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N',
                  ];
                  final cardinal = directions[((solar.azimuth % 360) / 22.5).round()];

                  final isNight = solar.altitude <= 0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fixed readout block — never rotates
                      Text(
                        '${(solar.azimuth % 360).toStringAsFixed(1)}°',
                        style: GoogleFonts.spaceMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          color: AppColors.sunAccent(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cardinal,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary(context).withAlpha(115),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'ALT  ',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context).withAlpha(90),
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (isNight) ...[
                            Text(
                              '☽',
                              style: GoogleFonts.spaceMono(
                                fontSize: 16,
                                color: const Color(0xFF2E7BFF).withAlpha(153), // Blueprint Blue 60%
                              ),
                            ),
                          ] else ...[
                            Text(
                              '${solar.altitude.toStringAsFixed(1)}°',
                              style: GoogleFonts.spaceMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary(context).withAlpha(180),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Rotating compass below the fixed readout, centered
                      Center(
                        child: LiveCompassRing(
                          heading: heading,
                          accentColor: AppColors.sunAccent(context),
                          size: 240,
                          child: AzimuthCompass(
                            azimuth: solar.azimuth,
                            altitude: solar.altitude,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              _SectionHeader(
                title: 'Daily Sun Path',
                subtitle:
                    "The sun's arc across the sky from sunrise to sunset.\nEach curve represents a different month of the year.",
                color: AppColors.sunAccent(context),
              ),
              const SizedBox(height: 32),

              arcsAsync.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                data:
                    (arcs) => Consumer(
                      builder: (context, ref, child) {
                        final liveSolarAsync = ref.watch(
                          liveSolarPositionProvider,
                        );
                        final solar = liveSolarAsync.valueOrNull ?? baseSolar;
                        return SunPathChart(arcs: arcs, currentPosition: solar);
                      },
                    ),
                loading:
                    () => SizedBox(
                      height: 220,
                      child: Center(
                        child: LoadingRadar(
                          color: AppColors.sunAccent(context),
                          size: 60,
                        ),
                      ),
                    ),
                error: (_, __) => const SizedBox(height: 220),
              ),
              const SizedBox(height: 32),

              _SectionHeader(
                title: 'Key Times Today',
                subtitle: 'Important sun events for your location today.',
                color: AppColors.sunAccent(context),
              ),
              const SizedBox(height: 32),

              SunInfoStrip(
                sunrise: baseSolar.sunrise,
                solarNoon: baseSolar.solarNoon,
                sunset: baseSolar.sunset,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error(context),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Solar Data',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your location is set correctly.\nSun calculations use your latitude and longitude.',
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
                ref.invalidate(locationProvider);
                ref.invalidate(baseSolarPositionProvider);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.sunAccent(context),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: AppColors.sunAccent(context),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.sunAccent(context),
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
      builder: (context) {
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
                    onTap: () => Navigator.of(context).pop(),
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
                          color: AppColors.sunAccent(context),
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

