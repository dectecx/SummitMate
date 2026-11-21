import 'dart:convert';

import '../../../core/db/app_database.dart';

/// A place to forecast: coordinates and, for mountains, the elevation in metres.
typedef WeatherQuery = ({double lat, double lng, int? elevation});

/// Identifies a place in the cache. Must round like the server so nearby points share a forecast.
String weatherCacheKey(WeatherQuery q) => '${q.lat.toStringAsFixed(2)},${q.lng.toStringAsFixed(2)},${q.elevation == null ? '-' : (q.elevation! / 100).round() * 100}';

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.rainChance,
    required this.rainMm,
    required this.windMax,
    required this.gustMax,
  });

  final DateTime date;

  /// WMO weather interpretation code.
  final int weatherCode;
  final double tempMax;
  final double tempMin;

  /// Chance of rain in percent, when the model gives one.
  final int? rainChance;
  final double rainMm;
  final double windMax;
  final double? gustMax;

  factory DailyForecast.fromJson(Map<String, dynamic> j) {
    final d = (j['date'] as String).split('-').map(int.parse).toList();
    return DailyForecast(
      date: DateTime(d[0], d[1], d[2]),
      weatherCode: (j['weather_code'] as num).toInt(),
      tempMax: (j['temp_max'] as num).toDouble(),
      tempMin: (j['temp_min'] as num).toDouble(),
      rainChance: (j['precipitation_probability_max'] as num?)?.toInt(),
      rainMm: (j['precipitation_sum'] as num).toDouble(),
      windMax: (j['wind_speed_max'] as num).toDouble(),
      gustMax: (j['wind_gusts_max'] as num?)?.toDouble(),
    );
  }
}

class WeatherForecast {
  const WeatherForecast({required this.latitude, required this.longitude, required this.elevation, required this.fetchedAt, required this.daily});
  final double latitude;
  final double longitude;
  final double? elevation;

  /// When the server fetched this from its source.
  final DateTime fetchedAt;
  final List<DailyForecast> daily;

  factory WeatherForecast.parse(String payload) {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    return WeatherForecast(
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble(),
      elevation: (j['elevation'] as num?)?.toDouble(),
      fetchedAt: DateTime.parse(j['fetched_at'] as String),
      daily: [for (final d in j['daily'] as List) DailyForecast.fromJson((d as Map).cast<String, dynamic>())],
    );
  }
}

/// What the weather card can show.
sealed class WeatherState {
  const WeatherState();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

/// Signed-out people have no token for the server.
class WeatherNeedsLogin extends WeatherState {
  const WeatherNeedsLogin();
}

class WeatherUnavailable extends WeatherState {
  const WeatherUnavailable();
}

class WeatherData extends WeatherState {
  const WeatherData(this.forecast, {this.stale = false, this.refreshFailed = false});
  final WeatherForecast forecast;

  /// Older than the refresh interval (shown while a refresh is running or after it failed).
  final bool stale;
  final bool refreshFailed;
}

/// The place whose weather to show for a trip: the first node (by day, then time) that has coordinates.
WeatherQuery? weatherLocationOf(List<ItineraryItem> items) {
  final located = items.where((i) => i.lat != null && i.lng != null).toList()
    ..sort((a, b) {
      final d = a.dayIndex.compareTo(b.dayIndex);
      if (d != 0) return d;
      return (a.estMinutes ?? 1 << 20).compareTo(b.estMinutes ?? 1 << 20);
    });
  if (located.isEmpty) return null;
  final i = located.first;
  return (lat: i.lat!, lng: i.lng!, elevation: i.altitude > 0 ? i.altitude : null);
}
