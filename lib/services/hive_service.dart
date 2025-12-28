import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../data/models/settings.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';
import '../data/models/gear_item.dart';
import '../data/models/gear_library_item.dart';
import '../data/models/weather_data.dart';
import '../data/models/poll.dart';
import '../data/models/trip.dart';

/// Hive 資料庫服務
/// 管理資料庫的初始化與生命週期
class HiveService {
  static HiveService? _instance;
  bool _isInitialized = false;

  /// 單例模式
  factory HiveService() {
    _instance ??= HiveService._internal();
    return _instance!;
  }

  HiveService._internal();

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化 Hive
  Future<void> init() async {
    if (_isInitialized) return;

    // 初始化 Hive Flutter
    await Hive.initFlutter();

    // 註冊 Adapters (由 build_runner 生成)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItineraryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GearItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WeatherDataAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DailyForecastAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PollAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PollOptionAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(GearLibraryItemAdapter());
    }

    _isInitialized = true;
  }

  /// 關閉所有 Box
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  /// 清除所有資料 (Debug 用途)
  Future<void> clearAllData() async {
    await Hive.deleteFromDisk();
  }

  /// 選擇性清除資料
  /// 使用 deleteBoxFromDisk 避免 type conflict
  Future<void> clearSelectedData({
    bool clearItinerary = false,
    bool clearMessages = false,
    bool clearGear = false,
    bool clearWeather = false,
    bool clearSettings = false,
    bool clearLogs = false,
    bool clearPolls = false,
  }) async {
    // 先關閉所有 box 以避免 type conflict
    await Hive.close();

    if (clearItinerary) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.itinerary);
    }
    if (clearMessages) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.messages);
    }
    if (clearGear) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.gear);
    }
    if (clearWeather) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.weather);
    }
    if (clearSettings) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.username);
    }
    if (clearLogs) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.logs);
    }
    if (clearPolls) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.polls);
    }
  }
}
