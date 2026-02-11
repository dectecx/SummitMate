import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/weather_data.dart';
import '../tools/log_service.dart';
import '../tools/hive_service.dart';
import '../../core/env_config.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/repositories/interfaces/i_settings_repository.dart';

import '../../domain/interfaces/i_weather_service.dart';
import '../../core/location/i_location_resolver.dart';
import '../../data/cwa/cwa_weather_source.dart';

/// 天氣服務
///
/// 整合 CWA (氣象局) 與 GAS API 的天氣資料。
/// 支援：
/// - 本地快取 (Hive)
/// - 離線模式存取
/// - 透過 [ILocationResolver] 解析地點名稱
/// - 取得目前天氣與預報
class WeatherService implements IWeatherService {
  static const String _boxName = HiveBoxNames.weather;

  final ISettingsRepository _settingsRepo;
  Box<WeatherData>? _box;
  final ILocationResolver _locationResolver;
  final CwaWeatherSource _cwaSource;

  WeatherService({ISettingsRepository? settingsRepo, ILocationResolver? locationResolver, CwaWeatherSource? cwaSource})
    : _settingsRepo = settingsRepo ?? getIt<ISettingsRepository>(),
      _locationResolver = locationResolver ?? getIt<ILocationResolver>(),
      _cwaSource = cwaSource ?? CwaWeatherSource();

  /// 初始化天氣服務 (開啟 Hive Local Storage)
  @override
  Future<void> init() async {
    _box = await HiveService().openBox<WeatherData>(_boxName);
  }

  // 取得快取天氣。僅在 forceRefresh 為真或無快取時取得新資料。
  @override
  Future<WeatherData?> getWeatherByName(String locationName, {bool forceRefresh = false}) async {
    final dynamicCacheKey = 'weather_$locationName';
    final cached = _box?.get(dynamicCacheKey);
    final isOffline = _settingsRepo.getSettings().isOfflineMode;

    if (isOffline) {
      if (cached != null) {
        LogService.info('離線模式: 回傳 $locationName 的快取天氣 (Stale: ${cached.isStale})', source: 'WeatherService');
        return cached;
      }
      LogService.warning('離線模式: 無 $locationName 的快取資料', source: 'WeatherService');
      throw Exception('目前為離線模式且無快取資料');
    }

    // 若強制重新整理
    if (forceRefresh) {
      // 檢查快取是否夠新 (例如 < 5 分鐘) 以避免過於頻繁請求
      if (cached != null) {
        final now = DateTime.now();
        final diff = now.difference(cached.timestamp);
        if (diff.inMinutes < 5) {
          LogService.info('天氣快取夠新 (${diff.inMinutes}m 前), 忽略強制重新整理。', source: 'WeatherService');
          return cached;
        }
      }

      try {
        final weather = await _fetchWeatherInternal(locationName: locationName);
        _box?.put(dynamicCacheKey, weather);
        return weather;
      } catch (e) {
        LogService.error('強制重新整理天氣失敗: $e', source: 'WeatherService');
        // 若失敗，則退回使用快取 (若有)
        return cached;
      }
    }

    // 若非強制重新整理，嘗試回傳快取 (即使過期)
    if (cached != null) {
      if (cached.isStale) {
        // 選項: 我們可以在背景自動更新，但若用戶僅要求手動更新。
        // 所以這裡回傳過期快取。UI 可顯示「資料已過期」警告。
        LogService.info('回傳 $locationName 的過期快取', source: 'WeatherService');
      }
      return cached;
    }

    // 無快取且非強制重新整理 -> 自動取得
    try {
      LogService.info('$locationName 無快取，開始取得...', source: 'WeatherService');
      final weather = await _fetchWeatherInternal(locationName: locationName);
      _box?.put(dynamicCacheKey, weather);
      return weather;
    } catch (e) {
      LogService.error('自動取得天氣失敗: $e', source: 'WeatherService');
      return null;
    }
  }

  /// 內部取得方法
  Future<WeatherData> _fetchWeatherInternal({required String locationName}) async {
    final isOffline = _settingsRepo.getSettings().isOfflineMode;
    if (isOffline) {
      throw Exception('離線模式: 無法取得天氣');
    }

    // 檢查快取 (雙重檢查，但若邏輯在上方則此處冗餘)
    // 保持邏輯簡單: 這裡總是取得新資料。

    // 決定使用 CWA 或 GAS
    // 邏輯: 若地點名稱看似鄉鎮市區 (包含縣, 市, 區, 鄉, 鎮)，嘗試 CWA。
    if (locationName.contains('縣') ||
        locationName.contains('市') ||
        locationName.contains('區') ||
        locationName.contains('鄉') ||
        locationName.contains('鎮')) {
      return _fetchCwaWeather(locationName);
    } else {
      return _fetchHikingWeather(locationName);
    }
  }

  Future<WeatherData> _fetchHikingWeather(String locationName) async {
    // 呼叫 GAS API
    final baseUrl = EnvConfig.getApiUrl();
    final url = Uri.parse('$baseUrl?action=${ApiConfig.actionWeatherGet}');

    LogService.info('從 GAS 取得登山天氣: $locationName', source: 'WeatherService');

    try {
      final response = await http.get(url);

      LogService.info('GAS API 狀態: ${response.statusCode}', source: 'WeatherService');

      if (response.statusCode == 200) {
        // 解析新的 GAS 格式: { code, data: { weather: [...] }, message }
        final bodyMsgs = utf8.decode(response.bodyBytes);
        LogService.debug('GAS API 回應 (長度: ${bodyMsgs.length})', source: 'WeatherService');

        final jsonMap = json.decode(bodyMsgs) as Map<String, dynamic>;

        // 檢查格式
        if (jsonMap['code'] != '0000') {
          throw Exception('GAS API 錯誤: ${jsonMap['message']}');
        }
        // 從 data.weather 提取天氣陣列
        final data = jsonMap['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> jsonList = data['weather'] as List<dynamic>? ?? [];

        if (jsonList.isEmpty) {
          throw Exception('GAS 未回傳天氣資料');
        }

        return _parseAndCacheWeatherData(jsonList, locationName);
      } else {
        throw Exception('GAS API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('GAS API 請求失敗: $e', source: 'WeatherService');
      rethrow;
    }
  }

  /// 解析天氣資料並快取所有地點
  WeatherData _parseAndCacheWeatherData(List<dynamic> jsonList, String locationName) {
    // --- 最佳化: 快取此回應中的所有地點 ---
    // 1. 識別所有唯一地點
    final uniqueLocations = jsonList.map((e) => e['Location'].toString()).toSet();
    LogService.info('GAS 回傳資料地點: ${uniqueLocations.join(', ')}', source: 'WeatherService');

    // 2. 解析並快取每個地點
    for (var loc in uniqueLocations) {
      try {
        final weather = _parseGasWeatherData(jsonList, loc);
        final key = 'weather_$loc';
        _box?.put(key, weather);
        LogService.info('已快取整批資料: $loc', source: 'WeatherService');
      } catch (e) {
        LogService.error('解析/快取整批資料失敗 $loc: $e', source: 'WeatherService');
      }
    }

    // 3. 回傳請求地點的資料
    return _parseGasWeatherData(jsonList, locationName);
  }

  Future<WeatherData> _fetchCwaWeather(String locationName) async {
    LogService.info('從 CWA 取得城鎮天氣: $locationName', source: 'WeatherService');
    try {
      return await _cwaSource.getWeather(locationName);
    } catch (e) {
      LogService.error('CWA Source 取得失敗: $e', source: 'WeatherService');
      rethrow;
    }
  }

  WeatherData _parseGasWeatherData(List<dynamic> list, String locationName) {
    // 1. 依地點過濾
    final locationRows = list.where((item) => item['Location'] == locationName).toList();

    if (locationRows.isEmpty) {
      throw Exception('GAS 資料中找不到地點 "$locationName"');
    }

    // 2. 依 StartTime 排序
    locationRows.sort((a, b) => a['StartTime'].compareTo(b['StartTime']));

    // 3. 目前天氣 (涵蓋目前時間的第一筆，或直接取第一筆)
    final current = locationRows.first;

    final temp = double.tryParse(current['T'].toString()) ?? 0.0;
    final humidity = double.tryParse(current['RH'].toString()) ?? 0.0;
    final pop = int.tryParse(current['PoP'].toString()) ?? 0;
    final windSpeed = double.tryParse(current['WS'].toString()) ?? 0.0;
    final wx = current['Wx'].toString();

    // 體感溫度 (Apparent Temp) (若有 Max/Min 則取平均)
    final maxAT = double.tryParse(current['MaxAT'].toString()) ?? 0.0;
    final minAT = double.tryParse(current['MinAT'].toString()) ?? 0.0;
    final apparentTemp = (maxAT != 0.0 || minAT != 0.0) ? (maxAT + minAT) / 2 : temp;

    // 發布時間 (IssueTime) (若有)
    DateTime? issueTime;
    if (current.containsKey('IssueTime') && current['IssueTime'].toString().isNotEmpty) {
      try {
        issueTime = DateTime.parse(current['IssueTime'].toString());
      } catch (_) {}
    }

    // 4. 建立每日預報 (Daily Forecast)
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

      // Wx 自訂邏輯 (白天 06-18, 晚上 18-06)
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

  // 簡易本地日出日落計算
  // 來源: 通用演算法近似值 (便於離線使用)
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
  Future<WeatherData?> getWeatherByLocation(double lat, double lon, {bool forceRefresh = false}) async {
    final isOffline = _settingsRepo.getSettings().isOfflineMode;

    // 解析地點
    final location = await _locationResolver.resolve(lat, lon);
    if (location == null) {
      LogService.warning('無法解析座標 $lat, $lon', source: 'WeatherService');
      return null;
    }

    final locationName = location.name;
    final dynamicCacheKey = 'weather_$locationName';

    // 檢查快取
    if (!forceRefresh && _box != null && _box!.containsKey(dynamicCacheKey)) {
      final cached = _box!.get(dynamicCacheKey);
      if (cached != null && !cached.isStale) {
        LogService.info(
          '回傳 $locationName 的快取天氣 (新鮮度: ${DateTime.now().difference(cached.timestamp).inMinutes}m)',
          source: 'WeatherService',
        );
        return cached;
      }
      if (isOffline && cached != null) {
        LogService.warning('離線模式: 回傳 $locationName 的過期快取', source: 'WeatherService');
        return cached;
      }
    }

    if (isOffline) {
      LogService.warning('$locationName 無快取且為離線模式', source: 'WeatherService');
      return null;
    }

    // 決定使用 CWA 或 GAS
    // 邏輯: 若地點名稱看似鄉鎮市區 (包含縣, 市, 區, 鄉, 鎮)，嘗試 CWA。
    if (locationName.contains('縣') ||
        locationName.contains('市') ||
        locationName.contains('區') ||
        locationName.contains('鄉') ||
        locationName.contains('鎮')) {
      try {
        final weather = await _fetchCwaWeather(locationName);
        _box?.put(dynamicCacheKey, weather);
        return weather;
      } catch (e) {
        LogService.error('CWA 天氣取得失敗 $locationName: $e', source: 'WeatherService');
        return null;
      }
    }

    // 若解析器回傳其他格式的後備方案 ??
    return null;
  }
}
