import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di/injection.dart';
import '../../models/message_model.dart';
import '../interfaces/i_message_local_data_source.dart';
import '../../../infrastructure/tools/hive_service.dart';

/// 留言訊息 (Message) 的本地資料來源實作 (使用 Hive)
@LazySingleton(as: IMessageLocalDataSource)
class MessageLocalDataSource implements IMessageLocalDataSource {
  static const String _boxName = HiveBoxNames.messages;
  static const String _prefKeyLastSync = 'msg_last_sync_time';

  final Box<MessageModel> box;

  MessageLocalDataSource({required HiveService hiveService}) : box = hiveService.getBox<MessageModel>(_boxName);

  /// 取得所有訊息
  @override
  List<MessageModel> getAll() {
    return box.values.toList();
  }

  /// 透過 ID 取得訊息
  ///
  /// [id] 訊息 ID
  @override
  MessageModel? getById(String id) {
    try {
      return box.values.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 新增訊息
  ///
  /// [message] 欲新增的訊息物件
  @override
  Future<void> add(MessageModel message) async {
    // 檢查是否已存在，若存在則更新 (基於 id)
    final existingIndex = box.values.toList().indexWhere((m) => m.id == message.id);
    if (existingIndex != -1) {
      await box.putAt(existingIndex, message);
    } else {
      await box.add(message);
    }
  }

  /// 刪除訊息
  ///
  /// [key] 訊息的本地鍵值 (Hive Key)
  @override
  Future<void> delete(dynamic key) async {
    // 如果 key 是 String (id)，我們需要找到對應的 Hive Key
    if (key is String) {
      final existingIndex = box.values.toList().indexWhere((m) => m.id == key);
      if (existingIndex != -1) {
        await box.deleteAt(existingIndex);
      }
    } else {
      await box.delete(key);
    }
  }

  /// 清除所有訊息
  @override
  Future<void> clear() async {
    await box.clear();
  }

  /// 監聽資料變更
  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }

  /// 儲存最後同步時間
  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKeyLastSync, time.toIso8601String());
  }

  /// 取得最後同步時間
  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_prefKeyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
