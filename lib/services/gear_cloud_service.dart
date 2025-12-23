import 'dart:convert';

import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/gear_set.dart';
import '../data/models/gear_item.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 雲端裝備庫服務
class GearCloudService {
  static const String _source = 'GearCloud';

  final GasApiClient _apiClient;

  GearCloudService({GasApiClient? apiClient}) : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 取得公開/保護的裝備組合列表
  Future<GearCloudResult<List<GearSet>>> fetchGearSets() async {
    try {
      LogService.info('取得雲端裝備組合列表...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionFetchGearSets});

      if (response.statusCode != 200) {
        return GearCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearCloudResult.failure(data['error'] ?? '取得失敗');
      }

      final gearSets =
          (data['gear_sets'] as List<dynamic>?)
              ?.map((item) => GearSet.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.info('取得 ${gearSets.length} 個裝備組合', source: _source);
      return GearCloudResult.success(gearSets);
    } catch (e) {
      LogService.error('取得裝備組合失敗: $e', source: _source);
      return GearCloudResult.failure('$e');
    }
  }

  /// 用 Key 取得特定裝備組合 (含 items)
  Future<GearCloudResult<GearSet>> fetchGearSetByKey(String key) async {
    try {
      LogService.info('用 Key 取得裝備組合...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionFetchGearSetByKey, 'key': key});

      if (response.statusCode != 200) {
        return GearCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearCloudResult.failure(data['error'] ?? '取得失敗');
      }

      final gearSet = GearSet.fromJson(data['gear_set'] as Map<String, dynamic>);
      LogService.info('成功取得: ${gearSet.title}', source: _source);
      return GearCloudResult.success(gearSet);
    } catch (e) {
      LogService.error('用 Key 取得失敗: $e', source: _source);
      return GearCloudResult.failure('$e');
    }
  }

  /// 下載指定裝備組合
  Future<GearCloudResult<GearSet>> downloadGearSet(String uuid, {String? key}) async {
    try {
      LogService.info('下載裝備組合: $uuid', source: _source);

      final response = await _apiClient.post({
        'action': ApiConfig.actionDownloadGearSet,
        'uuid': uuid,
        if (key != null) 'key': key,
      });

      if (response.statusCode != 200) {
        return GearCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearCloudResult.failure(data['error'] ?? '下載失敗');
      }

      final gearSet = GearSet.fromJson(data['gear_set'] as Map<String, dynamic>);
      LogService.info('下載成功: ${gearSet.title} (${gearSet.itemCount} items)', source: _source);
      return GearCloudResult.success(gearSet);
    } catch (e) {
      LogService.error('下載失敗: $e', source: _source);
      return GearCloudResult.failure('$e');
    }
  }

  /// 上傳裝備組合
  Future<GearCloudResult<GearSet>> uploadGearSet({
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    String? key,
  }) async {
    try {
      // Protected/Private 模式必須有 Key
      if (visibility != GearSetVisibility.public && (key == null || key.length != 4)) {
        return GearCloudResult.failure('Protected/Private 模式需要 4 位數 Key');
      }

      LogService.info('上傳裝備組合: $title ($visibility)', source: _source);

      final totalWeight = items.fold<double>(0, (sum, item) => sum + item.weight);

      final response = await _apiClient.post({
        'action': ApiConfig.actionUploadGearSet,
        'title': title,
        'author': author,
        'visibility': visibility.name,
        'total_weight': totalWeight,
        'item_count': items.length,
        'items': items.map((item) => item.toJson()).toList(),
        if (key != null) 'key': key,
      });

      if (response.statusCode != 200) {
        return GearCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        final errorMsg = data['error'] ?? '上傳失敗';
        // 檢查是否為 Key 重複錯誤
        if (errorMsg.toString().contains('duplicate') || errorMsg.toString().contains('重複')) {
          return GearCloudResult.failure('Key 已存在，請換一個 4 位數');
        }
        return GearCloudResult.failure(errorMsg);
      }

      final gearSet = GearSet.fromJson(data['gear_set'] as Map<String, dynamic>);
      LogService.info('上傳成功: ${gearSet.uuid}', source: _source);
      return GearCloudResult.success(gearSet);
    } catch (e) {
      LogService.error('上傳失敗: $e', source: _source);
      return GearCloudResult.failure('$e');
    }
  }

  /// 刪除裝備組合 (需要 Key 驗證)
  Future<GearCloudResult<bool>> deleteGearSet(String uuid, String key) async {
    try {
      LogService.info('刪除裝備組合: $uuid', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionDeleteGearSet, 'uuid': uuid, 'key': key});

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearCloudResult.failure(data['error'] ?? '刪除失敗');
      }

      LogService.info('刪除成功', source: _source);
      return GearCloudResult.success(true);
    } catch (e) {
      LogService.error('刪除失敗: $e', source: _source);
      return GearCloudResult.failure('$e');
    }
  }
}

/// 雲端裝備操作結果
class GearCloudResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  GearCloudResult._({required this.success, this.data, this.errorMessage});

  factory GearCloudResult.success(T data) => GearCloudResult._(success: true, data: data);

  factory GearCloudResult.failure(String message) => GearCloudResult._(success: false, errorMessage: message);
}
