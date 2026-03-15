import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wind_repository.dart';
import '../../../core/utils/wind_statistics.dart';
import '../../sun/providers/sun_provider.dart';

/// Provider for WindRepository.
final windRepositoryProvider = Provider<WindRepository>(
  (ref) => WindRepository(),
);

/// Provider for wind forecast data. Auto-refreshes every 10 minutes.
final windForecastProvider = FutureProvider<WindForecastData>((ref) async {
  final locationAsync = ref.watch(locationProvider);

  return locationAsync.when(
    data: (location) async {
      final repo = ref.read(windRepositoryProvider);
      return repo.fetchForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    },
    loading: () => throw Exception('Waiting for location...'),
    error: (e, _) => throw e,
  );
});

/// Provider for seasonal wind data.
final seasonalWindProvider = FutureProvider<Map<Season, SeasonalWindData>>((
  ref,
) async {
  final locationAsync = ref.watch(locationProvider);

  return locationAsync.when(
    data: (location) async {
      final repo = ref.read(windRepositoryProvider);
      return repo.fetchSeasonalData(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    },
    loading: () => throw Exception('Waiting for location...'),
    error: (e, _) => throw e,
  );
});
