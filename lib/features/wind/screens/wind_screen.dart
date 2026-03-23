import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/wind_provider.dart';
import '../../sun/providers/sun_provider.dart';
import '../widgets/wind_vane_hero.dart';
import '../widgets/seasonal_rose.dart';
import '../widgets/wind_flow_background.dart';

import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_local_time.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/heading_provider.dart';

class WindScreen extends ConsumerWidget {
  const WindScreen({super.key});

  static String _cardinal(double degrees) {
    const dirs = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
      'N',
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
      loading:
          () =>
              Center(child: LoadingRadar(color: AppColors.windAccent(context))),
      error: (error, _) => _buildError(context, error, ref),
      data: (baseForecast) {
        final cardinal = _cardinal(baseForecast.primaryDirection);

        // Convert m/s -> km/h (multiply by 3.6)
        final speedKmh = baseForecast.currentSpeed * 3.6;
        final gustKmh = baseForecast.gustSpeed * 3.6;

        final gustStr = '${gustKmh.toStringAsFixed(1)} km/h';
        final humidityStr = '${baseForecast.humidity.round()}%';

        return Scaffold(
          backgroundColor: const Color.fromARGB(
            255,
            53,
            114,
            168,
          ), // Base blue to fill the edges
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Stack(
            children: [
              // ── AMBIENT GRADIENT WASH ─────────────────────────────────────
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 30, 80, 130), // Deep blue at top
                        Color.fromARGB(255, 65, 125, 180), // Mid rich blue
                        Color.fromARGB(255, 54, 111, 164), // Atmospheric base
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // ── WIND PARTICLE STROKES ─────────────────────────────────────
              Positioned.fill(
                child: WindFlowBackground(
                  windDirectionDegrees:
                      baseForecast
                          .primaryDirection, // <-- Matches the Hero exactly!
                  windSpeedMps: baseForecast.currentSpeed,
                  heading: heading,
                ),
              ),

              // ── SCROLL CONTENT ────────────────────────────────────────────
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── HERO (55% screen height for larger Vane) ───────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: Stack(
                        children: [
                          // Wind vane sculpture fills the hero and scaled up
                          Positioned.fill(
                            child: Transform.scale(
                              scale:
                                  1.15, // Original scale
                              child: WindVaneHero(
                                windDirectionDegrees:
                                    baseForecast.primaryDirection,
                                windSpeedMps: baseForecast.currentSpeed,
                                heading: heading,
                              ),
                            ),
                          ),
                          // Cardinal direction word — large Fraunces, bottom-left
                          Positioned(
                            left: 24,
                            bottom: 20,
                            right: 24, // Let it span to constraint inner items
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Cardinal Direction
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder:
                                      (child, anim) => FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: Text(
                                    cardinal,
                                    key: ValueKey(cardinal),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displayLarge?.copyWith(
                                      color: Colors.white,
                                      height: 0.8, // visually align better with sub elements
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Temperature Pill
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
                                      ),
                                      child: Text(
                                        '${baseForecast.temperature.round()}°',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── GLASS DATA CARD (speed + rows) ────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Primary speed row
                                _PrimaryCapsule(
                                  label: 'WIND SPEED',
                                  value: '${speedKmh.toStringAsFixed(1)} km/h',
                                ),
                                // Hairline separator
                                Container(height: 0.5, color: Colors.white.withAlpha(20)),
                                // Data rows
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    children: [
                                      _DataRow(
                                        label: 'LOCAL TIME',
                                        valueWidget: LiveLocalTime(
                                          longitude: location?.longitude ?? 0.0,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      _DataRow(label: 'WIND GUST', value: gustStr),
                                      _DataRow(label: 'DIRECTION', value: 'FROM $cardinal'),
                                      _DataRow(label: 'HUMIDITY', value: humidityStr, isLast: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── SCROLL HINT ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        '↓  SEASONAL PATTERN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: Colors.white.withAlpha(200),
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
                        loading:
                            () => SizedBox(
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

                  // ── BOTTOM SPACER (for nav bar clearance) ────────────────
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // ── TOP RIGHT COMPASS ─────────────────────────────────────────
              Positioned(
                top:
                    MediaQuery.of(context).padding.top +
                    100, // Moved down below the LocationBar significantly
                right: 20,
                child: _TinyCompass(heading: heading),
              ),
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
              Icons.cloud_off_rounded,
              color: AppColors.windAccent(context),
              size: 40,
            ),
            const SizedBox(height: 16),
              Text(
                'Unable to Load Wind Data',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
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
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

/// Full-width primary metric row — transparent bg, sits inside glass card.
class _PrimaryCapsule extends StatelessWidget {
  final String label;
  final String value;

  const _PrimaryCapsule({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: Colors.white.withAlpha(160),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// One data row: Inter label (left) + hairline + Space Mono value (right).
class _DataRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isLast;

  const _DataRow({required this.label, this.value, this.valueWidget, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: Colors.white.withAlpha(160),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 0.5,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              const SizedBox(width: 8),
              if (valueWidget != null)
                valueWidget!
              else if (value != null)
                Text(
                  value!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          Container(height: 0.5, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// Tiny live gyro compass indicating North.
class _TinyCompass extends StatelessWidget {
  final double heading;

  const _TinyCompass({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.capsuleDark.withAlpha(200),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -heading * pi / 180.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 6,
                  child: CustomPaint(
                    size: const Size(12, 14),
                    painter: _CompassArrowPainter(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.warmPaper,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(size.width / 2, 0) // top peak
          ..lineTo(0, size.height) // bottom left
          ..lineTo(size.width / 2, size.height - 3) // inner indent
          ..lineTo(size.width, size.height) // bottom right
          ..close();

    canvas.drawPath(path, Paint()..color = Colors.redAccent.shade400);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
