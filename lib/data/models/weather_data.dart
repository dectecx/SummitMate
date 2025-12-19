import 'package:hive/hive.dart';

part 'weather_data.g.dart';

@HiveType(typeId: 4)
class WeatherData extends HiveObject {
  @HiveField(0)
  final double temperature; // C

  @HiveField(1)
  final double humidity; // %

  @HiveField(2)
  final int rainProbability; // %

  @HiveField(3)
  final double windSpeed; // m/s

  @HiveField(4)
  final String condition; // Wx Description (e.g. 多雲)

  @HiveField(5)
  final DateTime sunrise;

  @HiveField(6)
  final DateTime sunset;

  @HiveField(7)
  final DateTime timestamp; // Fetch time

  @HiveField(8)
  final String locationName; // e.g. 海端鄉

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeed,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
    required this.locationName,
  });

  // Factory check for stale data (e.g. > 3 hours old, refresh needed)
  bool get isStale => DateTime.now().difference(timestamp).inHours > 3;
}
