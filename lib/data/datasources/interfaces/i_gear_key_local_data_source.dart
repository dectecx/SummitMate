import '../../models/gear_key_record.dart';

abstract class IGearKeyLocalDataSource {
  Future<List<GearKeyRecord>> getUploadedKeys();
  Future<void> saveUploadedKey(String key, String title, String visibility);
  Future<void> removeUploadedKey(String key);
}
