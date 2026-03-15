import 'dart:math';

/// Full Solar Position Calculator based on the NOAA Solar Calculator
/// spreadsheet algorithm (derived from Jean Meeus "Astronomical Algorithms").
///
/// Accuracy: < 0.01° for altitude and azimuth when given correct inputs.
///
/// IMPORTANT: All internal calculations use UTC. The [dateTime] parameter
/// should represent the exact moment in time (any timezone is fine — we
/// convert to UTC internally via [DateTime.toUtc()]).
class SolarCalculator {
  /// Calculates solar position for given location and time.
  static SolarPosition calculate({
    required double latitude,
    required double longitude,
    required DateTime dateTime, // Should be DateTime.now().toUtc() when calling
  }) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final jd = _julianDate(utc);
    final jc = _julianCentury(jd);

    // ── Orbital elements ────────────────────────────────────────────
    // Sun's geometric mean longitude (degrees)
    final l0 = _normalize360(280.46646 + jc * (36000.76983 + 0.0003032 * jc));

    // Sun's mean anomaly (degrees)
    final m = _normalize360(357.52911 + jc * (35999.05029 - 0.0001537 * jc));
    final mRad = _toRad(m);

    // Eccentricity of Earth's orbit
    final e = 0.016708634 - jc * (0.000042037 + 0.0000001267 * jc);

    // Equation of center
    final c =
        sin(mRad) * (1.914602 - jc * (0.004817 + 0.000014 * jc)) +
        sin(2 * mRad) * (0.019993 - 0.000101 * jc) +
        sin(3 * mRad) * 0.000289;

    // Sun's true longitude
    final sunTrueLon = l0 + c;

    // Sun's apparent longitude
    final omega = 125.04 - 1934.136 * jc;
    final lambda = sunTrueLon - 0.00569 - 0.00478 * sin(_toRad(omega));

    // ── Obliquity ───────────────────────────────────────────────────
    final epsilon0 =
        23.0 +
        (26.0 +
                (21.448 - jc * (46.8150 + jc * (0.00059 - jc * 0.001813))) /
                    60.0) /
            60.0;

    // Corrected obliquity
    final epsilon = epsilon0 + 0.00256 * cos(_toRad(omega));
    final epsilonRad = _toRad(epsilon);

    // ── Declination ─────────────────────────────────────────────────
    final declination = _toDeg(asin(sin(epsilonRad) * sin(_toRad(lambda))));

    // ── Equation of Time (minutes) ──────────────────────────────────
    // NOAA method (accurate)
    final y = tan(epsilonRad / 2) * tan(epsilonRad / 2);
    final l0Rad = _toRad(l0);

    final eqTimeMinutes =
        4.0 *
        _toDeg(
          y * sin(2 * l0Rad) -
              2 * e * sin(mRad) +
              4 * e * y * sin(mRad) * cos(2 * l0Rad) -
              0.5 * y * y * sin(4 * l0Rad) -
              1.25 * e * e * sin(2 * mRad),
        );

    // ── Solar noon (minutes from midnight UTC) ──────────────────────
    final solarNoonMinUTC = 720.0 - 4.0 * longitude - eqTimeMinutes;

    // ── Current time in fractional minutes from midnight UTC ─────────
    final timeMinUTC = utc.hour * 60.0 + utc.minute + utc.second / 60.0;

    // ── Hour angle (degrees) ────────────────────────────────────────
    final hourAngle = (timeMinUTC - solarNoonMinUTC) / 4.0;
    final haRad = _toRad(hourAngle);

    final latRad = _toRad(latitude);
    final declRad = _toRad(declination);

    // ── Solar altitude (elevation) ──────────────────────────────────
    final sinAlt =
        sin(latRad) * sin(declRad) + cos(latRad) * cos(declRad) * cos(haRad);
    var altitude = _toDeg(asin(sinAlt.clamp(-1.0, 1.0)));

    // Atmospheric refraction correction (result is in DEGREES)
    altitude += _refractionCorrectionDeg(altitude);

    // ── Solar azimuth (from north, clockwise) ───────────────────────
    var azimuth = _toDeg(
      atan2(sin(haRad), cos(haRad) * sin(latRad) - tan(declRad) * cos(latRad)),
    );
    azimuth = _normalize360(azimuth + 180.0);

    // ── Sunrise / Sunset ────────────────────────────────────────────
    final sunrise = _calcSunEvent(
      latitude: latitude,
      longitude: longitude,
      declination: declination,
      eqTimeMinutes: eqTimeMinutes,
      dateUtc: utc,
      isSunrise: true,
    );

    final sunset = _calcSunEvent(
      latitude: latitude,
      longitude: longitude,
      declination: declination,
      eqTimeMinutes: eqTimeMinutes,
      dateUtc: utc,
      isSunrise: false,
    );

    final solarNoon = _minutesToDateTime(solarNoonMinUTC, utc, longitude);

    return SolarPosition(
      altitude: altitude,
      azimuth: azimuth,
      declination: declination,
      hourAngle: hourAngle,
      sunrise: sunrise,
      sunset: sunset,
      solarNoon: solarNoon,
    );
  }

  /// Calculate sun path arc for a specific date (for chart visualization).
  /// Returns list of [SolarPathPoint] from before sunrise to after sunset.
  static List<SolarPathPoint> calculateDayPath({
    required double latitude,
    required double longitude,
    required DateTime date,
    int steps = 72,
  }) {
    final points = <SolarPathPoint>[];

    // Use local solar midnight as reference
    final offsetMin = (longitude * 4).round();
    final localMidUTC = DateTime.utc(date.year, date.month, date.day)
        .subtract(Duration(minutes: offsetMin));

    for (int i = 0; i <= steps; i++) {
      // Sweep from 00:00 to 24:00 local time
      final minuteOfDay = (i * 1440.0 / steps).round();
      final t = localMidUTC.add(Duration(minutes: minuteOfDay));

      final pos = calculate(
        latitude: latitude,
        longitude: longitude,
        dateTime: t,
      );

      // Include points near or above horizon
      if (pos.altitude > -2) {
        points.add(
          SolarPathPoint(
            azimuth: pos.azimuth,
            altitude: pos.altitude.clamp(0, 90),
            time: t,
          ),
        );
      }
    }
    return points;
  }

  /// Generates monthly sun path data for the chart.
  static List<MonthlyArc> generateMonthlyArcs({
    required double latitude,
    required double longitude,
    required DateTime now,
    int pastMonths = 6,
    int futureMonths = 1,
  }) {
    final arcs = <MonthlyArc>[];
    for (int offset = -pastMonths; offset <= futureMonths; offset++) {
      final month = DateTime(now.year, now.month + offset, 15);
      final path = calculateDayPath(
        latitude: latitude,
        longitude: longitude,
        date: month,
      );
      arcs.add(MonthlyArc(month: month, path: path, isCurrent: offset == 0));
    }
    return arcs;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Private helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Sunrise / sunset calculation.
  static DateTime? _calcSunEvent({
    required double latitude,
    required double longitude,
    required double declination,
    required double eqTimeMinutes,
    required DateTime dateUtc,
    required bool isSunrise,
  }) {
    final latRad = _toRad(latitude);
    final declRad = _toRad(declination);

    // Solar zenith for sunrise/sunset: 90.833° (accounts for refraction
    // + solar disc radius)
    final cosHa =
        (cos(_toRad(90.833)) / (cos(latRad) * cos(declRad))) -
        tan(latRad) * tan(declRad);

    if (cosHa.abs() > 1.0) return null; // Polar day / polar night

    final ha = _toDeg(acos(cosHa.clamp(-1.0, 1.0)));

    // Minutes from midnight UTC
    final eventMinUTC =
        isSunrise
            ? 720.0 - 4.0 * (longitude + ha) - eqTimeMinutes
            : 720.0 - 4.0 * (longitude - ha) - eqTimeMinutes;

    return _minutesToDateTime(eventMinUTC, dateUtc, longitude);
  }

  /// Converts fractional minutes from midnight UTC into a DateTime,
  /// shifted by the longitude's solar timezone offset.
  static DateTime _minutesToDateTime(
    double minutesUTC,
    DateTime referenceUtc,
    double longitude,
  ) {
    final totalMin = minutesUTC.round();
    final h = (totalMin ~/ 60).clamp(0, 23);
    final m = (totalMin % 60).clamp(0, 59);

    final utcTime = DateTime.utc(
      referenceUtc.year,
      referenceUtc.month,
      referenceUtc.day,
      h,
      m,
    );

    // Approximate timezone offset: 15 degrees = 1 hour (4 mins per degree)
    final offsetMinutes = (longitude * 4).round();
    return utcTime.add(Duration(minutes: offsetMinutes));
  }

  /// Julian Date from a UTC DateTime.
  static double _julianDate(DateTime utc) {
    var y = utc.year.toDouble();
    var m = utc.month.toDouble();
    final d =
        utc.day + utc.hour / 24.0 + utc.minute / 1440.0 + utc.second / 86400.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _julianCentury(double jd) => (jd - 2451545.0) / 36525.0;

  /// Atmospheric refraction correction.
  /// Returns the correction in DEGREES (already converted from arc-seconds).
  /// Follows the Meeus / Bennett formula.
  static double _refractionCorrectionDeg(double altitudeDeg) {
    if (altitudeDeg > 85.0) return 0.0;

    double refractionArcSec;

    if (altitudeDeg > 5.0) {
      final tanAlt = tan(_toRad(altitudeDeg));
      refractionArcSec =
          58.1 / tanAlt -
          0.07 / (tanAlt * tanAlt * tanAlt) +
          0.000086 / (tanAlt * tanAlt * tanAlt * tanAlt * tanAlt);
    } else if (altitudeDeg > -0.575) {
      refractionArcSec =
          1735.0 +
          altitudeDeg *
              (-518.2 +
                  altitudeDeg *
                      (103.4 + altitudeDeg * (-12.79 + altitudeDeg * 0.711)));
    } else {
      refractionArcSec = -20.774 / tan(_toRad(altitudeDeg));
    }

    // Convert arc-seconds → degrees
    return refractionArcSec / 3600.0;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
  static double _toDeg(double rad) => rad * 180.0 / pi;
  static double _normalize360(double deg) => ((deg % 360) + 360) % 360;
}

/// Solar position data at a specific moment.
class SolarPosition {
  final double altitude;
  final double azimuth;
  final double declination;
  final double hourAngle;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime solarNoon;

  const SolarPosition({
    required this.altitude,
    required this.azimuth,
    required this.declination,
    required this.hourAngle,
    this.sunrise,
    this.sunset,
    required this.solarNoon,
  });
}

/// Single point on a daily sun path curve.
class SolarPathPoint {
  final double azimuth;
  final double altitude;
  final DateTime time;

  const SolarPathPoint({
    required this.azimuth,
    required this.altitude,
    required this.time,
  });
}

/// One month's sun path arc for the chart.
class MonthlyArc {
  final DateTime month;
  final List<SolarPathPoint> path;
  final bool isCurrent;

  const MonthlyArc({
    required this.month,
    required this.path,
    required this.isCurrent,
  });
}
