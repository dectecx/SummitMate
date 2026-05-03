import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/domain.dart';
import '../../domain/interfaces/i_gear_cloud_service.dart';
import '../datasources/interfaces/i_gear_key_local_data_source.dart';

/// 裝備組合 Repository
///
/// 負責協調雲端裝備組合 (GearSet) 與本地 Key 儲存。
@LazySingleton(as: IGearSetRepository)
class GearSetRepository implements IGearSetRepository {
  final IGearCloudService _remoteDataSource;
  final IGearKeyLocalDataSource _localDataSource;

  GearSetRepository(this._remoteDataSource, this._localDataSource);

  // --- Remote (雲端操作) ---

  /// 取得所有公開/分享的裝備組合
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets() => _remoteDataSource.getGearSets();

  /// 透過 Key 取得單一裝備組合
  ///
  /// [key] 裝備組合的唯一識別碼
  @override
  Future<Result<GearSet, Exception>> getGearSetByKey(String key) => _remoteDataSource.getGearSetByKey(key);

  /// 下載特定裝備組合
  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) =>
      _remoteDataSource.downloadGearSet(id, key: key);

  /// 刪除雲端裝備組合
  @override
  Future<Result<bool, Exception>> deleteGearSet(String id, String key) => _remoteDataSource.deleteGearSet(id, key);

  /// 上傳裝備組合
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

  // --- Local (本地記錄) ---

  /// 取得本地已上傳過的 Key 紀錄
  @override
  Future<List<GearKeyRecord>> getUploadedKeys() async {
    return _localDataSource.getUploadedKeys();
  }

  /// 儲存一條上傳紀錄
  @override
  Future<void> saveUploadedKey(String key, String title, String visibility) =>
      _localDataSource.saveUploadedKey(key, title, visibility);

  /// 移除一條上傳紀錄
  @override
  Future<void> removeUploadedKey(String key) => _localDataSource.removeUploadedKey(key);
}
