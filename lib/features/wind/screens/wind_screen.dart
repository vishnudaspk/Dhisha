import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/wind_provider.dart';
import '../../sun/providers/sun_provider.dart';
import '../widgets/wind_vane_hero.dart';
import '../widgets/seasonal_rose.dart';
import '../widgets/wind_info_strip.dart';
import '../widgets/wind_flow_background.dart';

import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_local_time.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/heading_provider.dart';

class WindScreen extends ConsumerWidget {
  const WindScreen({super.key});

  static String _cardinal(double degrees) {
    const dirs = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N',
    ];
    return dirs[((degrees % 360) / 22.5).round()];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseForecastAsync = ref.watch(windForecastProvider);
    final seasonalAsync = ref.watch(seasonalWindProvider);
    final headingAsync = ref.watch(headingProvider);
    final heading = headingAsync.valueOrNull ?? 0.0;
    final location = ref.watch(locationProvider).valueOrNull;

    return baseForecastAsync.when(
      loading: () => Center(child: LoadingRadar(color: AppColors.windAccent(context))),
      error: (error, _) => _buildError(context, error, ref),
      data: (baseForecast) {
        final cardinal = _cardinal(baseForecast.primaryDirection);

        // Ambient gradient — wind origin direction maps to gradient centre
        final rad = (baseForecast.primaryDirection - 90) * (pi / 180.0);
        final gradientCenter = Alignment(cos(rad) * 0.8, sin(rad) * 0.8);

        final gustStr = '${baseForecast.gustSpeed.toStringAsFixed(1)} m/s';
        final humidityStr = '${baseForecast.humidity.round()}%';

        return Stack(
          children: [
            // ── AMBIENT GRADIENT WASH ─────────────────────────────────────
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: gradientCenter,
                    radius: 1.4,
                    colors: [
                      AppColors.windBlue.withAlpha(22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── WIND PARTICLE STROKES ─────────────────────────────────────
            Positioned.fill(
              child: WindFlowBackground(
                windDirectionDegrees: baseForecast.currentWindDirection,
                windSpeedMps: baseForecast.currentSpeed,
                heading: heading,
              ),
            ),

            // ── SCROLL CONTENT ────────────────────────────────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── HERO (45% screen height) ──────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Stack(
                      children: [
                        // Wind vane sculpture fills the hero
                        Positioned.fill(
                          child: WindVaneHero(
                            windDirectionDegrees: baseForecast.primaryDirection,
                          ),
                        ),
                        // Cardinal direction word — large Fraunces, bottom-left
                        Positioned(
                          left: 24,
                          bottom: 20,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              cardinal,
                              key: ValueKey(cardinal),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppColors.windBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── PRIMARY CAPSULE ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _PrimaryCapsule(
                      label: 'WIND SPEED',
                      value: '${baseForecast.currentSpeed.toStringAsFixed(1)} m/s',
                    ),
                  ),
                ),

                // ── DATA ROWS ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _DataRow(
                          label: 'LOCAL TIME',
                          valueWidget: LiveLocalTime(
                            longitude: location?.longitude ?? 0.0,
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        _DataRow(label: 'WIND GUST',  value: gustStr),
                        _DataRow(label: 'DIRECTION',   value: 'FROM $cardinal'),
                        _DataRow(label: 'HUMIDITY',    value: humidityStr),
                      ],
                    ),
                  ),
                ),

                // ── SCROLL HINT ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      '↓  SEASONAL PATTERN',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: AppColors.textPrimary(context).withAlpha(89),
                      ),
                    ),
                  ),
                ),

                // ── SEASONAL WIND ROSE ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: seasonalAsync.when(
                      data: (data) => Center(child: SeasonalRose(data: data)),
                      loading: () => SizedBox(
                        height: 220,
                        child: Center(
                          child: LoadingRadar(
                            color: AppColors.windAccent(context),
                            size: 48,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox(height: 220),
                    ),
                  ),
                ),

                // ── READINGS STRIP ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: WindInfoStrip(
                      currentSpeed: baseForecast.currentSpeed,
                      gustSpeed: baseForecast.gustSpeed,
                      humidity: baseForecast.humidity,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            Icon(Icons.cloud_off_rounded, color: AppColors.windAccent(context), size: 40),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Wind Data',
              style: GoogleFonts.spaceMono(
                color: AppColors.textPrimary(context),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                color: AppColors.textSecondary(context),
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
              child: Text(
                'RETRY →',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: AppColors.windAccent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Primitives ─────────────────────────────────────────────────────

/// Full-width dark capsule — primary metric. inkBlack bg, warmPaper text.
class _PrimaryCapsule extends StatelessWidget {
  final String label;
  final String value;

  const _PrimaryCapsule({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.capsuleDark;
    const fg = AppColors.warmPaper;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              letterSpacing: 1.8,
              color: fg.withAlpha(140),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// One data row: Space Mono label (left) + hairline + value (right).
class _DataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DataRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: textColor.withAlpha(115),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 0.5, color: AppColors.hairline),
              ),
              const SizedBox(width: 8),
              if (valueWidget != null)
                valueWidget!
              else if (value != null)
                Text(
                  value!,
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.hairline),
      ],
    );
  }
}
