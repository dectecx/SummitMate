import '../../models/gear_set.dart';
import '../../models/gear_key_record.dart';
import '../../models/gear_item.dart';
import '../../models/meal_item.dart';
import '../../../domain/interfaces/i_gear_cloud_service.dart'; // For GearCloudResult

abstract class IGearSetRepository {
  // Remote Actions
  Future<GearCloudResult<List<GearSet>>> getGearSets();
  Future<GearCloudResult<GearSet>> getGearSetByKey(String key);
  Future<GearCloudResult<GearSet>> downloadGearSet(String uuid, {String? key});

  Future<GearCloudResult<GearSet>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  });

  Future<GearCloudResult<bool>> deleteGearSet(String uuid, String key);

  // Local Key Storage Actions
  Future<List<GearKeyRecord>> getUploadedKeys();
  Future<void> saveUploadedKey(String key, String title, String visibility);
  Future<void> removeUploadedKey(String key);
}
