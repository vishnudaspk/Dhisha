import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sun_repository.dart';
import '../../../core/utils/solar_calculator.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

/// Whether to use live GPS instead of manual coordinates.
final useGpsProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('use_gps') ?? false;
});

/// Provider for manual location override.
final manualLocationProvider = StateProvider<Position?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final lat = prefs.getDouble('manual_lat');
  final lon = prefs.getDouble('manual_lon');

  if (lat != null && lon != null) {
    return Position(
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
  }
  return null;
});

/// Snaps a coordinate to a 250 m geographic grid so the app does not
/// refetch API data for every micro-movement.
/// 250 m ≈ 0.00225° of latitude (constant). Longitude degrees per 250 m
/// are smaller at higher latitudes: ΔLon = 0.00225° / cos(lat_rad).
Position _snapTo250mTile(Position pos) {
  const tileMetres = 250.0;
  // 1° latitude ≈ 111 320 m (mean Earth radius)
  const degPerMetre = 1.0 / 111320.0;
  final latStep = tileMetres * degPerMetre;
  // Longitude degrees shrink with cos(latitude)
  final cosLat = cos(pos.latitude * pi / 180.0);
  final lonStep = cosLat > 1e-6 ? latStep / cosLat : latStep;

  final snappedLat = (pos.latitude / latStep).round() * latStep;
  final snappedLon = (pos.longitude / lonStep).round() * lonStep;

  return Position(
    latitude: snappedLat,
    longitude: snappedLon,
    timestamp: pos.timestamp,
    accuracy: pos.accuracy,
    altitude: pos.altitude,
    heading: pos.heading,
    speed: pos.speed,
    speedAccuracy: pos.speedAccuracy,
    altitudeAccuracy: pos.altitudeAccuracy,
    headingAccuracy: pos.headingAccuracy,
  );
}

/// Provider for live GPS position that updates every 5 seconds,
/// snapped to a 250 m geographic tile to limit API churn.
final liveGpsProvider = StreamProvider<Position>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled. Please enable GPS.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Location permission permanently denied. '
      'Please enable it in device settings.',
    );
  }

  // Get initial high-accuracy position and snap to 250 m tile
  final initial = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
  );
  Position lastTile = _snapTo250mTile(initial);
  yield lastTile;

  // Stream updates – only yield when the tile changes (avoids redundant fetches)
  await for (final pos in Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 50, // only callback at all after 50 m movement
    ),
  )) {
    final tile = _snapTo250mTile(pos);
    // Only propagate when we cross into a new 250 m tile
    if (tile.latitude != lastTile.latitude ||
        tile.longitude != lastTile.longitude) {
      lastTile = tile;
      yield tile;
    }
  }
});

/// Unified location provider: uses live GPS if enabled, else manual coords.
final locationProvider = FutureProvider<Position>((ref) async {
  final useGps = ref.watch(useGpsProvider);

  if (useGps) {
    return await ref.watch(liveGpsProvider.future);
  }

  // Manual mode
  final manualLocation = ref.watch(manualLocationProvider);
  if (manualLocation != null) {
    return manualLocation;
  }

  // Fallback: try device GPS once
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception(
      'No location set. Tap the location button to enter coordinates '
      'or enable GPS.',
    );
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions permanently denied.');
  }

  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
  );
});

/// Provider for SunRepository.
final sunRepositoryProvider = Provider<SunRepository>((ref) => SunRepository());

/// Provider for base current solar position. Loads once and does not tick.
final baseSolarPositionProvider = FutureProvider<SolarPosition>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final repo = ref.read(sunRepositoryProvider);
  return repo.getCurrentPosition(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});

/// Provider for live solar position. Auto-refreshes every 10 seconds locally.
final liveSolarPositionProvider = StreamProvider<SolarPosition>((ref) async* {
  final baseDataAsync = ref.watch(baseSolarPositionProvider);
  final locationAsync = ref.watch(locationProvider);

  if (!baseDataAsync.hasValue || !locationAsync.hasValue) {
    return;
  }

  final repo = ref.read(sunRepositoryProvider);
  final location = locationAsync.requireValue;

  yield repo.getCurrentPosition(
    latitude: location.latitude,
    longitude: location.longitude,
  );

  yield* Stream.periodic(const Duration(seconds: 10), (_) {
    return repo.getCurrentPosition(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  });
});

/// Provider for monthly sun path arcs.
final sunPathArcsProvider = FutureProvider<List<MonthlyArc>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final repo = ref.read(sunRepositoryProvider);
  return repo.getMonthlyArcs(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});
