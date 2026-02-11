import 'package:hive/hive.dart';

part 'weather_data.g.dart';

@HiveType(typeId: 4)
class WeatherData extends HiveObject {
  /// 目前氣溫 (攝氏)
  @HiveField(0)
  final double temperature;

  /// 相對濕度 (%)
  @HiveField(1)
  final double humidity;

  /// 降雨機率 (%)
  @HiveField(2)
  final int rainProbability;

  /// 風速 (m/s)
  @HiveField(3)
  final double windSpeed;

  /// 天氣現象描述 (如: 多雲)
  @HiveField(4)
  final String condition;

  /// 日出時間
  @HiveField(5)
  final DateTime sunrise;

  /// 日沒時間
  @HiveField(6)
  final DateTime sunset;

  /// 資料更新時間
  @HiveField(7)
  final DateTime timestamp;

  /// 地點名稱 (如: 向陽山)
  @HiveField(8)
  final String locationName;

  /// 未來7天天氣預報
  @HiveField(9)
  final List<DailyForecast> dailyForecasts;

  /// 體感溫度 (攝氏, optional)
  @HiveField(10)
  final double? apparentTemperature;

  /// 資料發布時間 (CWA Dataset IssueTime, optional)
  @HiveField(11)
  final DateTime? issueTime;

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
    this.dailyForecasts = const [],
    this.apparentTemperature,
    this.issueTime,
  });

  /// 檢查資料是否過期 (> 3小時)
  bool get isStale => DateTime.now().difference(timestamp).inHours > 3;
}

@HiveType(typeId: 5)
class DailyForecast extends HiveObject {
  /// 日期
  @HiveField(0)
  final DateTime date;

  /// 白天天氣現象
  @HiveField(1)
  final String dayCondition;

  /// 晚上天氣現象
  @HiveField(2)
  final String nightCondition;

  /// 最高溫
  @HiveField(3)
  final double maxTemp;

  /// 最低溫
  @HiveField(4)
  final double minTemp;

  /// 降雨機率 (平均或最高)
  @HiveField(5)
  final int rainProbability;

  /// 最高體感溫度
  @HiveField(6)
  final double? maxApparentTemp;

  /// 最低體感溫度
  @HiveField(7)
  final double? minApparentTemp;

  DailyForecast({
    required this.date,
    required this.dayCondition,
    required this.nightCondition,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    this.maxApparentTemp,
    this.minApparentTemp,
  });
}
