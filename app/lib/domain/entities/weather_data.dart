import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_data.freezed.dart';
part 'weather_data.g.dart';

/// 天氣資料實體 (Domain Entity)
@freezed
abstract class WeatherData with _$WeatherData {
  const WeatherData._();

  const factory WeatherData({
    required double temperature,
    required double humidity,
    required int rainProbability,
    required double windSpeed,
    required String condition,
    required DateTime sunrise,
    required DateTime sunset,
    required DateTime timestamp,
    required String locationName,
    @Default([]) List<DailyForecast> dailyForecasts,
    double? apparentTemperature,
    DateTime? issueTime,
  }) = _WeatherData;

  bool get isStale => DateTime.now().difference(timestamp).inHours > 3;

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);
}

/// 每日天氣預報實體 (Domain Entity)
@freezed
abstract class DailyForecast with _$DailyForecast {
  const factory DailyForecast({
    required DateTime date,
    required String dayCondition,
    required String nightCondition,
    required double maxTemp,
    required double minTemp,
    required int rainProbability,
    double? maxApparentTemp,
    double? minApparentTemp,
  }) = _DailyForecast;

  factory DailyForecast.fromJson(Map<String, dynamic> json) => _$DailyForecastFromJson(json);
}
