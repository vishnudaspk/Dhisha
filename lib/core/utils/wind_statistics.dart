import 'dart:math';

/// Utilities for wind direction statistics, circular mean,
/// direction clustering, and seasonal aggregation.
class WindStatistics {
  /// Computes circular mean of a list of angles (in degrees).
  /// Returns mean direction in [0, 360) degrees.
  static double circularMean(List<double> angles) {
    if (angles.isEmpty) return 0;

    double sinSum = 0;
    double cosSum = 0;

    for (final angle in angles) {
      final rad = angle * pi / 180.0;
      sinSum += sin(rad);
      cosSum += cos(rad);
    }

    sinSum /= angles.length;
    cosSum /= angles.length;

    final mean = atan2(sinSum, cosSum) * 180.0 / pi;
    return ((mean % 360) + 360) % 360;
  }

  /// Computes circular standard deviation.
  static double circularStdDev(List<double> angles) {
    if (angles.isEmpty) return 0;

    double sinSum = 0;
    double cosSum = 0;

    for (final angle in angles) {
      final rad = angle * pi / 180.0;
      sinSum += sin(rad);
      cosSum += cos(rad);
    }

    sinSum /= angles.length;
    cosSum /= angles.length;

    final r = sqrt(sinSum * sinSum + cosSum * cosSum);
    return sqrt(-2 * log(r.clamp(0.0001, 1.0))) * 180.0 / pi;
  }

  /// Finds primary and secondary wind direction clusters.
  /// Uses 8-sector binning (N, NE, E, SE, S, SW, W, NW) to find
  /// the two most frequent direction clusters.
  static WindDirectionResult findPrimarySecondary(List<double> directions) {
    if (directions.isEmpty) {
      return const WindDirectionResult(
        primary: 0,
        secondary: 0,
        primarySpeed: 0,
        secondarySpeed: 0,
      );
    }

    // Bin into 8 sectors of 45° each
    final bins = List.filled(8, <double>[]);
    for (int i = 0; i < 8; i++) {
      bins[i] = [];
    }

    for (final dir in directions) {
      final sector = (((dir + 22.5) % 360) / 45).floor() % 8;
      bins[sector].add(dir);
    }

    // Find primary sector (most populated)
    int primaryIdx = 0;
    int maxCount = 0;
    for (int i = 0; i < 8; i++) {
      if (bins[i].length > maxCount) {
        maxCount = bins[i].length;
        primaryIdx = i;
      }
    }

    // Find secondary sector (second most populated, excluding primary)
    int secondaryIdx = (primaryIdx + 4) % 8; // default opposite
    int secondMax = 0;
    for (int i = 0; i < 8; i++) {
      if (i != primaryIdx && bins[i].length > secondMax) {
        secondMax = bins[i].length;
        secondaryIdx = i;
      }
    }

    final primaryDir =
        bins[primaryIdx].isNotEmpty
            ? circularMean(bins[primaryIdx])
            : primaryIdx * 45.0;
    final secondaryDir =
        bins[secondaryIdx].isNotEmpty
            ? circularMean(bins[secondaryIdx])
            : secondaryIdx * 45.0;

    return WindDirectionResult(
      primary: primaryDir,
      secondary: secondaryDir,
      primarySpeed: maxCount.toDouble(),
      secondarySpeed: secondMax.toDouble(),
    );
  }

  /// Determines the meteorological season based on month and hemisphere.
  /// Northern hemisphere: Dec-Feb=Winter, Mar-May=Spring, Jun-Aug=Summer, Sep-Nov=Monsoon/Autumn
  /// Southern hemisphere: reversed
  static Season getSeason(int month, {bool isNorthern = true}) {
    final adjusted = isNorthern ? month : ((month + 6 - 1) % 12) + 1;
    if (adjusted >= 12 || adjusted <= 2) return Season.winter;
    if (adjusted >= 3 && adjusted <= 5) return Season.spring;
    if (adjusted >= 6 && adjusted <= 8) return Season.summer;
    return Season.monsoon;
  }

  /// Groups daily wind data into seasonal averages.
  static Map<Season, SeasonalWindData> computeSeasonalAverages({
    required List<DailyWindRecord> records,
    required bool isNorthernHemisphere,
  }) {
    final grouped = <Season, List<DailyWindRecord>>{};
    for (final season in Season.values) {
      grouped[season] = [];
    }

    for (final record in records) {
      final season = getSeason(
        record.date.month,
        isNorthern: isNorthernHemisphere,
      );
      grouped[season]!.add(record);
    }

    final result = <Season, SeasonalWindData>{};
    for (final season in Season.values) {
      final seasonRecords = grouped[season]!;
      if (seasonRecords.isEmpty) {
        result[season] = SeasonalWindData(
          direction: season.index * 90.0,
          speed: 0,
          count: 0,
        );
        continue;
      }

      final directions = seasonRecords.map((r) => r.direction).toList();
      final speeds = seasonRecords.map((r) => r.speed).toList();

      result[season] = SeasonalWindData(
        direction: circularMean(directions),
        speed: speeds.reduce((a, b) => a + b) / speeds.length,
        count: seasonRecords.length,
        gusts:
            speeds.reduce((a, b) => a > b ? a : b) *
            1.5, // Mock gust estimation for visualization since historical data only gives avg speeds
      );
    }

    return result;
  }
}

enum Season { summer, monsoon, winter, spring }

class WindDirectionResult {
  final double primary;
  final double secondary;
  final double primarySpeed;
  final double secondarySpeed;

  const WindDirectionResult({
    required this.primary,
    required this.secondary,
    required this.primarySpeed,
    required this.secondarySpeed,
  });
}

class SeasonalWindData {
  final double direction;
  final double speed;
  final int count;
  final double gusts;

  const SeasonalWindData({
    required this.direction,
    required this.speed,
    required this.count,
    this.gusts = 0.0,
  });
}

class DailyWindRecord {
  final DateTime date;
  final double direction;
  final double speed;

  const DailyWindRecord({
    required this.date,
    required this.direction,
    required this.speed,
  });
}
