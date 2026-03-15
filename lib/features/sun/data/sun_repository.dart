import '../../../core/utils/solar_calculator.dart';

/// Repository for computing solar position data from GPS coordinates.
class SunRepository {
  /// Gets current solar position.
  SolarPosition getCurrentPosition({
    required double latitude,
    required double longitude,
  }) {
    return SolarCalculator.calculate(
      latitude: latitude,
      longitude: longitude,
      dateTime: DateTime.now(),
    );
  }

  /// Generates monthly sun path arcs for the chart.
  List<MonthlyArc> getMonthlyArcs({
    required double latitude,
    required double longitude,
  }) {
    return SolarCalculator.generateMonthlyArcs(
      latitude: latitude,
      longitude: longitude,
      now: DateTime.now(),
      pastMonths: 6,
      futureMonths: 1,
    );
  }

  /// Gets sun position for a specific date and time.
  SolarPosition getPositionAt({
    required double latitude,
    required double longitude,
    required DateTime dateTime,
  }) {
    return SolarCalculator.calculate(
      latitude: latitude,
      longitude: longitude,
      dateTime: dateTime,
    );
  }
}
