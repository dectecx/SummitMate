import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/domain.dart';
import '../datasources/interfaces/i_gear_cloud_remote_data_source.dart';
import '../datasources/interfaces/i_gear_key_local_data_source.dart';
import '../datasources/interfaces/i_gear_set_cache_local_data_source.dart';
import 'base/repository_remote_access.dart';

/// 裝備組合 Repository（A 模式：線上守門）
///
/// 雲端裝備組合（GearSet）為線上內容：所有遠端操作皆經
/// [RepositoryRemoteAccess.online] 守門（離線→`OfflineException`）。
/// [getGearSets] 額外保留本地快取，離線時可回傳上次拉取的清單。
@LazySingleton(as: IGearSetRepository)
class GearSetRepository with RepositoryRemoteAccess implements IGearSetRepository {
  final IGearCloudRemoteDataSource _remoteDataSource;
  final IGearKeyLocalDataSource _localDataSource;
  final IGearSetCacheLocalDataSource _cacheDao;

  @override
  final IConnectivityService connectivity;

  List<GearSet>? _cache;
  DateTime? _lastFetchedAt;

  @override
  DateTime? get lastFetchedAt => _lastFetchedAt;

  GearSetRepository(this._remoteDataSource, this._localDataSource, this._cacheDao, this.connectivity);

  // --- Remote (雲端操作，線上守門) ---

  /// 取得所有公開/分享的裝備組合
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets({bool? myUploadedOnly, bool forceRefresh = false}) async {
    // 1. 如果非強制刷新，且內存已有，直接回傳
    if (!forceRefresh && _cache != null && myUploadedOnly == null) {
      return Success(_cache!);
    }

    // 2. 如果內存沒有，且非強制刷新，嘗試從本地資料庫讀取
    if (!forceRefresh && _cache == null && myUploadedOnly == null) {
      try {
        final localSets = await _cacheDao.getAllGearSets();
        if (localSets.isNotEmpty) {
          _cache = localSets;
          return Success(localSets);
        }
      } catch (_) {
        // 快取讀取失敗則忽略，繼續往後打 API
      }
    }

    // 3. 獲取遠端資料（線上守門）
    return online<List<GearSet>>(
      'getGearSets',
      () => _remoteDataSource.getGearSets(myUploadedOnly: myUploadedOnly),
      cache: (value) async {
        if (myUploadedOnly == null) {
          _cache = value;
          _lastFetchedAt = DateTime.now();
          await _cacheDao.saveGearSets(value);
        }
      },
    );
  }

  /// 下載特定裝備組合
  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) =>
      online<GearSet>('downloadGearSet', () => _remoteDataSource.downloadGearSet(id, key: key));

  /// 刪除雲端裝備組合
  @override
  Future<Result<bool, Exception>> deleteGearSet(String id) =>
      online<bool>('deleteGearSet', () => _remoteDataSource.deleteGearSet(id));

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
  }) => online<GearSet>(
    'uploadGearSet',
    () => _remoteDataSource.uploadGearSet(
      tripId: tripId,
      title: title,
      author: author,
      visibility: visibility,
      items: items,
      meals: meals,
      key: key,
    ),
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
  }) => online<GearSet>(
    'updateGearSet',
    () => _remoteDataSource.updateGearSet(
      id: id,
      title: title,
      author: author,
      visibility: visibility,
      items: items,
      meals: meals,
      key: key,
    ),
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
