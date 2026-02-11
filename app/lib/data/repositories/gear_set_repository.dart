import '../../core/di.dart';
import '../../core/error/result.dart';
import '../models/gear_set.dart';
import '../models/gear_key_record.dart';
import '../models/gear_item.dart';
import '../models/meal_item.dart';
import 'interfaces/i_gear_set_repository.dart';
import '../../domain/interfaces/i_gear_cloud_service.dart';
import '../datasources/interfaces/i_gear_key_local_data_source.dart';

/// 裝備組合 Repository
///
/// 負責協調雲端裝備組合 (GearSet) 與本地 Key 儲存。
class GearSetRepository implements IGearSetRepository {
  final IGearCloudService _remoteDataSource;
  final IGearKeyLocalDataSource _localDataSource;

  GearSetRepository({IGearCloudService? remoteDataSource, IGearKeyLocalDataSource? localDataSource})
    : _remoteDataSource = remoteDataSource ?? getIt<IGearCloudService>(),
      _localDataSource = localDataSource ?? getIt<IGearKeyLocalDataSource>();

  // --- Remote (雲端操作) ---

  /// 取得所有公開/分享的裝備組合
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets() => _remoteDataSource.getGearSets();

  /// 透過 Key 取得單一裝備組合
  ///
  /// [key] 裝備組合的唯一識別碼
  @override
  Future<Result<GearSet, Exception>> getGearSetByKey(String key) => _remoteDataSource.getGearSetByKey(key);

  /// 下載並匯入裝備組合至指定行程
  ///
  /// [uuid] 本地識別碼 (可選)
  /// [key] 雲端識別碼
  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String uuid, {String? key}) =>
      _remoteDataSource.downloadGearSet(uuid, key: key);

  /// 上傳/分享裝備組合
  ///
  /// [tripId] 關聯行程 ID
  /// [title] 清單標題
  /// [author] 作者名稱
  /// [visibility] 可見度
  /// [items] 裝備項目列表
  /// [meals] 餐食計畫 (可選)
  /// [key] 若為更新舊有清單，則提供此 Key
  @override
  Future<Result<GearSet, Exception>> uploadGearSet({
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

  /// 刪除雲端裝備組合
  ///
  /// [uuid] 本地識別碼 (若有)
  /// [key] 雲端識別碼
  @override
  Future<Result<bool, Exception>> deleteGearSet(String uuid, String key) => _remoteDataSource.deleteGearSet(uuid, key);

  // --- Local (本地紀錄) ---

  /// 取得已上傳的組合 Key 紀錄
  @override
  Future<List<GearKeyRecord>> getUploadedKeys() => _localDataSource.getUploadedKeys();

  /// 儲存上傳紀錄 (Key)
  ///
  /// [key] 雲端識別碼
  /// [title] 標題
  /// [visibility] 可見度
  @override
  Future<void> saveUploadedKey(String key, String title, String visibility) =>
      _localDataSource.saveUploadedKey(key, title, visibility);

  /// 移除上傳紀錄
  ///
  /// [key] 雲端識別碼
  @override
  Future<void> removeUploadedKey(String key) => _localDataSource.removeUploadedKey(key);
}
