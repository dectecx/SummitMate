import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../core/location/i_location_resolver.dart';
import '../../data/cwa/cwa_weather_source.dart';
import '../../domain/domain.dart';
import '../../domain/entities/weather_data.dart';
import '../database/app_database.dart';

@LazySingleton(as: IWeatherService)
class WeatherService implements IWeatherService {
  final ILocationResolver _locationResolver;
  final CwaWeatherSource _cwaSource;
  final AppDatabase _db;

  final _weatherController = StreamController<WeatherData?>.broadcast();

  WeatherService({
    required ISettingsRepository settingsRepo, // Keep for constructor compatibility if needed, though unused
    required ILocationResolver locationResolver,
    required CwaWeatherSource cwaSource,
    required AppDatabase db,
  }) : _locationResolver = locationResolver,
       _cwaSource = cwaSource,
       _db = db;

  @override
  Future<void> init() async {
    // 初始化邏輯
  }

  @override
  Stream<WeatherData?> get onWeatherChanged => _weatherController.stream;

  @override
  Future<WeatherData?> getWeatherByName(String locationName, {bool forceRefresh = false}) async {
    final cacheKey = 'weather_$locationName';

    // 1. 檢查快取
    if (!forceRefresh) {
      try {
        final cached = await (_db.select(_db.weatherDataTable)..where((t) => t.id.equals(cacheKey))).getSingleOrNull();
        if (cached != null) {
          final now = DateTime.now();
          if (now.difference(cached.updatedAt).inMinutes < 30) {
            final data = WeatherData.fromJson(json.decode(cached.data));
            _weatherController.add(data);
            return data;
          }
        }
      } catch (_) {}
    }

    // 2. 從 API 抓取
    try {
      final weatherData = await _cwaSource.getWeather(locationName);

      // 3. 更新快取
      await _db
          .into(_db.weatherDataTable)
          .insertOnConflictUpdate(
            WeatherDataTableCompanion.insert(
              id: cacheKey,
              data: json.encode(weatherData.toJson()),
              updatedAt: DateTime.now(),
            ),
          );

      _weatherController.add(weatherData);
      return weatherData;
    } catch (e) {
      // 失敗時嘗試回傳舊快取
      try {
        final cached = await (_db.select(_db.weatherDataTable)..where((t) => t.id.equals(cacheKey))).getSingleOrNull();
        if (cached != null) {
          return WeatherData.fromJson(json.decode(cached.data));
        }
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<WeatherData?> getWeatherByLocation(double lat, double lon, {bool forceRefresh = false}) async {
    // 1. 將座標轉換為行政區
    final location = await _locationResolver.resolve(lat, lon);
    if (location == null) return null;

    return getWeatherByName(location.name, forceRefresh: forceRefresh);
  }
}
