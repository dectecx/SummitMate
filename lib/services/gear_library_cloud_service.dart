import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/gear_library_item.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 個人裝備庫雲端同步服務
class GearLibraryCloudService {
  static const String _source = 'GearLibraryCloud';

  final GasApiClient _apiClient;

  GearLibraryCloudService({GasApiClient? apiClient})
    : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 同步個人裝備庫 (上傳全部)
  Future<GearLibraryCloudResult<int>> syncLibrary(String ownerKey, List<GearLibraryItem> items) async {
    try {
      LogService.info('同步裝備庫: ${items.length} items (key=$ownerKey)', source: _source);

      // GAS expects generic item structure, ensure GearLibraryItem.toJson matches
      final response = await _apiClient.post({
        'action': ApiConfig.actionUploadGearLibrary,
        'items': items.map((i) => i.toJson()).toList(),
        'owner_key': ownerKey,
      });

      if (response.statusCode != 200) {
        return GearLibraryCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return GearLibraryCloudResult.failure(gasResponse.message);
      }

      final count = gasResponse.data['count'] as int? ?? 0;
      LogService.info('同步成功: $count items stored', source: _source);
      return GearLibraryCloudResult.success(count);
    } catch (e) {
      LogService.error('同步裝備庫失敗: $e', source: _source);
      return GearLibraryCloudResult.failure('$e');
    }
  }

  /// 取得雲端個人裝備庫
  Future<GearLibraryCloudResult<List<GearLibraryItem>>> fetchLibrary(String ownerKey) async {
    try {
      LogService.info('取得雲端個人裝備庫 (key=$ownerKey)...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionDownloadGearLibrary, 'owner_key': ownerKey});

      if (response.statusCode != 200) {
        return GearLibraryCloudResult.failure('HTTP ${response.statusCode}');
      }

      final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
      if (!gasResponse.isSuccess) {
        return GearLibraryCloudResult.failure(gasResponse.message);
      }

      final items =
          (gasResponse.data['items'] as List<dynamic>?)
              ?.map((item) => GearLibraryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.info('取得 ${items.length} 個裝備', source: _source);
      return GearLibraryCloudResult.success(items);
    } catch (e) {
      LogService.error('取得個人裝備庫失敗: $e', source: _source);
      return GearLibraryCloudResult.failure('$e');
    }
  }
}

/// 裝備庫雲端操作結果
class GearLibraryCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  GearLibraryCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  factory GearLibraryCloudResult.success(T data) => GearLibraryCloudResult._(isSuccess: true, data: data);
  factory GearLibraryCloudResult.failure(String message) =>
      GearLibraryCloudResult._(isSuccess: false, errorMessage: message);
}
