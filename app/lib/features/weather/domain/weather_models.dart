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

/// Where a trip day is spent, for the forecast: the place and the query for it.
typedef DayPlace = ({int day, DateTime date, String? placeName, int? altitude, WeatherQuery? query});

/// One forecast place per trip day. A day is forecast at its highest node that has coordinates (that is the
/// coldest and windiest place of the day, the one people need to prepare for); a day with no located node
/// falls back to the previous day's place, then to the trip's main mountain.
List<DayPlace> weatherPlanFor({
  required DateTime start,
  required int dayCount,
  required List<ItineraryItem> items,
  WeatherQuery? fallback,
  String? fallbackName,
}) {
  final plan = <DayPlace>[];
  DayPlace? previous;
  for (var day = 1; day <= dayCount; day++) {
    final date = DateTime(start.year, start.month, start.day + day - 1);
    final located = items.where((i) => i.dayIndex == day && i.lat != null && i.lng != null).toList()
      ..sort((a, b) => b.altitude.compareTo(a.altitude));
    DayPlace entry;
    if (located.isNotEmpty) {
      final i = located.first;
      entry = (
        day: day,
        date: date,
        placeName: i.name.isEmpty ? null : i.name,
        altitude: i.altitude > 0 ? i.altitude : null,
        query: (lat: i.lat!, lng: i.lng!, elevation: i.altitude > 0 ? i.altitude : null),
      );
    } else if (previous != null && previous.query != null) {
      entry = (day: day, date: date, placeName: previous.placeName, altitude: previous.altitude, query: previous.query);
    } else {
      entry = (day: day, date: date, placeName: fallbackName, altitude: fallback?.elevation, query: fallback);
    }
    plan.add(entry);
    previous = entry;
  }
  // Days before the first located day take the first located day's place rather than staying empty.
  final firstWithQuery = plan.cast<DayPlace?>().firstWhere((e) => e!.query != null, orElse: () => null);
  if (firstWithQuery != null) {
    for (var k = 0; k < plan.length && plan[k].query == null; k++) {
      plan[k] = (day: plan[k].day, date: plan[k].date, placeName: firstWithQuery.placeName, altitude: firstWithQuery.altitude, query: firstWithQuery.query);
    }
  }
  return plan;
}

/// Short advice for a day, or null when nothing stands out.
String? weatherAdvice(DailyForecast d) {
  final tips = <String>[
    if ((d.rainChance ?? 0) >= 50 || d.rainMm >= 10) '帶雨具、做好防水',
    if (d.tempMin <= 3) '低溫，注意保暖',
    if (d.windMax >= 40 || (d.gustMax ?? 0) >= 60) '強風，稜線要小心',
    if (d.weatherCode >= 95) '雷雨，避開稜線與空曠處',
  ];
  return tips.isEmpty ? null : tips.join('、');
}
