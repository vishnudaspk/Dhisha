import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/wind_statistics.dart';

/// Repository for fetching wind data from Open-Meteo API.
class WindRepository {
  /// Fetches current day's hourly wind data and computes primary/secondary directions.
  Future<WindForecastData> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final url = ApiConstants.forecastUrl(latitude, longitude);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch wind forecast: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final hourly = data['hourly'] as Map<String, dynamic>;

    // Use only past/current hours (up to the current UTC hour) to avoid
    // using future-forecast hours as the "current" wind direction.
    final times = (hourly['time'] as List).cast<String>();
    final nowUtc = DateTime.now().toUtc();
    int currentHourIndex = 0;
    for (int i = 0; i < times.length; i++) {
      final t = DateTime.parse(times[i]);
      if (t.isAfter(nowUtc)) break;
      currentHourIndex = i;
    }

    final windDirsList = (hourly['wind_direction_10m'] as List)
        .map<double?>((e) => e != null ? (e as num).toDouble() : null)
        .toList();

    // Current hour's actual wind direction (not an aggregate)
    final currentWindDir = windDirsList.isNotEmpty
        ? (windDirsList[currentHourIndex] ?? 0.0)
        : 0.0;

    // Past-hours-only list for statistical computations
    final windDirs = windDirsList
        .sublist(0, currentHourIndex + 1)
        .where((e) => e != null)
        .map<double>((e) => e!)
        .toList();

    final windSpeedsList = (hourly['wind_speed_10m'] as List)
        .map<double?>((e) => e != null ? (e as num).toDouble() : null)
        .toList();

    // Current speed is from the current hour; all past speeds for gust calc
    final currentSpeed = windSpeedsList.isNotEmpty
        ? (windSpeedsList[currentHourIndex] ?? 0.0)
        : 0.0;
    final pastSpeeds = windSpeedsList
        .sublist(0, currentHourIndex + 1)
        .where((e) => e != null)
        .map<double>((e) => e!)
        .toList();
    final gustSpeed = pastSpeeds.isNotEmpty
        ? pastSpeeds.reduce((a, b) => a > b ? a : b)
        : currentSpeed;

    final humidity =
        (hourly['relative_humidity_2m'] as List?)
            ?.map<double?>((e) => e != null ? (e as num).toDouble() : null)
            .toList();
    final currentHumidity = (humidity != null && humidity.length > currentHourIndex)
        ? (humidity[currentHourIndex] ?? 0.0)
        : 0.0;

    // Compute statistical primary/secondary directions from past data only
    final dirResult = WindStatistics.findPrimarySecondary(
      windDirs.isNotEmpty ? windDirs : [currentWindDir],
    );

    return WindForecastData(
      primaryDirection: dirResult.primary,
      secondaryDirection: dirResult.secondary,
      // Live, current-hour actual wind direction for the flow animation
      currentWindDirection: currentWindDir,
      currentSpeed: currentSpeed,
      gustSpeed: gustSpeed,
      humidity: currentHumidity,
      meanDirection: WindStatistics.circularMean(
        windDirs.isNotEmpty ? windDirs : [currentWindDir],
      ),
    );
  }

  /// Fetches historical 3-month archive data for seasonal wind rose.
  Future<Map<Season, SeasonalWindData>> fetchSeasonalData({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 3, now.day);
    final endDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final startDateStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    final url = ApiConstants.archiveUrl(
      latitude,
      longitude,
      startDateStr,
      endDateStr,
    );

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        // Return default seasonal data if archive fails
        return _defaultSeasonalData();
      }

      final data = json.decode(response.body);
      final daily = data['daily'] as Map<String, dynamic>?;

      if (daily == null) return _defaultSeasonalData();

      final times = (daily['time'] as List).cast<String>();
      final directions =
          (daily['winddirection_10m_dominant'] as List?)
              ?.map<double?>((e) => e != null ? (e as num).toDouble() : null)
              .toList();
      final speeds =
          (daily['windspeed_10m_max'] as List?)
              ?.map<double?>((e) => e != null ? (e as num).toDouble() : null)
              .toList();

      if (directions == null || speeds == null) return _defaultSeasonalData();

      final records = <DailyWindRecord>[];
      for (int i = 0; i < times.length; i++) {
        if (i < directions.length &&
            i < speeds.length &&
            directions[i] != null &&
            speeds[i] != null) {
          records.add(
            DailyWindRecord(
              date: DateTime.parse(times[i]),
              direction: directions[i]!,
              speed: speeds[i]!,
            ),
          );
        }
      }

      final isNorthern = latitude >= 0;
      return WindStatistics.computeSeasonalAverages(
        records: records,
        isNorthernHemisphere: isNorthern,
      );
    } catch (_) {
      return _defaultSeasonalData();
    }
  }

  Map<Season, SeasonalWindData> _defaultSeasonalData() {
    return {
      Season.summer: const SeasonalWindData(direction: 225, speed: 3, count: 0),
      Season.monsoon: const SeasonalWindData(
        direction: 180,
        speed: 5,
        count: 0,
      ),
      Season.winter: const SeasonalWindData(direction: 315, speed: 4, count: 0),
      Season.spring: const SeasonalWindData(direction: 45, speed: 3, count: 0),
    };
  }
}

/// Parsed wind forecast data.
class WindForecastData {
  final double primaryDirection;
  final double secondaryDirection;
  /// The actual wind direction at the current hour (FROM direction, 0–360°).
  /// This is the raw meteorological reading, not a statistical aggregate.
  /// Use this for the live wind flow animation.
  final double currentWindDirection;
  final double currentSpeed; // m/s
  final double gustSpeed;    // m/s – peak of past hours today
  final double humidity;
  final double meanDirection;

  const WindForecastData({
    required this.primaryDirection,
    required this.secondaryDirection,
    required this.currentWindDirection,
    required this.currentSpeed,
    required this.gustSpeed,
    required this.humidity,
    required this.meanDirection,
  });
}
