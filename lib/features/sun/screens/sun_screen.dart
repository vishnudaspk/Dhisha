import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/sun_provider.dart';
import '../widgets/sun_hero_circle.dart';
import '../widgets/sun_path_chart.dart';

import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_local_time.dart';
import '../../../core/theme/app_theme.dart';

class SunScreen extends ConsumerWidget {
  const SunScreen({super.key});

  // ── Sky palette by altitude ──────────────────────────────────────────────
  // Night   : deep indigo-black
  // Twilight: purple-amber gradient
  // Dawn/Dusk: warm amber-orange
  // Day     : bright sky blue → white
  static List<Color> _skyGradient(double altitude) {
    if (altitude <= -6) {
      // Deep night
      return [const Color(0xFF0A0E1A), const Color(0xFF111827)];
    } else if (altitude <= 0) {
      // Civil twilight — deep purple blending into dark indigo
      final t = (altitude + 6) / 6; // 0..1
      return [
        Color.lerp(const Color(0xFF0A0E1A), const Color(0xFF2D1B4E), t)!,
        Color.lerp(const Color(0xFF111827), const Color(0xFF4A2040), t)!,
      ];
    } else if (altitude <= 8) {
      // Golden hour / sunrise / sunset
      final t = altitude / 8;
      return [
        Color.lerp(const Color(0xFF2D1B4E), const Color(0xFF1A2A6C), t)!,
        Color.lerp(const Color(0xFFB31217), const Color(0xFFE8621A), t)!,
      ];
    } else if (altitude <= 30) {
      // Morning / afternoon
      final t = (altitude - 8) / 22;
      return [
        Color.lerp(const Color(0xFF1A2A6C), const Color(0xFF1565C0), t)!,
        Color.lerp(const Color(0xFFE8621A), const Color(0xFF42A5F5), t)!,
      ];
    } else {
      // Midday bright sky
      final t = ((altitude - 30) / 60).clamp(0.0, 1.0);
      return [
        Color.lerp(const Color(0xFF1565C0), const Color(0xFF0D47A1), t)!,
        Color.lerp(const Color(0xFF42A5F5), const Color(0xFF90CAF9), t)!,
      ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseSolarAsync = ref.watch(baseSolarPositionProvider);
    final arcsAsync = ref.watch(sunPathArcsProvider);

    return baseSolarAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Center(child: LoadingRadar(color: AppColors.sunAccent(context))),
      error: (error, _) => _buildError(context, error, ref),
      data: (baseSolar) {
        return Consumer(
          builder: (context, ref, _) {
            final liveSolarAsync = ref.watch(liveSolarPositionProvider);
            final solar = liveSolarAsync.valueOrNull ?? baseSolar;
            final location = ref.watch(locationProvider).valueOrNull;
            final isNight = solar.altitude <= 0;

            const directions = [
              'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
              'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N',
            ];
            final cardinal = directions[((solar.azimuth % 360) / 22.5).round()];
            final azimuthStr = '${(solar.azimuth % 360).toStringAsFixed(1)}°';
            final altStr = solar.altitude <= 0
                ? '—'
                : '${solar.altitude.toStringAsFixed(1)}°';

            final sunriseStr = baseSolar.sunrise != null
                ? DateFormat('h:mma').format(baseSolar.sunrise!).toLowerCase()
                : '—';
            final noonStr = DateFormat('h:mma').format(baseSolar.solarNoon).toLowerCase();
            final sunsetStr = baseSolar.sunset != null
                ? DateFormat('h:mma').format(baseSolar.sunset!).toLowerCase()
                : '—';

            final skyColors = _skyGradient(solar.altitude);

            return Scaffold(
              backgroundColor: skyColors[0],
              extendBodyBehindAppBar: true,
              extendBody: true,
              body: Stack(
                children: [
                  // ── Dynamic sky gradient background ────────────────────
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: skyColors,
                        ),
                      ),
                    ),
                  ),

                  // ── Scroll content ─────────────────────────────────────
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── HERO (55% screen height) ─────────────────────
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: Stack(
                            children: [
                              // Sun / crescent moon widget
                              Positioned.fill(
                                child: SunHeroCircle(altitude: solar.altitude),
                              ),

                              // Hero word bottom-left
                              Positioned(
                                left: 24,
                                bottom: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: Text(
                                        isNight ? 'Night' : 'Sun',
                                        key: ValueKey(isNight),
                                        style: GoogleFonts.inter(
                                          fontSize: 72,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white.withAlpha(220),
                                          height: 0.9,
                                          letterSpacing: -2.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isNight
                                          ? 'Below horizon'
                                          : 'Altitude $altStr',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withAlpha(150),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Azimuth badge top-right
                              Positioned(
                                right: 24,
                                bottom: 28,
                                child: _GlassBadge(
                                  label: 'AZIMUTH',
                                  value: azimuthStr,
                                  isNight: isNight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── DATA CARDS ──────────────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _GlassCard(
                            isNight: isNight,
                            children: [
                              _GlassRow(
                                label: 'LOCAL TIME',
                                isNight: isNight,
                                valueWidget: LiveLocalTime(
                                  longitude: location?.longitude ?? 0.0,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              _GlassRow(
                                label: 'SUNRISE',
                                value: sunriseStr,
                                isNight: isNight,
                                accent: isNight ? null : const Color(0xFFFFC857),
                              ),
                              _GlassRow(
                                label: 'SOLAR NOON',
                                value: noonStr,
                                isNight: isNight,
                              ),
                              _GlassRow(
                                label: 'SUNSET',
                                value: sunsetStr,
                                isNight: isNight,
                                accent: isNight ? null : const Color(0xFFFF7043),
                              ),
                              _GlassRow(
                                label: 'DIRECTION',
                                value: cardinal,
                                isNight: isNight,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ),


                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: arcsAsync.when(
                            skipLoadingOnReload: true,
                            skipLoadingOnRefresh: true,
                            data: (arcs) => SunPathChart(
                              arcs: arcs,
                              currentPosition: solar,
                            ),
                            loading: () => SizedBox(
                              height: 200,
                              child: Center(
                                child: LoadingRadar(
                                  color: isNight
                                      ? const Color(0xFF8FA8C8)
                                      : const Color(0xFFFFC857),
                                  size: 48,
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox(height: 200),
                          ),
                        ),
                      ),

                      // Bottom spacer for floating nav
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFFC857), size: 40),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Solar Data',
                style: GoogleFonts.inter(
                  color: Colors.white,
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
                  color: Colors.white.withAlpha(120),
                  fontSize: 11,
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
                child: Text(
                  'RETRY →',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: const Color(0xFFFFC857),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glassmorphic card container ───────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final bool isNight;
  final List<Widget> children;

  const _GlassCard({required this.isNight, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isNight ? 14 : 22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(30),
              width: 0.5,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// ── Single glassy data row ───────────────────────────────────────────────────

class _GlassRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? accent;
  final bool isNight;
  final bool isLast;

  const _GlassRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.accent,
    required this.isNight,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ?? Colors.white;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: Colors.white.withAlpha(90),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
                const SizedBox(width: 8),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value ?? '—',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Container(height: 0.5, color: Colors.white.withAlpha(12)),
      ],
    );
  }
}

// ── Azimuth badge ─────────────────────────────────────────────────────────────

class _GlassBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isNight;

  const _GlassBadge({
    required this.label,
    required this.value,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isNight ? 16 : 24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(35), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white.withAlpha(100),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
