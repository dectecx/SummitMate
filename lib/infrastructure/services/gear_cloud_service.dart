import '../../core/constants.dart';
import '../../core/di.dart';
import '../../core/error/result.dart';
import '../../data/models/gear_set.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/meal_item.dart';
import '../clients/network_aware_client.dart';
import '../clients/gas_api_client.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_gear_cloud_service.dart';

/// 雲端裝備庫服務
class GearCloudService implements IGearCloudService {
  static const String _source = 'GearCloud';

  final NetworkAwareClient _apiClient;

  GearCloudService({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得公開/保護的裝備組合列表
  @override
  Future<Result<List<GearSet>, Exception>> getGearSets() async {
    try {
      LogService.info('取得雲端裝備組合列表...', source: _source);

      final response = await _apiClient.post('', data: {'action': ApiConfig.actionGearSetList});

      if (response.statusCode != 200) {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return Failure(GeneralException(gasResponse.message));
      }

      final gearSets =
          (gasResponse.data['gear_sets'] as List<dynamic>?)
              ?.map((item) => GearSet.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.info('取得 ${gearSets.length} 個裝備組合', source: _source);
      return Success(gearSets);
    } catch (e) {
      LogService.error('取得裝備組合失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 用 Key 取得特定裝備組合 (含 items)
  @override
  Future<Result<GearSet, Exception>> getGearSetByKey(String key) async {
    try {
      LogService.info('用 Key 取得裝備組合...', source: _source);

      final response = await _apiClient.post('', data: {'action': ApiConfig.actionGearSetGet, 'key': key});

      if (response.statusCode != 200) {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return Failure(GeneralException(gasResponse.message));
      }

      final gearSet = GearSet.fromJson(gasResponse.data['gear_set'] as Map<String, dynamic>);
      LogService.info('成功取得: ${gearSet.title}', source: _source);
      return Success(gearSet);
    } catch (e) {
      LogService.error('用 Key 取得失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 下載指定裝備組合
  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) async {
    try {
      LogService.info('下載裝備組合: $id', source: _source);

      final response = await _apiClient.post(
        '',
        data: {'action': ApiConfig.actionGearSetDownload, 'id': id, if (key != null) 'key': key},
      );

      if (response.statusCode != 200) {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return Failure(GeneralException(gasResponse.message));
      }

      final gearSet = GearSet.fromJson(gasResponse.data['gear_set'] as Map<String, dynamic>);
      LogService.info('下載成功: ${gearSet.title} (${gearSet.itemCount} items)', source: _source);
      return Success(gearSet);
    } catch (e) {
      LogService.error('下載失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

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
  }) async {
    try {
      // Protected/Private 模式必須有 Key
      if (visibility != GearSetVisibility.public && (key == null || key.length != 4)) {
        return const Failure(GeneralException('Protected/Private 模式需要 4 位數 Key'));
      }

      LogService.info('上傳裝備組合: $title ($visibility)', source: _source);

      final totalWeight = items.fold<double>(0, (sum, item) => sum + item.weight);

      final response = await _apiClient.post(
        '',
        data: {
          'action': ApiConfig.actionGearSetUpload,
          'trip_id': tripId,
          'title': title,
          'author': author,
          'visibility': visibility.name,
          'total_weight': totalWeight,
          'item_count': items.length,
          'items': items.map((item) => item.toJson()).toList(),
          if (meals != null) 'meals': meals.map((m) => m.toJson()).toList(),
          if (key != null) 'key': key,
        },
      );

      if (response.statusCode != 200) {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        final errorMsg = gasResponse.message;
        // 檢查是否為 Key 重複錯誤
        if (errorMsg.contains('duplicate') || errorMsg.contains('重複')) {
          return const Failure(GeneralException('Key 已存在，請換一個 4 位數'));
        }
        return Failure(GeneralException(errorMsg));
      }

      final gearSet = GearSet.fromJson(gasResponse.data['gear_set'] as Map<String, dynamic>);
      LogService.info('上傳成功: ${gearSet.id}', source: _source);
      return Success(gearSet);
    } catch (e) {
      LogService.error('上傳失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 刪除裝備組合 (需要 Key 驗證)
  @override
  Future<Result<bool, Exception>> deleteGearSet(String id, String key) async {
    try {
      LogService.info('刪除裝備組合: $id', source: _source);

      final response = await _apiClient.post('', data: {'action': ApiConfig.actionGearSetDelete, 'id': id, 'key': key});

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return Failure(GeneralException(gasResponse.message));
      }

      LogService.info('刪除成功', source: _source);
      return const Success(true);
    } catch (e) {
      LogService.error('刪除失敗: $e', source: _source);
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }
}
