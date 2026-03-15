class ApiConstants {
  static const String openMeteoForecastBase =
      'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoArchiveBase =
      'https://archive-api.open-meteo.com/v1/archive';

  static String forecastUrl(double lat, double lon) =>
      '$openMeteoForecastBase?latitude=$lat&longitude=$lon'
      '&hourly=wind_speed_10m,wind_direction_10m,relative_humidity_2m'
      '&daily=wind_direction_10m_dominant'
      '&wind_speed_unit=ms'
      '&forecast_days=1';

  static String archiveUrl(
    double lat,
    double lon,
    String startDate,
    String endDate,
  ) =>
      '$openMeteoArchiveBase?latitude=$lat&longitude=$lon'
      '&start_date=$startDate&end_date=$endDate'
      '&daily=wind_direction_10m_dominant,wind_speed_10m_max';
}
