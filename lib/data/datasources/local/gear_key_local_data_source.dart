import 'package:shared_preferences/shared_preferences.dart';
import '../../models/gear_key_record.dart';
import '../interfaces/i_gear_key_local_data_source.dart';

class GearKeyLocalDataSource implements IGearKeyLocalDataSource {
  static const String _keyPrefix = 'gear_uploaded_keys';

  @override
  Future<List<GearKeyRecord>> getUploadedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];
    return keysJson.map((json) => GearKeyRecord.fromStorageString(json)).toList();
  }

  @override
  Future<void> saveUploadedKey(String key, String title, String visibility) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    final record = GearKeyRecord(key: key, title: title, visibility: visibility, uploadedAt: DateTime.now());

    keysJson.add(record.toStorageString());
    await prefs.setStringList(_keyPrefix, keysJson);
  }

  @override
  Future<void> removeUploadedKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getStringList(_keyPrefix) ?? [];

    // 過濾掉指定的 key
    final filtered = keysJson.where((json) {
      final record = GearKeyRecord.fromStorageString(json);
      return record.key != key;
    }).toList();

    await prefs.setStringList(_keyPrefix, filtered);
  }
}
