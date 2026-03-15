import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/sun_provider.dart';
import '../widgets/sun_hero_circle.dart';
import '../widgets/sun_path_chart.dart';
import '../widgets/sun_info_strip.dart';
import '../../../shared/widgets/loading_radar.dart';
import '../../../shared/widgets/live_local_time.dart';
import '../../../core/theme/app_theme.dart';

class SunScreen extends ConsumerWidget {
  const SunScreen({super.key});

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

            const directions = [
              'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
              'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N',
            ];
            final cardinal = directions[((solar.azimuth % 360) / 22.5).round()];
            final azimuthStr = '${(solar.azimuth % 360).toStringAsFixed(1)}°';
            final altStr = solar.altitude <= 0
                ? '—'
                : '${solar.altitude.toStringAsFixed(1)}°';

            final sunriseStr = baseSolar.sunrise != null ? DateFormat('h:mma').format(baseSolar.sunrise!).toLowerCase() : '—';
            final noonStr = DateFormat('h:mma').format(baseSolar.solarNoon).toLowerCase();
            final sunsetStr = baseSolar.sunset != null ? DateFormat('h:mma').format(baseSolar.sunset!).toLowerCase() : '—';

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── HERO (45% screen height) ──────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Stack(
                      children: [
                        // Big grainy sun circle
                        Positioned.fill(
                          child: SunHeroCircle(altitude: solar.altitude),
                        ),
                        // "Sun" — huge Fraunces word, bottom-left of hero
                        Positioned(
                          left: 24,
                          bottom: 20,
                          child: Text(
                            solar.altitude <= 0 ? 'Night' : 'Sun',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: solar.altitude > 50
                                  ? Colors.white.withAlpha(230)
                                  : AppColors.textPrimary(context),
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
                      label: 'AZIMUTH',
                      value: azimuthStr,
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
                        _DataRow(label: 'SUNRISE',    value: sunriseStr),
                        _DataRow(label: 'ALTITUDE',   value: altStr),
                        _DataRow(label: 'SOLAR NOON', value: noonStr),
                        _DataRow(label: 'SUNSET',     value: sunsetStr),
                        _DataRow(
                          label: 'DIRECTION',
                          value: '$cardinal — $cardinal',
                          accent: AppColors.sunAccent(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── SCROLL HINT ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      '↓  PATH',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: AppColors.textPrimary(context).withAlpha(89),
                      ),
                    ),
                  ),
                ),

                // ── SUN PATH CHART ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            color: AppColors.sunAccent(context),
                            size: 48,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox(height: 200),
                    ),
                  ),
                ),

                // ── KEY TIMES STRIP ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: SunInfoStrip(
                      sunrise: baseSolar.sunrise,
                      solarNoon: baseSolar.solarNoon,
                      sunset: baseSolar.sunset,
                    ),
                  ),
                ),
              ],
            );
          },
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
            Icon(Icons.error_outline, color: AppColors.sunAccent(context), size: 40),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Solar Data',
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
                ref.invalidate(locationProvider);
                ref.invalidate(baseSolarPositionProvider);
              },
              child: Text(
                'RETRY →',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: AppColors.sunAccent(context),
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
              fontWeight: FontWeight.w400,
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
  final Color? accent;

  const _DataRow({required this.label, this.value, this.valueWidget, this.accent});

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
                child: Container(
                  height: 0.5,
                  color: AppColors.hairline,
                ),
              ),
              const SizedBox(width: 8),
              if (valueWidget != null)
                valueWidget!
              else if (value != null)
                Text(
                  value!,
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    color: accent ?? textColor,
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
