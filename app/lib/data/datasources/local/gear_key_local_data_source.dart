import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/gear_key_record.dart';
import '../interfaces/i_gear_key_local_data_source.dart';

/// 裝備清單 Key 的本地資料來源實作 (使用 Shared Preferences)
@LazySingleton(as: IGearKeyLocalDataSource)
class GearKeyLocalDataSource implements IGearKeyLocalDataSource {
  static const String _keyPrefix = 'gear_uploaded_keys';

  /// 取得本地儲存的所有上傳 Key
  @override
  Future<List<GearKeyRecord>> getUploadedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];
    return keysJson.map((jsonStr) => GearKeyRecord.fromJson(json.decode(jsonStr))).toList();
  }

  /// 儲存上傳 Key 紀錄
  ///
  /// [key] 雲端回傳的唯一識別碼
  /// [title] 清單標題
  /// [visibility] 可見度 (public / private)
  @override
  Future<void> saveUploadedKey(String key, String title, String visibility) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    final record = GearKeyRecord(
      key: key,
      title: title,
      visibility: visibility,
      uploadedAt: DateTime.now(),
    );

    keysJson.add(json.encode(record.toJson()));
    await prefs.setStringList(_keyPrefix, keysJson);
  }

  /// 移除指定的上傳 Key 紀錄
  ///
  /// [key] 雲端識別碼
  @override
  Future<void> removeUploadedKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    // 過濾掉指定的 key
    final filtered = keysJson.where((jsonStr) {
      final record = GearKeyRecord.fromJson(json.decode(jsonStr));
      return record.key != key;
    }).toList();

    await prefs.setStringList(_keyPrefix, filtered);
  }
}
