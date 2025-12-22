import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/settings.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';
import '../data/models/gear_item.dart';
import '../data/models/weather_data.dart';
import '../data/models/poll.dart';

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
}
