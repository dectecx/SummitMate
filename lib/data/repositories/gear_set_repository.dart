import '../../core/di.dart';
import '../models/gear_set.dart';
import '../models/gear_key_record.dart';
import '../models/gear_item.dart';
import '../models/meal_item.dart';
import 'interfaces/i_gear_set_repository.dart';
import '../../services/interfaces/i_gear_cloud_service.dart';
import '../datasources/interfaces/i_gear_key_local_data_source.dart';

class GearSetRepository implements IGearSetRepository {
  final IGearCloudService _remoteDataSource;
  final IGearKeyLocalDataSource _localDataSource;

  GearSetRepository({IGearCloudService? remoteDataSource, IGearKeyLocalDataSource? localDataSource})
    : _remoteDataSource = remoteDataSource ?? getIt<IGearCloudService>(),
      _localDataSource = localDataSource ?? getIt<IGearKeyLocalDataSource>();

  // --- Remote ---

  @override
  Future<GearCloudResult<List<GearSet>>> getGearSets() => _remoteDataSource.getGearSets();

  @override
  Future<GearCloudResult<GearSet>> getGearSetByKey(String key) => _remoteDataSource.getGearSetByKey(key);

  @override
  Future<GearCloudResult<GearSet>> downloadGearSet(String uuid, {String? key}) =>
      _remoteDataSource.downloadGearSet(uuid, key: key);

  @override
  Future<GearCloudResult<GearSet>> uploadGearSet({
    required String tripId,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  }) => _remoteDataSource.uploadGearSet(
    tripId: tripId,
    title: title,
    author: author,
    visibility: visibility,
    items: items,
    meals: meals,
    key: key,
  );

  @override
  Future<GearCloudResult<bool>> deleteGearSet(String uuid, String key) => _remoteDataSource.deleteGearSet(uuid, key);

  // --- Local ---

  @override
  Future<List<GearKeyRecord>> getUploadedKeys() => _localDataSource.getUploadedKeys();

  @override
  Future<void> saveUploadedKey(String key, String title, String visibility) =>
      _localDataSource.saveUploadedKey(key, title, visibility);

  @override
  Future<void> removeUploadedKey(String key) => _localDataSource.removeUploadedKey(key);
}
