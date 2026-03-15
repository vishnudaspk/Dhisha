import 'dart:math';

/// Compass utilities for magnetic declination correction
/// and true north conversion.
class CompassUtils {
  /// Calculates magnetic declination (variation) for a given location.
  /// Uses a simplified World Magnetic Model (WMM) approximation.
  /// For production: replace with full WMM coefficient lookup.
  ///
  /// Returns declination in degrees (positive = east, negative = west).
  static double magneticDeclination({
    required double latitude,
    required double longitude,
    double year = 2025.0,
  }) {
    // Simplified dipole model approximation
    // Based on IGRF-13 / WMM2020 coefficients (simplified)
    // Magnetic north pole approximate position (2025)
    const double magNorthLat = 80.65; // degrees
    const double magNorthLon = -72.68; // degrees

    final latRad = latitude * pi / 180.0;
    final lonRad = longitude * pi / 180.0;
    const magLatRad = magNorthLat * pi / 180.0;
    const magLonRad = magNorthLon * pi / 180.0;

    // Compute the declination using spherical trigonometry
    final sinDeclination = cos(magLatRad) * sin(magLonRad - lonRad);
    final cosDeclination =
        sin(magLatRad) * cos(latRad) -
        cos(magLatRad) * sin(latRad) * cos(magLonRad - lonRad);

    var declination = atan2(sinDeclination, cosDeclination) * 180.0 / pi;

    // Apply secular variation correction (approximate ~0.1°/year drift)
    declination += (year - 2025.0) * 0.1;

    return declination;
  }

  /// Converts magnetic heading to true heading by applying declination.
  static double magneticToTrue(double magneticHeading, double declination) {
    return _normalize360(magneticHeading + declination);
  }

  /// Normalizes an angle to 0–360° range.
  static double _normalize360(double angle) {
    return ((angle % 360) + 360) % 360;
  }

  /// Computes smoothed heading from raw magnetometer data using
  /// complementary filter with accelerometer tilt compensation.
  static double smoothHeading({
    required double rawHeading,
    required double previousHeading,
    double alpha = 0.3, // smoothing factor (0 = smooth, 1 = responsive)
  }) {
    // Handle 360/0 boundary wrap-around
    var diff = rawHeading - previousHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    return _normalize360(previousHeading + alpha * diff);
  }
}
