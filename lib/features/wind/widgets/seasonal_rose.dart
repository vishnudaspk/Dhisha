import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/wind_statistics.dart';

/// Full-width seasonal wind table.
///
/// Each season is one row:
///   [SEASON LABEL] ─── [Animated bar] ─ [direction arrow] ─ [figure m/s]
///
/// Tapping a row expands a detail chip inline showing Gusts + Direction.
class SeasonalRose extends StatefulWidget {
  final Map<Season, SeasonalWindData> data;

  const SeasonalRose({super.key, required this.data});

  @override
  State<SeasonalRose> createState() => _SeasonalRoseState();
}

class _SeasonalRoseState extends State<SeasonalRose>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  Season? _selectedSeason;

  // SpringController for the selected row pop
  AnimationController? _springController;
  double _springScale = 1.0;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
    );

    _springController = AnimationController.unbounded(vsync: this);
    _springController!.addListener(() {
      setState(() => _springScale = _springController!.value);
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _springController?.dispose();
    super.dispose();
  }

  void _selectSeason(Season season) {
    setState(() {
      if (_selectedSeason == season) {
        _selectedSeason = null;
        _springScale = 1.0;
      } else {
        _selectedSeason = season;
        _springController?.value = 1.05;
        final spring = SpringDescription(mass: 1, stiffness: 280, damping: 18);
        final sim = SpringSimulation(spring, 1.05, 1.0, 0);
        _springController?.animateWith(sim);
      }
    });
  }

  static const _seasonMeta = {
    Season.summer:  _SeasonMeta('SUMMER',  'Jun–Aug', Color(0xFFFFC857)),
    Season.monsoon: _SeasonMeta('MONSOON', 'Jul–Sep', Color(0xFF80C4E9)),
    Season.winter:  _SeasonMeta('WINTER',  'Dec–Feb', Color(0xFFB4C8E1)),
    Season.spring:  _SeasonMeta('SPRING',  'Mar–May', Color(0xFF7FE0A2)),
  };

  String _cardinalDir(double deg) {
    const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
                   'S','SSW','SW','WSW','W','WNW','NW','NNW'];
    return dirs[((deg % 360) / 22.5).round() % 16];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final maxSpeed = widget.data.values
        .map((d) => d.speed)
        .fold<double>(1.0, (a, b) => a > b ? a : b);

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _springController!]),
      builder: (context, _) {
        return Column(
          children: Season.values.map((season) {
            final d = widget.data[season];
            if (d == null) return const SizedBox.shrink();

            final meta = _seasonMeta[season]!;
            final frac = (d.speed / maxSpeed).clamp(0.1, 1.0);
            final selected = _selectedSeason == season;
            final barScale = selected ? _springScale : 1.0;
            final speedKmh = d.speed * 3.6;
            final gustKmh  = d.gusts * 3.6;
            final cardinal = _cardinalDir(d.direction);

            return GestureDetector(
              onTap: () => _selectSeason(season),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withAlpha(14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? meta.accent.withAlpha(80)
                        : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Main row ───────────────────────────────────────────
                    Row(
                      children: [
                        // Season label + months
                        SizedBox(
                          width: 68,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta.label,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: meta.accent,
                                ),
                              ),
                              Text(
                                meta.months,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Colors.white.withAlpha(80),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated bar
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              final barWidth = constraints.maxWidth *
                                  frac *
                                  _entryAnim.value *
                                  barScale;
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Track
                                  Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(15),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  // Fill
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: barWidth.clamp(0.0, constraints.maxWidth),
                                    height: selected ? 4 : 2,
                                    decoration: BoxDecoration(
                                      color: meta.accent.withAlpha(
                                          selected ? 220 : 140),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Direction arrow
                        Transform.rotate(
                          angle: (d.direction) * pi / 180,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 12,
                            color: Colors.white.withAlpha(selected ? 220 : 100),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Speed value
                        Text(
                          '${speedKmh.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withAlpha(selected ? 230 : 160),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' km/h',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.white.withAlpha(80),
                          ),
                        ),
                      ],
                    ),

                    // ── Expandable detail row ───────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 230),
                      curve: Curves.easeOut,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const SizedBox(width: 68), // align with bar
                                  _DetailChip(
                                    label: 'GUSTS',
                                    value: '${gustKmh.toStringAsFixed(1)} km/h',
                                    accent: meta.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  _DetailChip(
                                    label: 'DIR',
                                    value: cardinal,
                                    accent: meta.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  _DetailChip(
                                    label: 'DAYS',
                                    value: '${d.count}',
                                    accent: meta.accent,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Detail chip ────────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withAlpha(60), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: accent.withAlpha(160),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal meta ─────────────────────────────────────────────────────────────

class _SeasonMeta {
  final String label;
  final String months;
  final Color accent;

  const _SeasonMeta(this.label, this.months, this.accent);
}
