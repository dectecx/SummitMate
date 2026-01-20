import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import 'log_service.dart';
import '../../data/models/settings.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/gear_library_item.dart';
import '../../data/models/weather_data.dart';
import '../../data/models/poll.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/group_event.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../data/models/enums/group_event_application_status.dart';
import '../../data/models/enums/sync_status.dart';

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

    // 初始化 Hive Flutter
    await Hive.initFlutter();

    // 初始化加密金鑰 (若為 Web 則跳過，因為 flutter_secure_storage 在 web 行為不同且通常不支援 Hive 非同步加密同樣方式)
    if (!kIsWeb) {
      _encryptionKey = await _checkAndGenerateEncryptionKey();
    }

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
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(UserProfileAdapter());
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

    _isInitialized = true;
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
    // 由於 openBox 是 idempotent (冪等) 的，Hive 會自動檢查是否已開啟。
    // 如果已開啟，它會直接回傳 instance，不會重複 IO 操作。
    // 因此不需要寫 if (!Hive.isBoxOpen) ...
    try {
      return await Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(_encryptionKey!));
    } catch (e) {
      // 若因為金鑰不匹配或檔案損壞導致無法開啟，這裡選擇拋出異常，
      // 而不是自動刪除 (為了避免意外資料遺失)。
      // 若確定是全新開發環境，遇到錯誤建議手動解除安裝 App 重裝。
      LogService.error('無法開啟加密 Box ($boxName): $e', source: 'HiveService');

      // 除錯用：若是開發階段遇到 Key 不合，可以考慮在這裡清空重建，
      // 但正式版不建議。
      if (kDebugMode) {
        debugPrint('Debug: Box開啟失敗，嘗試刪除重建...');
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(_encryptionKey!));
      }
      rethrow;
    }
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
  /// 保留 logs 以便除錯，清除其他所有使用者資料
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
      clearLogs: false, // 保留 logs
    );
  }

  /// 選擇性清除資料
  /// 使用 deleteBoxFromDisk 避免 type conflict
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
    // 先關閉所有 box 以避免 type conflict，並重置初始化狀態
    await close();

    // 1. Core Data (最重要)
    if (clearTrips) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.trips);
    }
    if (clearItinerary) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.itinerary);
    }
    if (clearMessages) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.messages);
    }

    // 2. Feature Data (功能性資料)
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

    // 3. System & Logs (系統與日誌)
    if (clearSettings) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.username);
    }
    if (clearLogs) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.logs);
    }

    // 如果清除了任何資料，建議重新初始化以確保 Encryption Key 狀態正確 (雖然 Key 是 persistent 的)
    // 但因為 close() 了，下次使用前會自動 init()
  }
}
