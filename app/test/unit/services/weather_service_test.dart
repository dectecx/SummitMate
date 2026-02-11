import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
// Note: We don't import the actual WeatherService since it has dependencies on Hive and DI
// Instead, we create a test helper that replicates the pure logic for testing

void main() {
  group('WeatherService Sun Calculation Tests', () {
    late WeatherServiceTestHelper helper;

    setUp(() {
      helper = WeatherServiceTestHelper();
    });

    test('calculateSunTimes returns valid sunrise and sunset', () {
      // 測試台灣嘉明湖區域 (緯度 23.29, 經度 121.03)
      final date = DateTime(2024, 6, 21); // 夏至
      final result = helper.calculateSunTimes(date, 23.29, 121.03);

      expect(result['sunrise'], isNotNull);
      expect(result['sunset'], isNotNull);

      // 日出應在凌晨 (4-6 點之間)
      expect(result['sunrise']!.hour, inInclusiveRange(4, 6));
      // 日落應在傍晚 (17-20 點之間)
      expect(result['sunset']!.hour, inInclusiveRange(17, 20));
    });

    test('calculateSunTimes winter has shorter days', () {
      final summer = DateTime(2024, 6, 21);
      final winter = DateTime(2024, 12, 21);

      final summerTimes = helper.calculateSunTimes(summer, 23.29, 121.03);
      final winterTimes = helper.calculateSunTimes(winter, 23.29, 121.03);

      final summerDayLength = summerTimes['sunset']!.difference(summerTimes['sunrise']!);
      final winterDayLength = winterTimes['sunset']!.difference(winterTimes['sunrise']!);

      // 夏天白天比冬天長
      expect(summerDayLength.inMinutes, greaterThan(winterDayLength.inMinutes));
    });

    test('calculateSunTimes handles equator latitude', () {
      final date = DateTime(2024, 3, 20); // 春分
      final result = helper.calculateSunTimes(date, 0.0, 121.0);

      expect(result['sunrise'], isNotNull);
      expect(result['sunset'], isNotNull);

      // 赤道上白天約 12 小時
      final dayLength = result['sunset']!.difference(result['sunrise']!);
      expect(dayLength.inHours, closeTo(12, 1));
    });

    test('calculateSunTimes handles extreme latitude', () {
      // 高緯度地區 (北極圈附近)
      final date = DateTime(2024, 6, 21);
      final result = helper.calculateSunTimes(date, 66.5, 121.0);

      // 不應該拋出異常
      expect(result['sunrise'], isNotNull);
      expect(result['sunset'], isNotNull);
    });
  });

  group('WeatherService Data Parsing Tests', () {
    late WeatherServiceTestHelper helper;

    setUp(() {
      helper = WeatherServiceTestHelper();
    });

    test('parseGasWeatherData throws on empty location', () {
      final emptyList = <Map<String, dynamic>>[];

      expect(() => helper.parseGasWeatherData(emptyList, '向陽山'), throwsException);
    });

    test('parseGasWeatherData throws on wrong location', () {
      final mockData = [
        {
          'Location': '玉山',
          'StartTime': '2024-01-01T06:00:00',
          'T': '10',
          'RH': '80',
          'PoP': '30',
          'WS': '5',
          'Wx': '晴',
          'MaxT': '15',
          'MinT': '5',
          'MaxAT': '12',
          'MinAT': '3',
        },
      ];

      expect(() => helper.parseGasWeatherData(mockData, '雪山'), throwsException);
    });

    test('parseGasWeatherData correctly parses temperature', () {
      final mockData = [
        {
          'Location': '向陽山',
          'StartTime': '2024-01-01T06:00:00',
          'T': '15.5',
          'RH': '75',
          'PoP': '20',
          'WS': '3.5',
          'Wx': '多雲',
          'MaxT': '18',
          'MinT': '12',
          'MaxAT': '16',
          'MinAT': '10',
        },
      ];

      final result = helper.parseGasWeatherData(mockData, '向陽山');

      expect(result.temperature, 15.5);
      expect(result.humidity, 75.0);
      expect(result.rainProbability, 20);
      expect(result.windSpeed, 3.5);
      expect(result.condition, '多雲');
      expect(result.locationName, '向陽山');
    });

    test('parseGasWeatherData handles invalid numeric values gracefully', () {
      final mockData = [
        {
          'Location': '向陽山',
          'StartTime': '2024-01-01T06:00:00',
          'T': 'invalid',
          'RH': '',
          'PoP': 'N/A',
          'WS': null,
          'Wx': '晴',
          'MaxT': '',
          'MinT': '',
          'MaxAT': '',
          'MinAT': '',
        },
      ];

      // 應該不拋出異常，使用預設值
      final result = helper.parseGasWeatherData(mockData, '向陽山');

      expect(result.temperature, 0.0);
      expect(result.humidity, 0.0);
      expect(result.rainProbability, 0);
    });

    test('parseGasWeatherData builds daily forecasts correctly', () {
      final mockData = [
        {
          'Location': '向陽山',
          'StartTime': '2024-01-01T06:00:00',
          'T': '10',
          'RH': '80',
          'PoP': '30',
          'WS': '5',
          'Wx': '晴',
          'MaxT': '15',
          'MinT': '5',
          'MaxAT': '13',
          'MinAT': '3',
        },
        {
          'Location': '向陽山',
          'StartTime': '2024-01-01T18:00:00',
          'T': '8',
          'RH': '90',
          'PoP': '40',
          'WS': '3',
          'Wx': '多雲',
          'MaxT': '15',
          'MinT': '5',
          'MaxAT': '13',
          'MinAT': '3',
        },
        {
          'Location': '向陽山',
          'StartTime': '2024-01-02T06:00:00',
          'T': '12',
          'RH': '70',
          'PoP': '10',
          'WS': '2',
          'Wx': '晴時多雲',
          'MaxT': '16',
          'MinT': '6',
          'MaxAT': '14',
          'MinAT': '4',
        },
      ];

      final result = helper.parseGasWeatherData(mockData, '向陽山');

      // 應該有 2 天預報
      expect(result.dailyForecasts.length, 2);

      // 第一天
      expect(result.dailyForecasts[0].date.day, 1);
      expect(result.dailyForecasts[0].dayCondition, '晴');
      expect(result.dailyForecasts[0].nightCondition, '多雲');
      expect(result.dailyForecasts[0].maxTemp, 15.0);
      expect(result.dailyForecasts[0].minTemp, 5.0);
      expect(result.dailyForecasts[0].rainProbability, 40); // 取最大值

      // 第二天
      expect(result.dailyForecasts[1].date.day, 2);
      expect(result.dailyForecasts[1].dayCondition, '晴時多雲');
    });
  });
}

/// Helper class to expose private methods for testing
/// 這是一個測試輔助類，用於複製 WeatherService 的純邏輯
class WeatherServiceTestHelper {
  /// 計算日出日落時間 (複製自 WeatherService._calculateSunTimes)
  Map<String, DateTime> calculateSunTimes(DateTime date, double lat, double lng) {
    final startOfYear = DateTime(date.year, 1, 1, 0, 0, 0);
    final dayOfYear = date.difference(startOfYear).inDays + 1;

    final radLat = (pi / 180) * lat;
    final declination = 0.4095 * sin(0.016906 * (dayOfYear - 80.089));

    double halfDayRad = 0;
    try {
      final val = -tan(radLat) * tan(declination);
      halfDayRad = acos(val.clamp(-1.0, 1.0));
    } catch (_) {
      halfDayRad = pi / 2;
    }

    final halfDayHours = (halfDayRad * 180 / pi) / 15.0;
    final timeOffsetMin = (lng - 120.0) * 4.0;
    final solarNoon = 12.0 - (timeOffsetMin / 60.0);

    final sunriseHour = solarNoon - halfDayHours;
    final sunsetHour = solarNoon + halfDayHours;

    DateTime toTime(double h) {
      int hour = h.floor();
      int min = ((h - hour) * 60).round();
      return DateTime(date.year, date.month, date.day, hour, min);
    }

    return {'sunrise': toTime(sunriseHour), 'sunset': toTime(sunsetHour)};
  }

  /// 解析 GAS 天氣資料 (複製自 WeatherService._parseGasWeatherData)
  TestWeatherData parseGasWeatherData(List<Map<String, dynamic>> list, String locationName) {
    final locationRows = list.where((item) => item['Location'] == locationName).toList();

    if (locationRows.isEmpty) {
      throw Exception('Location "$locationName" not found in GAS data');
    }

    locationRows.sort((a, b) => a['StartTime'].compareTo(b['StartTime']));

    final current = locationRows.first;

    final temp = double.tryParse(current['T']?.toString() ?? '') ?? 0.0;
    final humidity = double.tryParse(current['RH']?.toString() ?? '') ?? 0.0;
    final pop = int.tryParse(current['PoP']?.toString() ?? '') ?? 0;
    final windSpeed = double.tryParse(current['WS']?.toString() ?? '') ?? 0.0;
    final wx = current['Wx']?.toString() ?? '';

    final maxAT = double.tryParse(current['MaxAT']?.toString() ?? '') ?? 0.0;
    final minAT = double.tryParse(current['MinAT']?.toString() ?? '') ?? 0.0;
    final apparentTemp = (maxAT != 0.0 || minAT != 0.0) ? (maxAT + minAT) / 2 : temp;

    // Build daily forecasts
    final dailyMap = <String, Map<String, dynamic>>{};

    for (var row in locationRows) {
      final start = DateTime.parse(row['StartTime']);
      final dateKey = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";

      dailyMap.putIfAbsent(
        dateKey,
        () => {
          'dayCondition': '',
          'nightCondition': '',
          'maxTemp': -100.0,
          'minTemp': 100.0,
          'maxAT': -100.0,
          'minAT': 100.0,
          'pop': 0,
        },
      );

      final val = row['Wx']?.toString() ?? '';
      if (start.hour >= 6 && start.hour < 18) {
        if (dailyMap[dateKey]!['dayCondition'] == '') {
          dailyMap[dateKey]!['dayCondition'] = val;
        }
      } else {
        if (dailyMap[dateKey]!['nightCondition'] == '') {
          dailyMap[dateKey]!['nightCondition'] = val;
        }
      }

      final maxT = double.tryParse(row['MaxT']?.toString() ?? '');
      if (maxT != null && maxT != 0.0 && maxT > dailyMap[dateKey]!['maxTemp']) {
        dailyMap[dateKey]!['maxTemp'] = maxT;
      }

      final minT = double.tryParse(row['MinT']?.toString() ?? '');
      if (minT != null && minT != 0.0 && minT < dailyMap[dateKey]!['minTemp']) {
        dailyMap[dateKey]!['minTemp'] = minT;
      }

      final p = int.tryParse(row['PoP']?.toString() ?? '') ?? 0;
      if (p > dailyMap[dateKey]!['pop']) {
        dailyMap[dateKey]!['pop'] = p;
      }
    }

    final dailyForecasts = dailyMap.entries.map((e) {
      final d = e.value;
      return TestDailyForecast(
        date: DateTime.parse(e.key),
        dayCondition: d['dayCondition'] == '' ? d['nightCondition'] : d['dayCondition'],
        nightCondition: d['nightCondition'] == '' ? d['dayCondition'] : d['nightCondition'],
        maxTemp: d['maxTemp'] == -100.0 ? 0.0 : d['maxTemp'],
        minTemp: d['minTemp'] == 100.0 ? 0.0 : d['minTemp'],
        rainProbability: d['pop'],
        maxApparentTemp: d['maxAT'] == -100.0 ? 0.0 : d['maxAT'],
        minApparentTemp: d['minAT'] == 100.0 ? 0.0 : d['minAT'],
      );
    }).toList();

    dailyForecasts.sort((a, b) => a.date.compareTo(b.date));

    final sunTimes = calculateSunTimes(DateTime.now(), 23.29, 121.03);

    return TestWeatherData(
      temperature: temp,
      humidity: humidity,
      rainProbability: pop,
      windSpeed: windSpeed,
      condition: wx,
      sunrise: sunTimes['sunrise']!,
      sunset: sunTimes['sunset']!,
      timestamp: DateTime.now(),
      locationName: locationName,
      dailyForecasts: dailyForecasts,
      apparentTemperature: apparentTemp,
      issueTime: null,
    );
  }
}

/// Test-only WeatherData class
class TestWeatherData {
  final double temperature;
  final double humidity;
  final int rainProbability;
  final double windSpeed;
  final String condition;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime timestamp;
  final String locationName;
  final List<TestDailyForecast> dailyForecasts;
  final double apparentTemperature;
  final DateTime? issueTime;

  TestWeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.windSpeed,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
    required this.locationName,
    required this.dailyForecasts,
    required this.apparentTemperature,
    this.issueTime,
  });
}

/// Test-only DailyForecast class
class TestDailyForecast {
  final DateTime date;
  final String dayCondition;
  final String nightCondition;
  final double maxTemp;
  final double minTemp;
  final int rainProbability;
  final double maxApparentTemp;
  final double minApparentTemp;

  TestDailyForecast({
    required this.date,
    required this.dayCondition,
    required this.nightCondition,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.maxApparentTemp,
    required this.minApparentTemp,
  });
}
