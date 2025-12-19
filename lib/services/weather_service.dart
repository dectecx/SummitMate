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
      'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-D0047-039';
  static const String _apiKey = EnvConfig.cwaApiKey;
  static const String _targetLocation = '海端鄉';

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
        '$_cwaApiUrl?Authorization=$_apiKey&format=JSON&locationName=$_targetLocation&elementName=PoP12h,T,AT,RH,WS,Wx');

    LogService.info('Fetching weather from CWA: $_targetLocation', source: 'WeatherService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final locations = json['records']['locations'][0]['location'];
      final locationData = locations.firstWhere(
        (loc) => loc['locationName'] == _targetLocation,
        orElse: () => throw Exception('Location not found'),
      );

      final elements = locationData['weatherElement'] as List;

      // Helper to find element value by time (nearest future)
      String getValue(String elementName) {
        final el = elements.firstWhere((e) => e['elementName'] == elementName);
        // data[0] is usually the next 12h block or current block
        // For accurate current, we take the first available forecast block.
        // F-D0047-039 blocks are usually 12h or 6h.
        // Let's just take the first time block [0]. 
        // For numeric values, it's inside 'elementValue'[0]['value'].
        // For Wx, it's 'elementValue'[0]['value'] (String) and [1] (Code).
        return el['time'][0]['elementValue'][0]['value'].toString();
      }

      final pop = int.tryParse(getValue('PoP12h')) ?? 0;
      final temp = double.tryParse(getValue('T')) ?? 0.0;
      final apparentTemp = double.tryParse(getValue('AT')) ?? 0.0; // Not used in model yet but good to have logic
      final humidity = double.tryParse(getValue('RH')) ?? 0.0;
      final windSpeed = double.tryParse(getValue('WS')) ?? 0.0;
      final condition = getValue('Wx');
      
      // Calculate sun times locally for Jiaming Lake (approx 23.29, 121.03)
      // This is dynamic based on DATE.
      final now = DateTime.now();
      final sunTimes = _calculateSunTimes(now, 23.29, 121.03);

      final weather = WeatherData(
        temperature: temp,
        humidity: humidity,
        rainProbability: pop,
        windSpeed: windSpeed,
        condition: condition,
        sunrise: sunTimes['sunrise']!,
        sunset: sunTimes['sunset']!,
        timestamp: DateTime.now(),
        locationName: _targetLocation,
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
    
    // Equation of time
    // Approximation for solar transit
    // This is a simplified version, sufficient for hiking reference (+/- 5~10 mins)
    // Detailed implementation is complex, for "Offline First" simple logic is better
    // Or we assume standard 6:00/18:00 adjusted by season.
    
    // Let's use a slightly better approx:
    // H = acos(-tan(lat) * tan(declination))
    // This gives half-day length in radians.
    
    double halfDayRad = 0;
    try {
       // -tan(lat)*tan(dec) must be between -1 and 1
       final val = -tan(radLat) * tan(declination);
       halfDayRad = acos(val.clamp(-1.0, 1.0));
    } catch (_) {
       halfDayRad = pi/2; // Equator fallback
    }
    
    final halfDayHours = (halfDayRad * 180 / pi) / 15.0;
    
    // Solar Noon (Approx 12:00 for Taiwan GMT+8, adjusted by Longitude)
    // Taiwan (120-122E) is close to 120E (GMT+8 standard).
    // 121.03 is +1.03 deg off = +4 mins.
    // So Solar Noon is approx 11:56 AM.
    // Let's simplify: Noon = 12:00 - (Longitude - 120) * 4min
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
