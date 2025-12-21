import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/weather_data.dart';
import '../services/log_service.dart';
import '../core/env_config.dart';
import '../core/constants.dart';



/// Weather Service
/// Data Sources:
/// 1. Hiking Weather: F-B0053-031 育樂天氣預報資料-登山一週日夜天氣預報(中文)
///    - URL: https://opendata.cwa.gov.tw/dataset/forecast/F-B0053-031 (Actually F-B0053-003 or 033 per usage)
///    - Accessed via Google Apps Script Proxy
/// 2. Township Weather: F-D0047-039 鄉鎮天氣預報-臺東縣未來1週天氣預報
///    - URL: https://opendata.cwa.gov.tw/dataset/all/F-D0047-039
///    - Accessed via Direct API (Mobile) or Netlify Proxy (Web)
class WeatherService {
  static const String _boxName = 'weather_cache';
  static const String _cacheKey = 'current_weather';
  static const String _apiKey = EnvConfig.cwaApiKey;
  String _targetLocation = '向陽山';

  Box<WeatherData>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<WeatherData>(_boxName);
    } else {
      _box = Hive.box<WeatherData>(_boxName);
    }
  }

  // Get cached weather. Only fetch new if forceRefresh is true or cache is missing.
  Future<WeatherData?> getWeather({bool forceRefresh = false, String locationName = '向陽山'}) async {
    final dynamicCacheKey = 'weather_$locationName';
    final cached = _box?.get(dynamicCacheKey);

    // If forcing refresh, fetch and update cache
    if (forceRefresh) {
      try {
        final weather = await fetchWeather(locationName: locationName);
        _box?.put(dynamicCacheKey, weather);
        return weather;
      } catch (e) {
        LogService.error('Failed to force refresh weather: $e', source: 'WeatherService');
        // If fetch fails, fall back to cache if available
        return cached;
      }
    }

    // If not forcing refresh, attempt to return cache (even if stale)
    if (cached != null) {
      if (cached.isStale) {
        // Option: We could auto-fetch background, but user requested Manual Only.
        // So we just return stale cache. UI can show "Data out of date" warning if needed.
        LogService.info('Returning stale cache for $locationName', source: 'WeatherService');
      }
      return cached;
    }

    // No cache and not force refresh -> Auto-fetch
    try {
       LogService.info('Cache miss for $locationName, fetching...', source: 'WeatherService');
       final weather = await fetchWeather(locationName: locationName);
       _box?.put(dynamicCacheKey, weather);
       return weather;
    } catch (e) {
       LogService.error('Failed to auto-fetch weather: $e', source: 'WeatherService');
       return null;
    }
  }

  Future<WeatherData> fetchWeather({String locationName = '向陽山'}) async {
    _targetLocation = locationName;

    // Check cache
    if (_box != null && _box!.containsKey(_cacheKey)) {
      final cached = _box!.get(_cacheKey) as WeatherData;
      if (!cached.isStale && cached.locationName == locationName) {
        return cached;
      }
    }

    if (locationName == '池上') {
      return _fetchTownshipWeather(locationName);
    } else {
      return _fetchHikingWeather(locationName);
    }
  }

  Future<WeatherData> _fetchHikingWeather(String locationName) async {
    // Call GAS API
    final baseUrl = EnvConfig.getApiUrl();
    final url = Uri.parse('$baseUrl?action=${ApiConfig.actionFetchWeather}');

    LogService.info('Fetching hiking weather from GAS for: $locationName', source: 'WeatherService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // GAS returns List<Map>
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        
        // --- OPTIMIZATION: Cache ALL locations from this response ---
        // 1. Identify all unique locations
        final uniqueLocations = jsonList.map((e) => e['Location'].toString()).toSet();
        LogService.info('GAS returned data for: ${uniqueLocations.join(', ')}', source: 'WeatherService');

        // 2. Parse and Cache each location
        for (var loc in uniqueLocations) {
           try {
             final weather = _parseGasWeatherData(jsonList, loc);
             final key = 'weather_$loc';
             _box?.put(key, weather);
             LogService.info('Cached bulk data for: $loc', source: 'WeatherService');
           } catch (e) {
             LogService.error('Failed to parse/cache bulk data for $loc: $e', source: 'WeatherService');
           }
        }

        // 3. Return the requested location's data (now in cache) or parse directly if something failed above
        // We will just return the parsed data for the requested location
        // If it was cached above, we could technically re-read it, but parsing again is fine/safer return.
        return _parseGasWeatherData(jsonList, locationName);

      } else {
        throw Exception('GAS API Error: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('GAS API Request failed: $e', source: 'WeatherService');
      rethrow;
    }
  }

  Future<WeatherData> _fetchTownshipWeather(String locationName) async {
    // F-D0047-039 (Taitung)
    final target = '池上鄉'; // Map '池上' to '池上鄉'

    final baseUrl = '${EnvConfig.cwaApiHost}/api/v1/rest/datastore/F-D0047-039';

    final url = Uri.parse(
      '$baseUrl?Authorization=$_apiKey&locationName=$target&elementName=MaxT,MinT,PoP12h,Wx,T,RH,WS,MaxAT,MinAT',
    );

    LogService.info('Fetching town weather: $target (Host: ${EnvConfig.cwaApiHost})', source: 'WeatherService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return _parseTownshipWeatherData(data, locationName, target);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('Town API Request failed: $e', source: 'WeatherService');
      rethrow;
    }
  }

  WeatherData _parseGasWeatherData(List<dynamic> list, String locationName) {
    // 1. Filter by Location
    final locationRows = list.where((item) => item['Location'] == locationName).toList();

    if (locationRows.isEmpty) {
      throw Exception('Location "$locationName" not found in GAS data');
    }

    // 2. Sort by StartTime
    locationRows.sort((a, b) => a['StartTime'].compareTo(b['StartTime']));

    // 3. Current Weather (First item covering current time, or just the first item)
    final current = locationRows.first;

    final temp = double.tryParse(current['T'].toString()) ?? 0.0;
    final humidity = double.tryParse(current['RH'].toString()) ?? 0.0;
    final pop = int.tryParse(current['PoP'].toString()) ?? 0;
    final windSpeed = double.tryParse(current['WS'].toString()) ?? 0.0;
    final wx = current['Wx'].toString();
    
    // Apparent Temp (Avg of Max/Min if available)
    final maxAT = double.tryParse(current['MaxAT'].toString()) ?? 0.0;
    final minAT = double.tryParse(current['MinAT'].toString()) ?? 0.0;
    final apparentTemp = (maxAT != 0.0 || minAT != 0.0) ? (maxAT + minAT) / 2 : temp;

    // IssueTime (if available)
    DateTime? issueTime;
    if (current.containsKey('IssueTime') && current['IssueTime'].toString().isNotEmpty) {
      try {
        issueTime = DateTime.parse(current['IssueTime'].toString());
      } catch (_) {}
    }

    // 4. Build Daily Forecast
    final dailyMap = <String, Map<String, dynamic>>{};

    for (var row in locationRows) {
      final start = DateTime.parse(row['StartTime']);
      final dateKey = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";

      dailyMap.putIfAbsent(
        dateKey,
        () => {
          'dayCondition': '', 'nightCondition': '', 
          'maxTemp': -100.0, 'minTemp': 100.0, 
          'maxAT': -100.0, 'minAT': 100.0,
          'pop': 0
        },
      );

      // Wx logic (Day 06-18, Night 18-06)
      final val = row['Wx'].toString();
      if (start.hour >= 6 && start.hour < 18) {
        if (dailyMap[dateKey]!['dayCondition'] == '') {
           dailyMap[dateKey]!['dayCondition'] = val;
        }
      } else {
        if (dailyMap[dateKey]!['nightCondition'] == '') {
           dailyMap[dateKey]!['nightCondition'] = val;
        }
      }

      // MaxT
      final maxT = double.tryParse(row['MaxT'].toString());
      if (maxT != null && maxT != 0.0) {
         if (maxT > dailyMap[dateKey]!['maxTemp']) dailyMap[dateKey]!['maxTemp'] = maxT;
      } else {
         final t = double.tryParse(row['T'].toString()) ?? 0.0;
         if (t > dailyMap[dateKey]!['maxTemp']) dailyMap[dateKey]!['maxTemp'] = t;
      }

      // MinT
      final minT = double.tryParse(row['MinT'].toString());
      if (minT != null && minT != 0.0) {
        if (minT < dailyMap[dateKey]!['minTemp']) dailyMap[dateKey]!['minTemp'] = minT;
      } else {
         final t = double.tryParse(row['T'].toString()) ?? 0.0;
         if (t < dailyMap[dateKey]!['minTemp']) dailyMap[dateKey]!['minTemp'] = t;
      }

      // MaxAT
      final mxAT = double.tryParse(row['MaxAT'].toString());
      if (mxAT != null && mxAT != 0.0) {
         if (mxAT > dailyMap[dateKey]!['maxAT']) dailyMap[dateKey]!['maxAT'] = mxAT;
      }

      // MinAT
      final mnAT = double.tryParse(row['MinAT'].toString());
      if (mnAT != null && mnAT != 0.0) {
        if (mnAT < dailyMap[dateKey]!['minAT']) dailyMap[dateKey]!['minAT'] = mnAT;
      }

      // PoP
      final p = int.tryParse(row['PoP'].toString()) ?? 0;
      if (p > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = p;
    }

    final dailyForecasts = dailyMap.entries.map((e) {
      final d = e.value;
      return DailyForecast(
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

    final now = DateTime.now();
    final sunTimes = _calculateSunTimes(now, 23.29, 121.03);

    return WeatherData(
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
      issueTime: issueTime,
    );
  }

  // Custom Parser for Township API (List-based ElementValue)
  WeatherData _parseTownshipWeatherData(Map<String, dynamic> json, String diffName, String targetLoc) {
    final records = json['records'];
    final locations = records['Locations'][0]['Location'] as List;
    final loc = locations.firstWhere((l) => l['LocationName'] == targetLoc);
    final elements = loc['WeatherElement'] as List;

    List<dynamic> getTimeList(String elName) {
      final e = elements.firstWhere((el) => el['ElementName'] == elName, orElse: () => null);
      return e?['Time'] ?? [];
    }

    String getValue(String elName, String key, {int index = 0}) {
      final list = getTimeList(elName);
      if (list.length <= index) return '';
      // ElementValue is List<Map>
      final evList = list[index]['ElementValue'] as List;
      if (evList.isEmpty) return '';
      final map = evList[0] as Map; // { "Temperature": "20" }
      return map[key]?.toString() ?? '';
    }

    // Current (Index 0)
    // F-D0047-039 uses T, RH, Wx, WS? Check URL params
    // I requested: MaxT,MinT,PoP12h,Wx,T,RH,WS
    // But T is '平均溫度'? No, in F-D0047 usually 'T' stands for '平均溫度' IF requested as 'T'.
    // But wait, the JSON output I saw earlier had '平均溫度'. So I should use Chinese names if I requested or default.
    // In fetch_township.py I requested EN names `MinT...`. The output `township_utf8.json` had "ElementName": "平均溫度".
    // CWA returns Chinese ElementName even if EN requested? Yes.
    // Mapping:
    // T -> 平均溫度
    // RH -> 平均相對濕度 (or 相對濕度?)
    // Wx -> 天氣現象

    final temp = double.tryParse(getValue('平均溫度', 'Temperature')) ?? 0.0;
    final hum = double.tryParse(getValue('平均相對濕度', 'RelativeHumidity')) ?? 0.0;
    final pop = int.tryParse(getValue('12小時降雨機率', 'ProbabilityOfPrecipitation')) ?? 0;
    final wx = getValue('天氣現象', 'Weather');
    final ws = double.tryParse(getValue('風速', 'WindSpeed')) ?? 0.0; // If available

    // Issue Time (Township)
    DateTime? issueTime;
    try {
       final locationsRoot = json['records']['Locations'][0];
       if (locationsRoot['DatasetInfo'] != null) {
          final info = locationsRoot['DatasetInfo'];
          if (info['IssueTime'] != null) {
             issueTime = DateTime.parse(info['IssueTime'].toString());
          }
       }
    } catch (_) {}

    // Apparent Temp
    final maxAT = double.tryParse(getValue('最高體感溫度', 'MaxApparentTemperature')) ?? 0.0;
    final minAT = double.tryParse(getValue('最低體感溫度', 'MinApparentTemperature')) ?? 0.0;
    final apparentTemp = (maxAT != 0.0 || minAT != 0.0) ? (maxAT + minAT) / 2 : temp;

    // Daily Forecast
    final dailyMap = <String, Map<String, dynamic>>{};

    // Wx
    final wxList = getTimeList('天氣現象');
    for (var item in wxList) {
      final start = DateTime.parse(item['StartTime']);
      final dateKey = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      dailyMap.putIfAbsent(
        dateKey,
        () => {
          'dayCondition': '', 'nightCondition': '', 
          'maxTemp': -100.0, 'minTemp': 100.0, 
          'maxAT': -100.0, 'minAT': 100.0,
          'pop': 0
        },
      );
      final val = item['ElementValue'][0]['Weather'].toString();
      if (start.hour >= 6 && start.hour < 18) {
        dailyMap[dateKey]!['dayCondition'] = val;
      } else {
        dailyMap[dateKey]!['nightCondition'] = val;
      }
    }

    void processTemp(String elName, String key, String mapKey, bool isMax) {
      final list = getTimeList(elName);
      for (var item in list) {
        final start = DateTime.parse(item['StartTime']);
        final dateKey =
            "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
        if (!dailyMap.containsKey(dateKey)) continue;
        final val = double.tryParse(item['ElementValue'][0][key].toString()) ?? 0.0;
        if (isMax) {
          if (val > dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
        } else {
          if (val < dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
        }
      }
    }

    processTemp('最高溫度', 'MaxTemperature', 'maxTemp', true);
    processTemp('最低溫度', 'MinTemperature', 'minTemp', false);
    processTemp('最高體感溫度', 'MaxApparentTemperature', 'maxAT', true);
    processTemp('最低體感溫度', 'MinApparentTemperature', 'minAT', false);

    // PoP
    final popList = getTimeList('12小時降雨機率');
    for (var item in popList) {
      final start = DateTime.parse(item['StartTime']);
      final dateKey = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      if (!dailyMap.containsKey(dateKey)) continue;
      final val = int.tryParse(item['ElementValue'][0]['ProbabilityOfPrecipitation'].toString()) ?? 0;
      if (val > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = val;
    }

    final dailyForecasts = dailyMap.entries.map((e) {
      final d = e.value;
      return DailyForecast(
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

    final now = DateTime.now();
    final sunTimes = _calculateSunTimes(now, 23.12, 121.22); // Chishang approx

    final weather = WeatherData(
      temperature: temp,
      humidity: hum,
      rainProbability: pop,
      windSpeed: ws,
      condition: wx,
      sunrise: sunTimes['sunrise']!,
      sunset: sunTimes['sunset']!,
      timestamp: DateTime.now(),
      locationName: diffName,
      dailyForecasts: dailyForecasts,
      apparentTemperature: apparentTemp,
      issueTime: issueTime,
    );

    return weather;
  }

  // Simple local Sunrise/Sunset calculation
  // Source: General algorithms approx (offline friendly)
  Map<String, DateTime> _calculateSunTimes(DateTime date, double lat, double lng) {
    // Julian Date
    final startOfYear = DateTime(date.year, 1, 1, 0, 0, 0);
    final dayOfYear = date.difference(startOfYear).inDays + 1;

    // Convert to radians
    final radLat = (pi / 180) * lat;

    // Declination of the Sun
    final declination = 0.4095 * sin(0.016906 * (dayOfYear - 80.089));

    // Equation of time (Simplified)
    // H = acos(-tan(lat) * tan(declination))

    double halfDayRad = 0;
    try {
      // -tan(lat)*tan(dec) must be between -1 and 1
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
