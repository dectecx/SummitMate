import '../../core/constants.dart';
import '../../core/di.dart';
import 'package:summitmate/data/models/gear_library_item.dart';
import '../clients/network_aware_client.dart';
import '../clients/gas_api_client.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_gear_library_cloud_service.dart';

/// 個人裝備庫雲端同步服務
class GearLibraryCloudService implements IGearLibraryCloudService {
  static const String _source = 'GearLibraryCloud';

  final NetworkAwareClient _apiClient;

  GearLibraryCloudService({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 同步個人裝備庫 (上傳全部)
  @override
  Future<GearLibraryCloudResult<int>> syncLibrary(List<GearLibraryItem> items) async {
    try {
      LogService.info('同步裝備庫: ${items.length} items (User Auth)', source: _source);

      // GAS expects generic item structure, ensure GearLibraryItem.toJson matches
      final response = await _apiClient.post({
        'action': ApiConfig.actionGearLibraryUpload,
        'items': items.map((i) => i.toJson()).toList(),
      }, requiresAuth: true);

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
  @override
  Future<GearLibraryCloudResult<List<GearLibraryItem>>> getLibrary() async {
    try {
      LogService.info('取得雲端個人裝備庫 (User Auth)...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionGearLibraryDownload}, requiresAuth: true);

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
