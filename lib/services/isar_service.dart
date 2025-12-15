import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/settings.dart';
import '../data/models/itinerary_item.dart';
import '../data/models/message.dart';
import '../data/models/gear_item.dart';

/// Isar 資料庫服務
/// 管理資料庫的初始化與生命週期
class IsarService {
  static IsarService? _instance;
  Isar? _isar;

  /// 單例模式
  factory IsarService() {
    _instance ??= IsarService._internal();
    return _instance!;
  }

  IsarService._internal();

  /// 取得 Isar 實例
  Isar get isar {
    if (_isar == null) {
      throw StateError('IsarService has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  /// 是否已初始化
  bool get isInitialized => _isar != null;

  /// 初始化資料庫
  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        SettingsSchema,
        ItineraryItemSchema,
        MessageSchema,
        GearItemSchema,
      ],
      directory: dir.path,
      name: 'summitmate',
    );
  }

  /// 關閉資料庫
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// 清除所有資料 (Debug 用途)
  Future<void> clearAllData() async {
    await _isar?.writeTxn(() async {
      await _isar!.clear();
    });
  }

  /// 取得資料庫大小 (bytes)
  /// 透過備份檔案來計算大小
  Future<int> getDatabaseSize() async {
    if (_isar == null) return 0;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupPath = '${dir.path}/summitmate_backup.isar';
      await _isar!.copyToFile(backupPath);
      
      // 使用 dart:io 操作檔案
      final backupFile = File(backupPath);
      final size = await backupFile.length();
      await backupFile.delete();
      return size;
    } catch (e) {
      // 如果備份失敗，返回 0
      return 0;
    }
  }

  /// 為測試提供的初始化方法
  static Future<Isar> initForTest({String? directory, String? name}) async {
    return await Isar.open(
      [
        SettingsSchema,
        ItineraryItemSchema,
        MessageSchema,
        GearItemSchema,
      ],
      directory: directory ?? '',
      name: name ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
