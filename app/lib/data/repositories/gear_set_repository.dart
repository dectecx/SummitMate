import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/domain.dart';
import '../datasources/interfaces/i_gear_cloud_remote_data_source.dart';
import '../datasources/interfaces/i_gear_key_local_data_source.dart';

/// 裝備組合 Repository
///
/// 負責協調雲端裝備組合 (GearSet) 與本地 Key 儲存。
@LazySingleton(as: IGearSetRepository)
class GearSetRepository implements IGearSetRepository {
  final IGearCloudRemoteDataSource _remoteDataSource;
  final IGearKeyLocalDataSource _localDataSource;

  GearSetRepository(this._remoteDataSource, this._localDataSource);

  // --- Remote (雲端操作) ---

  /// 取得所有公開/分享的裝備組合
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets({bool? myUploadedOnly}) =>
      _remoteDataSource.getGearSets(myUploadedOnly: myUploadedOnly);

  /// 下載特定裝備組合
  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) =>
      _remoteDataSource.downloadGearSet(id, key: key);

  /// 刪除雲端裝備組合
  @override
  Future<Result<bool, Exception>> deleteGearSet(String id) => _remoteDataSource.deleteGearSet(id);

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

  /// 更新裝備組合
  @override
  Future<Result<GearSet, Exception>> updateGearSet({
    required String id,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  }) => _remoteDataSource.updateGearSet(
    id: id,
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
