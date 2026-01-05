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
import '../data/models/cwa/cwa_response_models.dart';
import '../services/cwa_api_factory.dart';

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

    // Determine if we should use CWA or GAS
    // Logic: If resolved location looks like a Township/District (contains 縣, 市, 區, 鄉, 鎮), try CWA.
    if (locationName.contains('縣') || locationName.contains('市') || locationName.contains('區') || locationName.contains('鄉') || locationName.contains('鎮')) {
      return _fetchCwaWeather(locationName);
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

      LogService.info('GAS API Status: ${response.statusCode}', source: 'WeatherService');

      if (response.statusCode == 200) {
        // Parse new GAS format: { code, data: { weather: [...] }, message }
        final bodyMsgs = utf8.decode(response.bodyBytes);
        LogService.debug('GAS API Response (Length: ${bodyMsgs.length})', source: 'WeatherService');
        
        final jsonMap = json.decode(bodyMsgs) as Map<String, dynamic>;

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

  Future<WeatherData> _fetchCwaWeather(String locationName) async {
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
    
    LogService.debug('CWA API URL: $url', source: 'WeatherService');

    try {
      final response = await http.get(Uri.parse(url));

      LogService.info('CWA API Status: ${response.statusCode}', source: 'WeatherService');

      if (response.statusCode == 200) {
         final bodyStr = utf8.decode(response.bodyBytes);
         LogService.debug('CWA API Response (Length: ${bodyStr.length})', source: 'WeatherService');
         
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
      LogService.error('CWA API Request failed: $e', source: 'WeatherService');
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
       LogService.warning('Location $queryName not found in response', source: 'WeatherService');
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

    final temp = double.tryParse(getCurrentValue('Temperature')) ?? 0.0;
    final hum = double.tryParse(getCurrentValue('RH')) ?? 0.0;
    final pop = int.tryParse(getCurrentValue('PoP')) ?? 0;
    final wx = getCurrentValue('Wx');
    final ws = double.tryParse(getCurrentValue('WS')) ?? 0.0;
    
    // Apparent Temp
    final maxAT = double.tryParse(getCurrentValue('MaxAT')) ?? 0.0;
    final minAT = double.tryParse(getCurrentValue('MinAT')) ?? 0.0;
    final apparentTemp = (maxAT != 0.0 || minAT != 0.0) ? (maxAT + minAT) / 2 : temp;

    // Issue Time (Current approx)
    final issueTime = DateTime.now(); 

    // 4. Build Daily Forecast
    final dailyMap = <String, Map<String, dynamic>>{};

    // Wx
    final wxSeries = getTimeSeries('Wx');
    for (var item in wxSeries) {
       final dateKey = "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
       dailyMap.putIfAbsent(dateKey, () => {'day': '', 'night': '', 'maxTemp': -100.0, 'minTemp': 100.0, 'pop': 0, 'maxAT': -100.0, 'minAT': 100.0});
       final val = item.getValue(['Weather', 'value']);
       if (item.startTime.hour >= 6 && item.startTime.hour < 18) {
         dailyMap[dateKey]!['day'] = val;
       } else {
         dailyMap[dateKey]!['night'] = val;
       }
    }

    void processMinMax(String concept, String mapKey, bool isMax) {
       final series = getTimeSeries(concept);
       final prefKey = CwaApiFactory.getElementValueKey(concept);
       for (var item in series) {
          final dateKey = "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
          if (!dailyMap.containsKey(dateKey)) continue;
          final val = double.tryParse(item.getValue([prefKey, 'value'])) ?? 0.0;
          if (isMax) {
             if (val > dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
          } else {
             if (val < dailyMap[dateKey]![mapKey]) dailyMap[dateKey]![mapKey] = val;
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
        final dateKey = "${item.startTime.year}-${item.startTime.month.toString().padLeft(2, '0')}-${item.startTime.day.toString().padLeft(2, '0')}";
        if (!dailyMap.containsKey(dateKey)) continue;
        final val = int.tryParse(item.getValue(['ProbabilityOfPrecipitation', 'value'])) ?? 0;
        if (val > dailyMap[dateKey]!['pop']) dailyMap[dateKey]!['pop'] = val;
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
      temperature: temp,
      humidity: hum,
      rainProbability: pop,
      windSpeed: ws,
      condition: wx,
      sunrise: sunTimes['sunrise']!,
      sunset: sunTimes['sunset']!,
      timestamp: DateTime.now(),
      locationName: displayName,
      dailyForecasts: dailyForecasts,
      apparentTemperature: apparentTemp,
      issueTime: issueTime,
    );
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
        LogService.info('Returning cached weather for $locationName (Freshness: ${DateTime.now().difference(cached.timestamp).inMinutes}m)', source: 'WeatherService');
        return cached;
      }
      if (isOffline && cached != null) {
        LogService.warning('Offline Mode: Returning cached (stale) weather for $locationName', source: 'WeatherService');
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

    // 3. Query params: locationName = Distroct (e.g. "信義區")

    // Actually _fetchCwaWeather takes locationName (e.g. "臺北市信義區").
    
    // Determine if we should use CWA or GAS
    // Logic: If resolved location looks like a Township/District (contains 縣, 市, 區, 鄉, 鎮), try CWA.
    if (locationName.contains('縣') || locationName.contains('市') || locationName.contains('區') || locationName.contains('鄉') || locationName.contains('鎮')) {
       try {
          final weather = await _fetchCwaWeather(locationName);
          _box?.put(dynamicCacheKey, weather);
          return weather;
       } catch (e) {
          LogService.error('Failed to fetch CWA weather for $locationName: $e', source: 'WeatherService');
          return null;
       }
    }
    
    // Fallback to what? GAS? The LocationResolver returns likely a precise location.
    // If it's a mountain, we might want GAS. But resolving coordinates usually yields township in current implementation.
    // So if it fails CWA, maybe returns null.
    // Assuming generic fallback logic isn't needed if we trust resolver.
    
    return null;
  }

}
