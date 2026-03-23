import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import 'shared/widgets/dhisha_logo.dart';
import 'features/sun/providers/sun_provider.dart';
import 'features/wind/providers/wind_provider.dart';
import 'core/theme/app_theme.dart';

import 'features/sun/screens/sun_screen.dart';
import 'features/wind/screens/wind_screen.dart';
import 'shared/widgets/bottom_nav.dart';

class DhishaApp extends ConsumerWidget {
  const DhishaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Dhisha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainShell(),
    );
  }
}

/// Splash screen with animated compass drawing effect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoStrokeAnim;
  late Animation<double> _pointerOpacityAnim;
  late Animation<double> _pointerScaleAnim;
  late Animation<double> _wordmarkFadeAnim;
  late Animation<double> _subtitleFadeAnim;

  @override
  void initState() {
    super.initState();
    // Total duration 1400ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Circle draws 0 to 500ms (0.0 to 0.357)
    _logoStrokeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.357, curve: Curves.easeOut),
      ),
    );

    // Pointer fades/scales in 300ms delay, 250ms duration -> 300-550ms (0.214 to 0.393)
    _pointerOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.214, 0.393, curve: Curves.easeOut),
      ),
    );
    _pointerScaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.214, 0.393, curve: Curves.easeOutBack),
      ),
    );

    // Wordmark fades in 500ms to 900ms (0.357 to 0.643)
    _wordmarkFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.357, 0.643, curve: Curves.easeIn),
      ),
    );

    // Subtitle fades in 600ms to 1000ms (0.429 to 0.714)
    _subtitleFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.429, 0.714, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const MainShell(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final textColor = Theme.of(context).colorScheme.onSurface;
            final accentColor = const Color(0xFFE64D2E); // vermilion

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DhishaLogo(
                  size: 64,
                  foregroundColor: textColor,
                  accentColor: accentColor,
                  progress: _logoStrokeAnim.value,
                  pointerOpacity: _pointerOpacityAnim.value,
                  pointerScale: _pointerScaleAnim.value,
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _wordmarkFadeAnim.value,
                  child: Text(
                    'dhisha',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: textColor,
                      letterSpacing: 8.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: _subtitleFadeAnim.value,
                  child: Text(
                    'precision site tracking',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: textColor.withAlpha(102),
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Main app shell with bottom nav and tab switching.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _locationDialogShown = false;

  final _screens = const [SunScreen(), WindScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLocationDialog();
    });
  }

  void _maybeShowLocationDialog() {
    if (_locationDialogShown) return;
    _locationDialogShown = true;

    final prefs = ref.read(sharedPreferencesProvider);
    final savedLat = prefs.getDouble('manual_lat');
    final savedLon = prefs.getDouble('manual_lon');
    final useGps = prefs.getBool('use_gps') ?? false;

    if (!useGps && savedLat == null && savedLon == null) {
      _showLocationDialog(isFirstTime: true);
    }
  }

  void _showLocationDialog({bool isFirstTime = false}) {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedLat = prefs.getDouble('manual_lat');
    final savedLon = prefs.getDouble('manual_lon');

    final latController = TextEditingController(
      text: savedLat?.toStringAsFixed(6) ?? '',
    );
    final lonController = TextEditingController(
      text: savedLon?.toStringAsFixed(6) ?? '',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: !isFirstTime,
      builder:
          (ctx) => _LocationDialog(
            latController: latController,
            lonController: lonController,
            isFirstTime: isFirstTime,
            savedLat: savedLat,
            savedLon: savedLon,
            isGpsEnabled: ref.read(useGpsProvider),
            onToggleGps: (enabled) {
              prefs.setBool('use_gps', enabled);
              ref.read(useGpsProvider.notifier).state = enabled;
              ref.invalidate(locationProvider);
              ref.invalidate(baseSolarPositionProvider);
              ref.invalidate(windForecastProvider);
              ref.invalidate(seasonalWindProvider);
              Navigator.pop(ctx);
            },
            onApply: (double lat, double lon) {
              // Switching to manual mode
              prefs.setBool('use_gps', false);
              ref.read(useGpsProvider.notifier).state = false;
              prefs.setDouble('manual_lat', lat);
              prefs.setDouble('manual_lon', lon);

              ref.read(manualLocationProvider.notifier).state = Position(
                longitude: lon,
                latitude: lat,
                timestamp: DateTime.now(),
                accuracy: 100,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );

              ref.invalidate(locationProvider);
              ref.invalidate(baseSolarPositionProvider);
              ref.invalidate(windForecastProvider);
              ref.invalidate(seasonalWindProvider);
              Navigator.pop(ctx);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useGps = ref.watch(useGpsProvider);
    final locationAsync = ref.watch(locationProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true, // Let background bleed into bottom nav
        body: Stack(
          children: [
            // ── Screen content (Full Screen Background) ─────────
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: _screens[_currentIndex],
                ),
              ),
            ),
            
            // ── Top Location Bar (Floating on top) ─────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _LocationBar(
                useGps: useGps,
                locationAsync: locationAsync,
                onTap: () => _showLocationDialog(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }
}

// ─── Location Bar (top of screen) ────────────────────────────────────────────

class _LocationBar extends StatelessWidget {
  final bool useGps;
  final AsyncValue<Position> locationAsync;
  final VoidCallback onTap;

  const _LocationBar({
    required this.useGps,
    required this.locationAsync,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final fgSec = Colors.white.withAlpha(180);
    final bg = Colors.white.withAlpha(22);
    const border = Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border.withAlpha(40), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: GPS/Manual label + divider
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      useGps ? 'GPS' : 'MANUAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: fg.withAlpha(51),
                    ),
                  ],
                ),

                // Center: Coordinates in Space Mono
                Expanded(
                  child: locationAsync.when(
                    skipLoadingOnReload: true,
                    skipLoadingOnRefresh: true,
                    data: (pos) => Text(
                      '${pos.latitude.toStringAsFixed(4)}°, ${pos.longitude.toStringAsFixed(4)}°',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Text(
                      'Acquiring...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: fgSec,
                      ),
                    ),
                    error: (e, _) => Text(
                      'Tap to set',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: fgSec,
                      ),
                    ),
                  ),
                ),

              // Right: balance spacer
              // We use an empty SizedBox to balance the "GPS / MANUAL" block
              // so the coordinates stay perfectly centered. Since the left block
              // is dynamic now, we give a rough rough balance size or remove it.
              // We'll keep width 54 for visual balance as it roughly matches the left.
              const SizedBox(width: 54),
            ],
          ),
        ),
      ),
    ),
    );
  }
}



// ─── Location Dialog Widget ──────────────────────────────────────────────────

class _LocationDialog extends StatefulWidget {
  final TextEditingController latController;
  final TextEditingController lonController;
  final bool isFirstTime;
  final double? savedLat;
  final double? savedLon;
  final bool isGpsEnabled;
  final void Function(bool enabled) onToggleGps;
  final void Function(double lat, double lon) onApply;
  final VoidCallback onCancel;

  const _LocationDialog({
    required this.latController,
    required this.lonController,
    required this.isFirstTime,
    required this.savedLat,
    required this.savedLon,
    required this.isGpsEnabled,
    required this.onToggleGps,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  String? _error;

  void _apply() {
    final lat = double.tryParse(widget.latController.text.trim());
    final lon = double.tryParse(widget.lonController.text.trim());

    if (lat == null || lon == null) {
      setState(() => _error = 'Enter valid numeric coordinates');
      return;
    }
    if (lat < -90 || lat > 90) {
      setState(() => _error = 'Latitude must be between -90 and 90');
      return;
    }
    if (lon < -180 || lon > 180) {
      setState(() => _error = 'Longitude must be between -180 and 180');
      return;
    }

    widget.onApply(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: AppColors.sunAccent(context),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.isFirstTime ? 'Set Your Location' : 'Location Settings',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isFirstTime
                ? 'Use live GPS for real-time updates, or enter coordinates manually.'
                : 'Switch between GPS and manual coordinates.',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── GPS toggle ────────────────────────────────────
          GestureDetector(
            onTap: () => widget.onToggleGps(!widget.isGpsEnabled),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    widget.isGpsEnabled
                        ? AppColors.calm.withAlpha(20)
                        : AppColors.background(context).withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      widget.isGpsEnabled
                          ? AppColors.calm.withAlpha(120)
                          : AppColors.border(context),
                  width: widget.isGpsEnabled ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    color:
                        widget.isGpsEnabled
                            ? AppColors.calm
                            : AppColors.textSecondary(context),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Live GPS',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Most accurate — updates as you move',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isGpsEnabled)
                    Icon(Icons.check_circle, color: AppColors.calm, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Divider ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.border(context), height: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.border(context), height: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Manual coordinate fields ──────────────────────
          _CoordField(
            controller: widget.latController,
            label: 'Latitude (Use - for South)',
            hint: 'e.g. 25.2048 or -33.8688',
            icon: Icons.swap_vert,
            suffix: '°',
          ),
          const SizedBox(height: 12),
          _CoordField(
            controller: widget.lonController,
            label: 'Longitude (Use - for West)',
            hint: 'e.g. -74.0060 for New York',
            icon: Icons.swap_horiz,
            suffix: '°',
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: AppColors.error(context), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.savedLat != null && widget.savedLon != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background(context).withAlpha(180),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: AppColors.textSecondary(context),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saved: ${widget.savedLat!.toStringAsFixed(4)}°, '
                      '${widget.savedLon!.toStringAsFixed(4)}°',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.isFirstTime)
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
        TextButton(
          onPressed: _apply,
          child: Text(
            'APPLY MANUAL',
            style: TextStyle(
              color: AppColors.sunAccent(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String suffix;

  const _CoordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(
          icon,
          color: AppColors.textSecondary(context),
          size: 18,
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary(context).withAlpha(100),
          fontSize: 13,
        ),
        suffixStyle: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border(context), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.sunAccent(context),
            width: 1.5,
          ),
        ),
        fillColor: AppColors.background(context).withAlpha(120),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
