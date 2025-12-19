import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../data/models/weather_data.dart';
import '../services/log_service.dart';
import '../core/env_config.dart';

class WeatherService {
  static const String _boxName = 'weather_cache';
  static const String _cacheKey = 'current_weather';
  static const String _cwaApiUrl =
      'https://opendata.cwa.gov.tw/fileapi/v1/opendataapi/F-B0053-033';
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

  // Get cached weather or fetch new if stale
  Future<WeatherData?> getWeather({bool forceRefresh = false, String locationName = '向陽山'}) async {
    final dynamicCacheKey = 'weather_$locationName';
    final cached = _box?.get(dynamicCacheKey);

    if (cached != null && !cached.isStale && !forceRefresh) {
      return cached;
    }

    try {
      final weather = await fetchWeather(locationName: locationName);
      // Cache the result with dynamic key
      _box?.put(dynamicCacheKey, weather);
      return weather;
    } catch (e) {
      LogService.error('Failed to fetch weather: $e', source: 'WeatherService');
      // Return stale cache if fetch fails
      return cached;
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
    String baseUrl = _cwaApiUrl;
    if (kIsWeb) {
      // Use using netlify proxy
      baseUrl = '/cwa-proxy/fileapi/v1/opendataapi/F-B0053-033';
    }

    final url = Uri.parse(
        '$baseUrl?Authorization=$_apiKey&downloadType=WEB&format=JSON');

    LogService.info('Fetching hiking weather: $locationName (Web: $kIsWeb)', source: 'WeatherService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return _parseHikingWeatherData(data, locationName);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('Hiking API Request failed: $e', source: 'WeatherService');
      rethrow;
    }
  }

  Future<WeatherData> _fetchTownshipWeather(String locationName) async {
    // F-D0047-039 (Taitung)
    final target = '池上鄉'; // Map '池上' to '池上鄉'
    
    String baseUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-D0047-039';
    if (kIsWeb) {
       baseUrl = '/cwa-proxy/api/v1/rest/datastore/F-D0047-039';
    }

    final url = Uri.parse(
        '$baseUrl?Authorization=$_apiKey&locationName=$target&elementName=MaxT,MinT,PoP12h,Wx,T,RH,WS');
    
    LogService.info('Fetching town weather: $target (Web: $kIsWeb)', source: 'WeatherService');

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

  WeatherData _parseHikingWeatherData(Map<String, dynamic> json, String locationName) {
      final root = json['cwaopendata'];
      if (root == null) throw Exception('Root cwaopendata missing');
      
      final dataset = root['Dataset'];
      final locationsObj = dataset['Locations'];
      final locations = locationsObj['Location'] as List?;
      if (locations == null) throw Exception('Location list empty');

      final locationData = locations.firstWhere(
        (loc) => loc['LocationName'] == locationName,
        orElse: () => null,
      );

      if (locationData == null) {
        throw Exception('Hiking Location "$locationName" not found');
      }

      final elements = locationData['WeatherElement'] as List?;
      if (elements == null) throw Exception('Weather elements missing');

      // Helper to extract Time list
      List<dynamic> getTimeList(String elementName) {
        final el = elements.firstWhere(
            (e) => e['ElementName'] == elementName, 
            orElse: () => null
        );
        return el?['Time'] as List? ?? [];
      }

      // Helper to get value key
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

      String getValue(String elemName, {int index = 0}) {
         final list = getTimeList(elemName);
         if (list.isEmpty || list.length <= index) return '';
         final valMap = list[index]['ElementValue'];
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

      final popList = getTimeList('12小時降雨機率');
      for (var item in popList) {
          final start = DateTime.parse(item['StartTime']);
          final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
          if (!dailyMap.containsKey(dateKey)) continue;
          
          final valMap = item['ElementValue'];
          final valStr = (valMap is Map ? valMap['ProbabilityOfPrecipitation'] : '0').toString();
          final val = (valStr == ' ' || valStr.isEmpty) ? 0 : (int.tryParse(valStr) ?? 0);
          
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
        );
      }).toList();
      
      dailyForecasts.sort((a, b) => a.date.compareTo(b.date));

      final now = DateTime.now();
      final sunTimes = _calculateSunTimes(now, 23.29, 121.03); // Xiangyang approx

      final weather = WeatherData(
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
      );

      return weather;
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

     String getValue(String elName, String key, {int index=0}) {
       final list = getTimeList(elName);
       if(list.length <= index) return '';
       // ElementValue is List<Map>
       final evList = list[index]['ElementValue'] as List;
       if(evList.isEmpty) return '';
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

     // Daily Forecast
      final dailyMap = <String, Map<String, dynamic>>{};

      // Wx
      final wxList = getTimeList('天氣現象');
      for(var item in wxList) {
         final start = DateTime.parse(item['StartTime']);
         final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
         dailyMap.putIfAbsent(dateKey, () => {
          'dayCondition': '', 'nightCondition': '', 'maxTemp': -100.0, 'minTemp': 100.0, 'pop': 0
         });
         final val = item['ElementValue'][0]['Weather'].toString();
         if (start.hour >= 6 && start.hour < 18) {
            dailyMap[dateKey]!['dayCondition'] = val;
         } else {
            dailyMap[dateKey]!['nightCondition'] = val;
         }
      }

      void processTemp(String elName, String key, String mapKey, bool isMax) {
         final list = getTimeList(elName);
         for(var item in list) {
            final start = DateTime.parse(item['StartTime']);
            final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
            if(!dailyMap.containsKey(dateKey)) continue;
            final val = double.tryParse(item['ElementValue'][0][key].toString()) ?? 0.0;
            if(isMax) {
               if(val > dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
            } else {
               if(val < dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
            }
         }
      }
      processTemp('最高溫度', 'MaxTemperature', 'maxTemp', true);
      processTemp('最低溫度', 'MinTemperature', 'minTemp', false);

      // PoP
      final popList = getTimeList('12小時降雨機率');
       for(var item in popList) {
            final start = DateTime.parse(item['StartTime']);
            final dateKey = "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}";
            if(!dailyMap.containsKey(dateKey)) continue;
            final val = int.tryParse(item['ElementValue'][0]['ProbabilityOfPrecipitation'].toString()) ?? 0;
            if(val > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = val;
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
        );
      }).toList();
      dailyForecasts.sort((a,b)=>a.date.compareTo(b.date));
     
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
