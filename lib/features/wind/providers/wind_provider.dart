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
  final location = await ref.watch(locationProvider.future);
  final repo = ref.read(windRepositoryProvider);
  return repo.fetchForecast(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});

/// Provider for seasonal wind data.
final seasonalWindProvider = FutureProvider<Map<Season, SeasonalWindData>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final repo = ref.read(windRepositoryProvider);
  return repo.fetchSeasonalData(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});
