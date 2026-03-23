import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Frosted-glass iOS-squircle bottom navigation pill.
///
/// The outer shell and the sliding inner chip both use the same
/// continuous-curvature squircle clipper (_SquircleClipper).
///
/// Symmetry fix: chip position is computed with LayoutBuilder so the
/// chip is *mathematically* centred in each tab's half regardless of
/// screen width, not guessed with hardcoded Alignment values.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _pillHeight = 60;
  static const double _outerRadius = 30; // Mathematically clamped to height/2
  static const double _chipRadius = 22; // outerRadius(30) - padding(8) = perfectly parallel squircle bounds

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 52,
        right: 52,
        bottom: bottomPad + 18,
      ),
      child: _SquircleClip(
        radius: _outerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: _pillHeight,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(22),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 0.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pillW = constraints.maxWidth;
                final halfW = pillW / 2;

                final padding = 8.0;
                final chipH = _pillHeight - (padding * 2);
                final chipW = halfW - (padding * 1.5); // 8px outer padding, 4px inner center padding 

                final chipTop = padding;
                final chipLeft = currentIndex == 0
                    ? padding
                    : halfW + (padding * 0.5);

                return Stack(
                  children: [
                    // ── Sliding inner squircle chip ───────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: chipLeft,
                      top: chipTop,
                      child: _SquircleClip(
                        radius: _chipRadius,
                        child: Container(
                          width: chipW,
                          height: chipH,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45), // Tweak visibility
                            border: Border.all(
                              color: Colors.white.withAlpha(55),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Tab row — equal halves ────────────────────────────
                    Row(
                      children: [
                        _Tab(
                          label: 'SUN',
                          icon: Icons.wb_sunny_outlined,
                          isActive: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                        // Hairline divider exactly at centre
                        Container(
                          width: 0.5,
                          height: 22,
                          color: Colors.white.withAlpha(28),
                        ),
                        _Tab(
                          label: 'WIND',
                          icon: Icons.air_outlined,
                          isActive: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── iOS continuous-curvature squircle clip ────────────────────────────────────

class _SquircleClip extends StatelessWidget {
  final double radius;
  final Widget child;
  const _SquircleClip({required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(clipper: _SquircleClipper(radius), child: child);
  }
}

class _SquircleClipper extends CustomClipper<Path> {
  final double radius;
  const _SquircleClipper(this.radius);

  @override
  Path getClip(Size s) => _squirclePath(
        Rect.fromLTWH(0, 0, s.width, s.height),
        radius.clamp(0.0, (s.width < s.height ? s.width : s.height) / 2),
      );

  @override
  bool shouldReclip(_SquircleClipper old) => old.radius != radius;
}

/// Continuous-curvature squircle via Bézier curves.
/// The handle length k ≈ 0.5523 reproduces Apple's super-ellipse tangents.
Path _squirclePath(Rect r, double cr) {
  const k = 0.5522848;
  final bx = cr * k;
  final l = r.left;
  final t = r.top;
  final w = r.width;
  final h = r.height;

  return Path()
    ..moveTo(l + cr, t)
    ..lineTo(l + w - cr, t)
    ..cubicTo(l + w - cr + bx, t, l + w, t + cr - bx, l + w, t + cr)
    ..lineTo(l + w, t + h - cr)
    ..cubicTo(l + w, t + h - cr + bx, l + w - cr + bx, t + h, l + w - cr, t + h)
    ..lineTo(l + cr, t + h)
    ..cubicTo(l + cr - bx, t + h, l, t + h - cr + bx, l, t + h - cr)
    ..lineTo(l, t + cr)
    ..cubicTo(l, t + cr - bx, l + cr - bx, t, l + cr, t)
    ..close();
}

// ── Single tab ────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? Colors.white : Colors.white.withAlpha(70);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.55,
          duration: const Duration(milliseconds: 280),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: Icon(icon, size: 14, color: fg),
                ),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 1.5,
                    color: fg,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
