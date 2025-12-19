import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/weather_data.dart';
import '../services/log_service.dart';
import '../core/env_config.dart';

class WeatherService {
  static const String _boxName = 'weather_cache';
  static const String _cacheKey = 'current_weather';
  static const String _cwaApiUrl =
      'https://opendata.cwa.gov.tw/fileapi/v1/opendataapi/F-B0053-033';
  static const String _apiKey = EnvConfig.cwaApiKey;
  static const String _targetLocation = '向陽山';

  Box<WeatherData>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<WeatherData>(_boxName);
    } else {
      _box = Hive.box<WeatherData>(_boxName);
    }
  }

  // Get cached weather or fetch new if stale
  Future<WeatherData?> getWeather({bool forceRefresh = false}) async {
    final cached = _box?.get(_cacheKey);

    if (cached != null && !cached.isStale && !forceRefresh) {
      return cached;
    }

    try {
      return await fetchWeather();
    } catch (e) {
      LogService.error('Failed to fetch weather: $e', source: 'WeatherService');
      // Return stale cache if fetch fails
      return cached;
    }
  }

  Future<WeatherData> fetchWeather() async {
    final url = Uri.parse(
        '$_cwaApiUrl?Authorization=$_apiKey&downloadType=WEB&format=JSON');

    LogService.info('Fetching hiking weather: $_targetLocation', source: 'WeatherService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Enforce UTF-8 decoding
        final data = json.decode(utf8.decode(response.bodyBytes));
        return _parseWeatherData(data);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('API Request failed: $e', source: 'WeatherService');
      rethrow;
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> json) {
    try {
      // 1. Traverse to Location List
      // Structure: cwaopendata -> Dataset -> Locations -> Location
      final root = json['cwaopendata'];
      if (root == null) throw Exception('Root cwaopendata missing');
      
      final dataset = root['Dataset'];
      if (dataset == null) throw Exception('Dataset missing');
      
      final locationsObj = dataset['Locations'];
      if (locationsObj == null) throw Exception('Locations missing');

      final locations = locationsObj['Location'] as List?;
      if (locations == null || locations.isEmpty) throw Exception('Location list empty');

      // 2. Find Target Location
      final locationData = locations.firstWhere(
        (loc) => loc['LocationName'] == _targetLocation,
        orElse: () => null,
      );

      if (locationData == null) {
        throw Exception('Location "$_targetLocation" not found');
      }

      final elements = locationData['WeatherElement'] as List?;
      if (elements == null) throw Exception('Weather elements missing');

      // Helper to extract Time list for a given element
      List<dynamic> getTimeList(String elementName) {
        final el = elements.firstWhere(
            (e) => e['ElementName'] == elementName, 
            orElse: () => null
        );
        return el?['Time'] as List? ?? [];
      }

      // Helper to get value key based on element name
      String getKeyForElement(String name) {
        if (name == '平均溫度') return 'Temperature';
        if (name == '平均相對濕度') return 'RelativeHumidity';
        if (name == '12小時降雨機率') return 'ProbabilityOfPrecipitation';
        if (name == '風速') return 'WindSpeed';
        if (name == '天氣現象') return 'Weather';
        if (name == '最高溫度') return 'MaxTemperature';
        if (name == '最低溫度') return 'MinTemperature';
        return 'value';
      }

      // 3. Extract Current Weather
      String getValue(String elemName, {int index = 0}) {
         final list = getTimeList(elemName);
         if (list.isEmpty || list.length <= index) return '';
         final valMap = list[index]['ElementValue']; // Is Map, not List
         if (valMap is! Map) return '';
         
         final key = getKeyForElement(elemName);
         return valMap[key]?.toString() ?? '';
      }
      
      final temp = double.tryParse(getValue('平均溫度')) ?? 0.0;
      final humidity = double.tryParse(getValue('平均相對濕度')) ?? 0.0;
      final pop = int.tryParse(getValue('12小時降雨機率')) ?? 0;
      final windSpeed = double.tryParse(getValue('風速')) ?? 0.0;
      final wx = getValue('天氣現象'); 

      // 4. Build 7-Day Forecast
      final dailyMap = <String, Map<String, dynamic>>{};

      // Process '天氣現象' (Wx)
      final wxList = getTimeList('天氣現象');
      for (var item in wxList) {
        final start = DateTime.parse(item['StartTime']);
        final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
        
        dailyMap.putIfAbsent(dateKey, () => {
          'dayCondition': '', 
          'nightCondition': '',
          'maxTemp': -100.0,
          'minTemp': 100.0,
          'pop': 0
        });

        final valMap = item['ElementValue'];
        final val = (valMap is Map ? valMap['Weather'] : '').toString();

        if (start.hour >= 6 && start.hour < 18) {
          dailyMap[dateKey]!['dayCondition'] = val;
        } else {
          dailyMap[dateKey]!['nightCondition'] = val;
        }
      }

      // Process MaxT/MinT
      void processTemp(String elName, String mapKey, bool isMax) {
        final list = getTimeList(elName);
        for (var item in list) {
          final start = DateTime.parse(item['StartTime']);
          final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
          if (!dailyMap.containsKey(dateKey)) continue;

          final valMap = item['ElementValue'];
          final key = getKeyForElement(elName);
          final valStr = (valMap is Map ? valMap[key] : '0').toString();
          final val = double.tryParse(valStr) ?? 0.0;

          if (isMax) {
             if (val > dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
          } else {
             if (val < dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
          }
        }
      }
      processTemp('最高溫度', 'maxTemp', true);
      processTemp('最低溫度', 'minTemp', false);

      // Process PoP
      final popList = getTimeList('12小時降雨機率');
      for (var item in popList) {
          final start = DateTime.parse(item['StartTime']);
          final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
          if (!dailyMap.containsKey(dateKey)) continue;
          
          final valMap = item['ElementValue'];
          final valStr = (valMap is Map ? valMap['ProbabilityOfPrecipitation'] : '0').toString(); // Space check?
          final val = (valStr == ' ' || valStr.isEmpty) ? 0 : (int.tryParse(valStr) ?? 0);
          
          if (val > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = val;
      }

      final dailyForecasts = dailyMap.entries.map((e) {
        final d = e.value;
        return DailyForecast(
          date: DateTime.parse(e.key),
          dayCondition: d['dayCondition'] == '' ? d['nightCondition'] : d['dayCondition'], // Fallback
          nightCondition: d['nightCondition'] == '' ? d['dayCondition'] : d['nightCondition'],
          maxTemp: d['maxTemp'] == -100.0 ? 0.0 : d['maxTemp'],
          minTemp: d['minTemp'] == 100.0 ? 0.0 : d['minTemp'],
          rainProbability: d['pop'],
        );
      }).toList();
      
      // Sort by date
      dailyForecasts.sort((a, b) => a.date.compareTo(b.date));

      // Calculate sun times locally (approx 23.29, 121.03 for Jiaming/Xiangyang)
      final now = DateTime.now();
      final sunTimes = _calculateSunTimes(now, 23.29, 121.03);

      final weather = WeatherData(
        temperature: temp,
        humidity: humidity,
        rainProbability: pop,
        windSpeed: windSpeed,
        condition: wx,
        sunrise: sunTimes['sunrise']!,
        sunset: sunTimes['sunset']!,
        timestamp: DateTime.now(),
        locationName: _targetLocation,
        dailyForecasts: dailyForecasts,
      );

      // Cache the result
      _box?.put(_cacheKey, weather);

      return weather;
    } catch (e) {
      LogService.error('Parse Error: $e', source: 'WeatherService');
      throw Exception('Failed to parse weather data');
    }
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
       halfDayRad = pi/2; // Equator fallback
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
    
    return {
      'sunrise': toTime(sunriseHour),
      'sunset': toTime(sunsetHour),
    };
  }
}
