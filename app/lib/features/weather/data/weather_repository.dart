import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import '../domain/weather_models.dart';

/// Fetches a forecast from our backend (which asks the weather source).
abstract interface class WeatherApi {
  /// Returns the server's JSON body as text.
  Future<String> forecast(WeatherQuery q, {int days});
}

class DioWeatherApi implements WeatherApi {
  DioWeatherApi(this._dio);
  final Dio _dio;

  @override
  Future<String> forecast(WeatherQuery q, {int days = 7}) async {
    final res = await _dio.get<String>(
      '/weather/forecast',
      queryParameters: {'lat': q.lat, 'lng': q.lng, 'elevation': ?q.elevation, 'days': days},
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }
}

/// Cached-read weather: show the last forecast straight away (it works offline on the mountain),
/// then refresh it when it is older than [maxAge] and a connection to the server is possible.
class WeatherRepository {
  WeatherRepository(this._db, this._api, {DateTime Function()? now, this.maxAge = const Duration(hours: 3)}) : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final WeatherApi _api;
  final DateTime Function() _now;
  final Duration maxAge;

  Stream<WeatherState> watch(WeatherQuery q, {required bool signedIn}) async* {
    final key = weatherCacheKey(q);
    final row = await (_db.select(_db.weatherCache)..where((c) => c.key.equals(key))).getSingleOrNull();
    WeatherForecast? cached;
    var fresh = false;
    if (row != null) {
      try {
        cached = WeatherForecast.parse(row.payload);
        fresh = _now().difference(row.fetchedAt) < maxAge;
      } on Object {
        cached = null; // unreadable (e.g. from an older version): refetch
      }
    }
    if (cached != null) yield WeatherData(cached, stale: !fresh);
    if (fresh) return;
    if (!signedIn) {
      if (cached == null) yield const WeatherNeedsLogin();
      return;
    }
    if (cached == null) yield const WeatherLoading();
    try {
      final payload = await _api.forecast(q);
      final forecast = WeatherForecast.parse(payload); // validates before it is stored
      await _db.into(_db.weatherCache).insertOnConflictUpdate(WeatherCacheCompanion.insert(key: key, payload: payload, fetchedAt: _now()));
      yield WeatherData(forecast);
    } on Object {
      yield cached == null ? const WeatherUnavailable() : WeatherData(cached, stale: true, refreshFailed: true);
    }
  }
}
