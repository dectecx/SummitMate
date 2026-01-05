import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/weather_data.dart';
import '../services/log_service.dart';
import '../core/env_config.dart';
import '../core/constants.dart';
import '../core/di.dart';
import '../data/repositories/interfaces/i_settings_repository.dart';

import 'interfaces/i_weather_service.dart';
import '../core/location/i_location_resolver.dart';

class WeatherService implements IWeatherService {
  static const String _boxName = HiveBoxNames.weather;
  static const String _cacheKey = 'current_weather';
  static const String _apiKey = EnvConfig.cwaApiKey;

  final ISettingsRepository _settingsRepo;
  Box<WeatherData>? _box;
  final ILocationResolver _locationResolver;

  WeatherService({ISettingsRepository? settingsRepo, ILocationResolver? locationResolver})
    : _settingsRepo = settingsRepo ?? getIt<ISettingsRepository>(),
      _locationResolver = locationResolver ?? getIt<ILocationResolver>();

  @override
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
    final isOffline = _settingsRepo.getSettings().isOfflineMode;

    if (isOffline) {
      if (cached != null) {
        LogService.info(
          'Offline Mode: Returning cached weather for $locationName (Stale: ${cached.isStale})',
          source: 'WeatherService',
        );
        return cached;
      }
      LogService.warning('Offline Mode: No cache for $locationName', source: 'WeatherService');
      throw Exception('目前為離線模式且無快取資料');
    }

    // If forcing refresh
    if (forceRefresh) {
      // Check if cache is fresh enough (e.g. < 5 minutes) to avoid spamming
      if (cached != null) {
        final now = DateTime.now();
        final diff = now.difference(cached.timestamp);
        if (diff.inMinutes < 5) {
          LogService.info(
            'Weather cache is fresh (${diff.inMinutes}m ago), ignoring force refresh.',
            source: 'WeatherService',
          );
          return cached;
        }
      }

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

  @override
  Future<WeatherData> fetchWeather({String locationName = '向陽山'}) async {
    final isOffline = _settingsRepo.getSettings().isOfflineMode;
    if (isOffline) {
      throw Exception('Offline Mode: Cannot fetch weather');
    }

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
        // Parse new GAS format: { code, data: { weather: [...] }, message }
        final jsonMap = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // Check if it's the new format
        if (jsonMap['code'] != '0000') {
          throw Exception('GAS API Error: ${jsonMap['message']}');
        }
        // Extract weather array from data.weather
        final data = jsonMap['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> jsonList = data['weather'] as List<dynamic>? ?? [];

        if (jsonList.isEmpty) {
          throw Exception('No weather data returned from GAS');
        }

        return _parseAndCacheWeatherData(jsonList, locationName);
      } else {
        throw Exception('GAS API Error: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('GAS API Request failed: $e', source: 'WeatherService');
      rethrow;
    }
  }

  /// Parse weather data and cache all locations
  WeatherData _parseAndCacheWeatherData(List<dynamic> jsonList, String locationName) {
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

    // 3. Return the requested location's data
    return _parseGasWeatherData(jsonList, locationName);
  }

  Future<WeatherData> _fetchTownshipWeather(String locationName) async {
    // F-D0047-039 (Taitung)
    final target = '池上鄉'; // Map '池上' to '池上鄉'

    final baseUrl = '${EnvConfig.cwaApiHost}/api/v1/rest/datastore/${CwaDataId.townshipForecastTaitung}';

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
          'dayCondition': '',
          'nightCondition': '',
          'maxTemp': -100.0,
          'minTemp': 100.0,
          'maxAT': -100.0,
          'minAT': 100.0,
          'pop': 0,
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
          'dayCondition': '',
          'nightCondition': '',
          'maxTemp': -100.0,
          'minTemp': 100.0,
          'maxAT': -100.0,
          'minAT': 100.0,
          'pop': 0,
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

  @override
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    final isOffline = _settingsRepo.getSettings().isOfflineMode;

    // Resolve location
    final location = await _locationResolver.resolve(lat, lon);
    if (location == null) {
      LogService.warning('Could not resolve location for $lat, $lon', source: 'WeatherService');
      return null;
    }

    final locationName = location.name;
    final dynamicCacheKey = 'weather_$locationName';

    // Check cache
    if (_box != null && _box!.containsKey(dynamicCacheKey)) {
      final cached = _box!.get(dynamicCacheKey);
      if (cached != null && !cached.isStale) {
        return cached;
      }
      if (isOffline && cached != null) {
        // In offline mode, return cached data even if stale
        return cached;
      }
    }

    if (isOffline) {
      LogService.warning('Offline and no cache for $locationName', source: 'WeatherService');
      return null;
    }

    // Fetch from CWA
    // Logic:
    // 1. Identify City/County (e.g. "臺北市" or "南投縣")
    // 2. Lookup Data ID (e.g. F-D0047-063)
    // 3. Query params: locationName = Distroct (e.g. "信義區")

    String queryName = locationName;
    String countyName = '';
    String dataId = CwaDataId.townshipForecast; // Default fallback to "All"

    if (locationName.length >= 3) {
      // Extract county (first 3 chars)
      countyName = locationName.substring(0, 3);
      if (CwaDataId.countyForecastIds.containsKey(countyName)) {
        dataId = CwaDataId.countyForecastIds[countyName]!;
        // Remove county prefix for query
        queryName = locationName.substring(3);
        LogService.info(
          'Mapped $countyName to DataID: $dataId. Querying district: $queryName',
          source: 'WeatherService',
        );
      } else {
        LogService.warning(
          'County "$countyName" not found in map. Falling back to global ID ($dataId)',
          source: 'WeatherService',
        );
        // If fallback to global, queryName might need to be full name or short name depending on global API.
        // Usually global API expects "信義區" if you query "臺北市" dataId? No, global API contains ALL.
        // Let's stick to short name query for now as it worked partially before.
        if (locationName.length > 3) queryName = locationName.substring(3);
      }
    }

    final url =
        '${EnvConfig.cwaApiHost}/api/v1/rest/datastore/$dataId?Authorization=$_apiKey&locationName=$queryName&elementName=PoP12h,T,Wx,MinT,MaxT';

    LogService.debug('CWA API URL: $url', source: 'WeatherService');

    try {
      final response = await http.get(Uri.parse(url));

      LogService.debug('CWA API Status: ${response.statusCode}', source: 'WeatherService');

      if (response.statusCode == 200) {
        // Log first 200 chars to debug
        final bodyStart = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
        LogService.debug('CWA API Body (Partial): $bodyStart', source: 'WeatherService');

        final jsonMap = jsonDecode(response.body);
        if (jsonMap['success'] == 'true') {
          // We pass the Original Name (displayName) and the queryName used
          final weather = _parseCwaResponse(jsonMap, locationName, queryName);
          if (weather != null) {
            _box?.put(dynamicCacheKey, weather);
            return weather;
          } else {
            LogService.error('Parsed weather is null for $locationName', source: 'WeatherService');
          }
        } else {
          LogService.error('CWA API Result Error: ${jsonMap['result']}', source: 'WeatherService');
        }
      } else {
        LogService.error('CWA API Failed: ${response.statusCode} | ${response.body}', source: 'WeatherService');
        // Specific hint for user debugging
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('CWA API Auth Failed. Check API Key.');
        }
        throw Exception('CWA API Failed with status ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('Exception fetching weather for $locationName: $e', source: 'WeatherService');
      // Rethrow to let UI show the error
      rethrow;
    }

    return null;
  }

  WeatherData? _parseCwaResponse(Map<String, dynamic> json, String displayName, String queryName) {
    try {
      if (!json.containsKey('records')) {
        LogService.error('JSON missing "records" key', source: 'WeatherService');
        LogService.debug('JSON Keys: ${json.keys.toList()}', source: 'WeatherService');
        return null;
      }

      final records = json['records'];
      // Handle Case Sensitivity: "Locations" vs "locations"
      var locationsRaw;
      if (records is Map) {
        if (records.containsKey('Locations')) {
          locationsRaw = records['Locations'];
        } else if (records.containsKey('locations')) {
          locationsRaw = records['locations'];
        } else {
          LogService.error('Records missing "Locations" or "locations" key', source: 'WeatherService');
          LogService.debug('Records Keys: ${records.keys.toList()}', source: 'WeatherService');
          return null;
        }
      } else {
        LogService.error('Records is not a Map', source: 'WeatherService');
        return null;
      }

      final locationsList = locationsRaw[0]['Location'] ?? locationsRaw[0]['location'];
      if (locationsList == null || (locationsList as List).isEmpty) {
        LogService.warning('No location list found (checked Location/location)', source: 'WeatherService');
        return null;
      }

      // Match against queryName (short)
      var location = locationsList.firstWhere(
        (loc) => loc['locationName'] == queryName || loc['LocationName'] == queryName,
        orElse: () => null,
      );

      // Fallback: Try match full name just in case
      if (location == null) {
        location = locationsList.firstWhere(
          (loc) => loc['locationName'] == displayName || loc['LocationName'] == displayName,
          orElse: () => null,
        );
      }

      if (location == null) {
        LogService.warning('Location "$queryName" (or "$displayName") not found in response', source: 'WeatherService');
        // Log available names for debugging
        final names = locationsList.map((e) => e['locationName'] ?? e['LocationName']).toList();
        LogService.debug('Available locations: $names', source: 'WeatherService');
        return null;
      }

      final elements = (location['weatherElement'] ?? location['WeatherElement']) as List;

      // Helper to handle multiple potential ElementNames (e.g. "T" vs "平均溫度")
      List<dynamic> getElementValues(List<String> possibleNames) {
        final el = elements.firstWhere(
          (e) => possibleNames.contains(e['elementName']) || possibleNames.contains(e['ElementName']),
          orElse: () => null,
        );
        if (el == null) return [];
        return el['time'] ?? el['Time'] ?? [];
      }

      final pops = getElementValues(['PoP12h', '12小時降雨機率']);
      final temps = getElementValues(['T', '平均溫度']);
      final wxs = getElementValues(['Wx', '天氣現象']);
      final minTs = getElementValues(['MinT', '最低溫度']);
      final maxTs = getElementValues(['MaxT', '最高溫度']);

      if (temps.isEmpty) {
        LogService.warning('No temperature data found (checked T, 平均溫度)', source: 'WeatherService');
        // Log available elements for debugging
        final available = elements.map((e) => e['elementName'] ?? e['ElementName']).toList();
        LogService.debug('Available elements: $available', source: 'WeatherService');
        return null;
      }

      // Helper to extract value from element structure
      // Structure A: { startTime:..., elementValue: [{ value: "20", measures: "C" }] }
      // Structure B: { StartTime:..., ElementValue: [{ ProbabilityOfPrecipitation: "20" }] } (Township specific sometimes)
      String extractVal(dynamic item, String keyPreference) {
        final ev = item['elementValue'] ?? item['ElementValue'];
        if (ev is List && ev.isNotEmpty) {
          final first = ev[0];
          // If simple structure with 'value'
          if (first is Map && first.containsKey('value')) return first['value'].toString();
          // If simple structure with 'Temperature', 'Weather', etc.
          if (first is Map && first.containsKey(keyPreference)) return first[keyPreference].toString();
          // Fallback: return first value
          if (first is Map && first.values.isNotEmpty) return first.values.first.toString();
        }
        return '';
      }

      // Current (Most recent forecast)
      // Note: "T" element typically has "Temperature" key if structure B, or "value" if structure A
      final currentT = double.tryParse(extractVal(temps[0], 'Temperature')) ?? 0.0;
      final currentWx = wxs.isNotEmpty ? extractVal(wxs[0], 'Weather') : '';
      final currentPop = pops.isNotEmpty ? int.tryParse(extractVal(pops[0], 'ProbabilityOfPrecipitation')) ?? 0 : 0;

      // Map builder for Daily Forecasts
      final builderMap = <String, Map<String, dynamic>>{};

      void updateBuilder(List<dynamic> list, String valKey, Function(Map<String, dynamic>, dynamic, bool) updater) {
        for (var item in list) {
          final st = item['startTime'] ?? item['StartTime'];
          final start = DateTime.parse(st);
          final dateKey =
              "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";

          builderMap.putIfAbsent(
            dateKey,
            () => {'dayCondition': '', 'nightCondition': '', 'maxTemp': -100.0, 'minTemp': 100.0, 'pop': 0},
          );
          // 簡單判斷：6:00~18:00 為白天
          updater(builderMap[dateKey]!, item, start.hour >= 6 && start.hour < 18);
        }
      }

      updateBuilder(wxs, 'Weather', (map, item, isDay) {
        final val = extractVal(item, 'Weather'); // Wx usually has 'value' or 'Weather' depending on API
        if (isDay)
          map['dayCondition'] = val;
        else
          map['nightCondition'] = val;
      });

      updateBuilder(maxTs, 'MaxTemperature', (map, item, isDay) {
        final val = double.tryParse(extractVal(item, 'MaxTemperature')) ?? 0.0;
        if (val > map['maxTemp']) map['maxTemp'] = val;
      });

      updateBuilder(minTs, 'MinTemperature', (map, item, isDay) {
        final val = double.tryParse(extractVal(item, 'MinTemperature')) ?? 0.0;
        if (val < map['minTemp']) map['minTemp'] = val;
      });

      updateBuilder(pops, 'ProbabilityOfPrecipitation', (map, item, isDay) {
        final val = int.tryParse(extractVal(item, 'ProbabilityOfPrecipitation')) ?? 0;
        if (val > map['pop']) map['pop'] = val;
      });

      final dailyForecasts = builderMap.entries.map((e) {
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

      return WeatherData(
        locationName: displayName,
        temperature: currentT,
        humidity: 0.0, // Not available in this subset
        rainProbability: currentPop,
        windSpeed: 0.0, // Not fetched
        condition: currentWx,
        sunrise: DateTime.now(), // Not fetched
        sunset: DateTime.now(), // Not fetched
        timestamp: DateTime.now(),
        dailyForecasts: dailyForecasts,
      );
    } catch (e, stack) {
      LogService.error('Error parsing CWA data logic: $e', source: 'WeatherService');
      LogService.debug('Stack trace: $stack', source: 'WeatherService');
      return null;
    }
  }
}
