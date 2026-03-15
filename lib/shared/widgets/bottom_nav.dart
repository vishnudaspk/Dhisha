import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Editorial bottom navigation — no icon, no border, no fill.
/// Active tab: Space Mono label, full opacity + a 2dp accent underline.
/// Inactive tab: 35% opacity, no underline.
/// The underline slides between tabs (300ms easeInOut).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sunActive  = currentIndex == 0;
    final windActive = currentIndex == 1;

    return Container(
      height: 56 + MediaQuery.of(context).padding.bottom,
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NavTab(
            label: 'SUN',
            isActive: sunActive,
            accentColor: AppColors.sunRed,
            allTextColor: AppColors.textPrimary(context),
            onTap: () => onTap(0),
          ),
          _NavTab(
            label: 'WIND',
            isActive: windActive,
            accentColor: AppColors.windBlue,
            allTextColor: AppColors.textPrimary(context),
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color accentColor;
  final Color allTextColor;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.allTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.6,
                color: isActive
                    ? allTextColor
                    : allTextColor.withAlpha(89), // 35%
              ),
              child: Text(label),
            ),
            const SizedBox(height: 4),
            // Accent underline — slides in/out via AnimatedContainer width
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isActive ? 24 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
