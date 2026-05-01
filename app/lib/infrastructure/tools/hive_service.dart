import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/infrastructure/adapters/app_theme_type_adapter.dart';
import '../../core/constants.dart';
import 'log_service.dart';
import '../../data/models/settings.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/gear_library_item.dart';
import '../../data/models/weather_data.dart';
import '../../data/models/poll.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/group_event.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../data/models/enums/group_event_application_status.dart';
import '../../data/models/enums/sync_status.dart';
import '../../data/models/enums/favorite_type.dart';
import '../../data/models/favorite.dart';

/// Hive 資料庫服務
/// 管理資料庫的初始化與生命週期，以及加密邏輯
class HiveService {
  final FlutterSecureStorage _secureStorage;
  static const _keyStorageKey = 'hive_encryption_key';

  bool _isInitialized = false;
  List<int>? _encryptionKey;

  /// 建構子
  ///
  /// [secureStorage] 可選的 SecureStorage 實例 (用於測試或自定義，預設為 [FlutterSecureStorage])
  HiveService({FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化 Hive
  Future<void> init() async {
    if (_isInitialized) return;

    // 初始化 Hive Flutter，並指定儲存在 'db' 子目錄中
    await Hive.initFlutter('db');

    // 初始化加密金鑰 (若為 Web 則跳過，因為 flutter_secure_storage 在 web 行為不同且通常不支援 Hive 非同步加密同樣方式)
    if (!kIsWeb) {
      _encryptionKey = await _checkAndGenerateEncryptionKey();
    }

    // 註冊 Adapters (由 build_runner 生成)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItineraryItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GearItemModelAdapter());
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
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(GearLibraryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(GroupEventAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(GroupEventApplicationAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(GroupEventStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(GroupEventApplicationStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(AppThemeTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(FavoriteAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(FavoriteTypeAdapter());
    }

    _isInitialized = true;

    // 預熱所有必要的 Box 以支援同步操作
    await openBox<Settings>(HiveBoxNames.settings);
    await openBox<TripModel>(HiveBoxNames.trips);
    await openBox<ItineraryItemModel>(HiveBoxNames.itinerary);
    await openBox<Message>(HiveBoxNames.messages);
    await openBox<GearItemModel>(HiveBoxNames.gear);
    await openBox<GearLibraryItem>(HiveBoxNames.gearLibrary);
    await openBox<Poll>(HiveBoxNames.polls);
    await openBox<GroupEvent>(HiveBoxNames.groupEvents);
    await openBox<GroupEventApplication>(HiveBoxNames.groupEventApplications);
    await openBox<WeatherData>(HiveBoxNames.weather);
    await openBox<Favorite>(HiveBoxNames.mountainFavorites);
    await openBox<Favorite>(HiveBoxNames.groupEventFavorites);
  }

  /// 取得或生成加密金鑰
  Future<Uint8List> _checkAndGenerateEncryptionKey() async {
    // 嘗試讀取現有金鑰
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    if (keyString != null) {
      final key = base64Url.decode(keyString);
      if (kDebugMode) {
        debugPrint('🔐 Hive Encryption Key (Loaded): $keyString');
      }
      return key;
    } else {
      // 生成新的 32-byte 金鑰
      final key = Hive.generateSecureKey();
      final encodedKey = base64Url.encode(key);
      await _secureStorage.write(key: _keyStorageKey, value: encodedKey);
      if (kDebugMode) {
        debugPrint('🔐 Hive Encryption Key (Generated): $encodedKey');
      }
      return Uint8List.fromList(key);
    }
  }

  /// 開啟 Box
  ///
  /// [boxName] Box 名稱
  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_isInitialized) await init();

    // 1. Web 或無金鑰環境：直接開啟明文 Box
    if (_encryptionKey == null) {
      return await Hive.openBox<T>(boxName);
    }

    // 2. 加密環境：直接開啟加密 Box
    try {
      return await Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(_encryptionKey!));
    } catch (e) {
      LogService.error('無法開啟加密 Box ($boxName): $e', source: 'HiveService');

      if (kDebugMode) {
        debugPrint('Debug: Box開啟失敗，嘗試刪除重建...');
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(_encryptionKey!));
      }
      rethrow;
    }
  }

  /// 取得已開啟的 Box (同步)
  ///
  /// [boxName] Box 名稱
  Box<T> getBox<T>(String boxName) {
    if (!_isInitialized) throw StateError('HiveService not initialized');
    return Hive.box<T>(boxName);
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

  /// 清除使用者資料 (登出時使用)
  Future<void> clearUserData() async {
    await clearSelectedData(
      clearTrips: true,
      clearItinerary: true,
      clearMessages: true,
      clearGear: true,
      clearGearLibrary: true,
      clearPolls: true,
      clearGroupEvents: true,
      clearWeather: true,
      clearSettings: true,
      clearLogs: false,
    );
  }

  /// 選擇性清除資料
  Future<void> clearSelectedData({
    bool clearTrips = false,
    bool clearItinerary = false,
    bool clearMessages = false,
    bool clearGear = false,
    bool clearGearLibrary = false,
    bool clearPolls = false,
    bool clearGroupEvents = false,
    bool clearWeather = false,
    bool clearSettings = false,
    bool clearLogs = false,
  }) async {
    await close();

    if (clearTrips) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.trips);
    }
    if (clearItinerary) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.itinerary);
    }
    if (clearMessages) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.messages);
    }

    if (clearGear) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.gear);
    }
    if (clearGearLibrary) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.gearLibrary);
    }
    if (clearPolls) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.polls);
    }
    if (clearGroupEvents) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.groupEvents);
      await Hive.deleteBoxFromDisk(HiveBoxNames.groupEventApplications);
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
  }
}
