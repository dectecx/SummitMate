import 'package:hive_ce/hive.dart';
import '../../domain/entities/weather_data.dart';

part 'weather_data_model.g.dart';

@HiveType(typeId: 4)
class WeatherDataModel extends HiveObject {
  @HiveField(0)
  final double temperature;

  @HiveField(1)
  final double humidity;

  @HiveField(2)
  final int rainProbability;

  @HiveField(3)
  final double windSpeed;

  @HiveField(4)
  final String condition;

  @HiveField(5)
  final DateTime sunrise;

  @HiveField(6)
  final DateTime sunset;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String locationName;

  @HiveField(9)
  final List<DailyForecastModel> dailyForecasts;

  @HiveField(10)
  final double? apparentTemperature;

  @HiveField(11)
  final DateTime? issueTime;

  WeatherDataModel({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeed,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
    required this.locationName,
    this.dailyForecasts = const [],
    this.apparentTemperature,
    this.issueTime,
  });

  WeatherData toDomain() => WeatherData(
    temperature: temperature,
    humidity: humidity,
    rainProbability: rainProbability,
    windSpeed: windSpeed,
    condition: condition,
    sunrise: sunrise,
    sunset: sunset,
    timestamp: timestamp,
    locationName: locationName,
    dailyForecasts: dailyForecasts.map((f) => f.toDomain()).toList(),
    apparentTemperature: apparentTemperature,
    issueTime: issueTime,
  );

  factory WeatherDataModel.fromDomain(WeatherData entity) => WeatherDataModel(
    temperature: entity.temperature,
    humidity: entity.humidity,
    rainProbability: entity.rainProbability,
    windSpeed: entity.windSpeed,
    condition: entity.condition,
    sunrise: entity.sunrise,
    sunset: entity.sunset,
    timestamp: entity.timestamp,
    locationName: entity.locationName,
    dailyForecasts: entity.dailyForecasts.map((f) => DailyForecastModel.fromDomain(f)).toList(),
    apparentTemperature: entity.apparentTemperature,
    issueTime: entity.issueTime,
  );
}

@HiveType(typeId: 5)
class DailyForecastModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String dayCondition;

  @HiveField(2)
  final String nightCondition;

  @HiveField(3)
  final double maxTemp;

  @HiveField(4)
  final double minTemp;

  @HiveField(5)
  final int rainProbability;

  @HiveField(6)
  final double? maxApparentTemp;

  @HiveField(7)
  final double? minApparentTemp;

  DailyForecastModel({
    required this.date,
    required this.dayCondition,
    required this.nightCondition,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    this.maxApparentTemp,
    this.minApparentTemp,
  });

  DailyForecast toDomain() => DailyForecast(
    date: date,
    dayCondition: dayCondition,
    nightCondition: nightCondition,
    maxTemp: maxTemp,
    minTemp: minTemp,
    rainProbability: rainProbability,
    maxApparentTemp: maxApparentTemp,
    minApparentTemp: minApparentTemp,
  );

  factory DailyForecastModel.fromDomain(DailyForecast entity) => DailyForecastModel(
    date: entity.date,
    dayCondition: entity.dayCondition,
    nightCondition: entity.nightCondition,
    maxTemp: entity.maxTemp,
    minTemp: entity.minTemp,
    rainProbability: entity.rainProbability,
    maxApparentTemp: entity.maxApparentTemp,
    minApparentTemp: entity.minApparentTemp,
  );
}
