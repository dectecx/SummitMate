import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/env_config.dart';
import '../../services/log_service.dart';
import '../models/weather_data.dart';
import '../models/cwa/cwa_response_models.dart';
import 'cwa_api_factory.dart';

class CwaWeatherSource {
  static const String _apiKey = EnvConfig.cwaApiKey;

  /// Fetch weather for a specific location using Township Forecast API
  Future<WeatherData> getWeather(String locationName) async {
    String countyName = '';
    if (locationName.length >= 3) {
      countyName = locationName.substring(0, 3);
    }

    final dataId = CwaApiFactory.getTownshipForecastId(countyName);
    var queryName = locationName;
    if (countyName.isNotEmpty && locationName.length > 3) {
      queryName = locationName.substring(3);
    }

    // We query with specific elements to reduce payload size
    final url =
        '${EnvConfig.cwaApiHost}/api/v1/rest/datastore/$dataId?Authorization=$_apiKey&locationName=$queryName&elementName=PoP12h,T,Wx,MinT,MaxT,MinAT,MaxAT,RH,WS';

    LogService.debug('CWA API URL: $url', source: 'CwaWeatherSource');

    try {
      final response = await http.get(Uri.parse(url));

      LogService.info('CWA API Status: ${response.statusCode}', source: 'CwaWeatherSource');

      if (response.statusCode == 200) {
        final bodyStr = utf8.decode(response.bodyBytes);
        LogService.debug('CWA API Response (Length: ${bodyStr.length})', source: 'CwaWeatherSource');

        final decoded = jsonDecode(bodyStr);
        final cwaResponse = CwaApiResponse.fromJson(decoded);

        if (cwaResponse.success == 'true') {
          final weather = _parseTownshipData(cwaResponse, locationName, queryName);
          if (weather != null) return weather;
          throw Exception('Parsed weather is null');
        } else {
          throw Exception('CWA API Error: Result was not success');
        }
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('CWA API Auth Failed. Check API Key.');
        }
        throw Exception('CWA API Failed with status ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('CWA API Request failed: $e', source: 'CwaWeatherSource');
      rethrow;
    }
  }

  WeatherData? _parseTownshipData(CwaApiResponse response, String displayName, String queryName) {
    // 1. Find Location
    // Flatten all locations from all records (usually just 1 record but hierarchy exists)
    final allLocs = response.records.locationsList.expand((l) => l.location).toList();

    var location = allLocs.firstWhere(
      (l) => l.locationName == queryName,
      orElse: () => CwaLocation(locationName: '', weatherElement: []),
    );

    // Fallback to displayName
    if (location.locationName.isEmpty) {
      location = allLocs.firstWhere(
        (l) => l.locationName == displayName,
        orElse: () => CwaLocation(locationName: '', weatherElement: []),
      );
    }

    if (location.locationName.isEmpty) {
      LogService.warning('Location $queryName not found in response', source: 'CwaWeatherSource');
      return null;
    }

    // 2. Helper to get Time Series for a concept
    List<CwaTime> getTimeSeries(String concept) {
      final possibleKeys = CwaApiFactory.getElementKeys(concept);
      final element = location.weatherElement.firstWhere(
        (e) => possibleKeys.contains(e.elementName),
        orElse: () => CwaWeatherElement(elementName: '', time: []),
      );
      return element.time;
    }

    // 3. Helper to get Current Value safely
    String getCurrentValue(String concept) {
      final series = getTimeSeries(concept);
      if (series.isEmpty) return '';
      final prefKey = CwaApiFactory.getElementValueKey(concept);
      return series[0].getValue([prefKey]);
    }

    final temperature = double.tryParse(getCurrentValue('Temperature')) ?? 0.0;
    final humidity = double.tryParse(getCurrentValue('RH')) ?? 0.0;
    final rainProbability = int.tryParse(getCurrentValue('PoP')) ?? 0;
    final condition = getCurrentValue('Wx');
    final windSpeed = double.tryParse(getCurrentValue('WS')) ?? 0.0;

    // Apparent Temp
    final maxApparentTemp = double.tryParse(getCurrentValue('MaxAT')) ?? 0.0;
    final minApparentTemp = double.tryParse(getCurrentValue('MinAT')) ?? 0.0;
    final apparentTemp = (maxApparentTemp != 0.0 || minApparentTemp != 0.0)
        ? (maxApparentTemp + minApparentTemp) / 2
        : temperature;

    // Issue Time (Current approx)
    final issueTime = DateTime.now();

    // 4. Build Daily Forecast
    final dailyMap = <String, Map<String, dynamic>>{};

    // Wx
    final wxSeries = getTimeSeries('Wx');
    for (var item in wxSeries) {
      final dateKey =
          "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
      dailyMap.putIfAbsent(
        dateKey,
        () => {'day': '', 'night': '', 'maxTemp': -100.0, 'minTemp': 100.0, 'pop': 0, 'maxAT': -100.0, 'minAT': 100.0},
      );
      final value = item.getValue(['Weather', 'value']);
      if (item.startTime.hour >= 6 && item.startTime.hour < 18) {
        dailyMap[dateKey]!['day'] = value;
      } else {
        dailyMap[dateKey]!['night'] = value;
      }
    }

    void processMinMax(String concept, String mapKey, bool isMax) {
      final series = getTimeSeries(concept);
      final prefKey = CwaApiFactory.getElementValueKey(concept);
      for (var item in series) {
        final dateKey =
            "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
        if (!dailyMap.containsKey(dateKey)) continue;
        final value = double.tryParse(item.getValue([prefKey, 'value'])) ?? 0.0;
        if (isMax) {
          if (value > dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = value;
        } else {
          if (value < dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = value;
        }
      }
    }

    processMinMax('MaxT', 'maxTemp', true);
    processMinMax('MinT', 'minTemp', false);
    processMinMax('MaxAT', 'maxAT', true);
    processMinMax('MinAT', 'minAT', false);

    // PoP
    final popSeries = getTimeSeries('PoP');
    for (var item in popSeries) {
      final dateKey =
          "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
      if (!dailyMap.containsKey(dateKey)) continue;
      final value = int.tryParse(item.getValue(['ProbabilityOfPrecipitation', 'value'])) ?? 0;
      if (value > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = value;
    }

    final dailyForecasts = dailyMap.entries.map((e) {
      final d = e.value;
      return DailyForecast(
        date: DateTime.parse(e.key),
        dayCondition: d['day'] == '' ? d['night'] : d['day'],
        nightCondition: d['night'] == '' ? d['day'] : d['night'],
        maxTemp: d['maxTemp'] == -100.0 ? 0.0 : d['maxTemp'],
        minTemp: d['minTemp'] == 100.0 ? 0.0 : d['minTemp'],
        rainProbability: d['pop'],
        maxApparentTemp: d['maxAT'] == -100.0 ? 0.0 : d['maxAT'],
        minApparentTemp: d['minAT'] == 100.0 ? 0.0 : d['minAT'],
      );
    }).toList();

    dailyForecasts.sort((a, b) => a.date.compareTo(b.date));

    final sunTimes = _calculateSunTimes(DateTime.now(), 23.5, 121.0); // Approx

    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      rainProbability: rainProbability,
      windSpeed: windSpeed,
      condition: condition,
      sunrise: sunTimes['sunrise']!,
      sunset: sunTimes['sunset']!,
      timestamp: DateTime.now(),
      locationName: displayName,
      dailyForecasts: dailyForecasts,
      apparentTemperature: apparentTemp,
      issueTime: issueTime,
    );
  }

  // Simple local Sunrise/Sunset calculation
  Map<String, DateTime> _calculateSunTimes(DateTime date, double lat, double lng) {
    // Julian Date
    final startOfYear = DateTime(date.year, 1, 1, 0, 0, 0);
    final dayOfYear = date.difference(startOfYear).inDays + 1;

    // Convert to radians
    final radLat = (pi / 180) * lat;

    // Declination of the Sun
    final declination = 0.4095 * sin(0.016906 * (dayOfYear - 80.089));

    // Equation of time (Simplified)
    double halfDayRad = 0;
    try {
      final val = -tan(radLat) * tan(declination);
      halfDayRad = acos(val.clamp(-1.0, 1.0));
    } catch (_) {
      halfDayRad = pi / 2; // Equator fallback
    }

    final halfDayHours = (halfDayRad * 180 / pi) / 15.0;

    // Solar Noon Approx
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
}
