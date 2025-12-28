import 'dart:convert';

import '../core/constants.dart';
import '../core/env_config.dart';
import '../data/models/gear_library_item.dart';
import 'gas_api_client.dart';
import 'log_service.dart';

/// 個人裝備庫雲端服務
///
/// 處理個人裝備庫的雲端備份與還原
/// 使用 owner_key (4 位數) 識別用戶
///
/// 【未來規劃】會員機制上線後改用 user_id
class GearLibraryCloudService {
  static const String _source = 'GearLibraryCloud';

  final GasApiClient _apiClient;

  GearLibraryCloudService({GasApiClient? apiClient})
    : _apiClient = apiClient ?? GasApiClient(baseUrl: EnvConfig.gasBaseUrl);

  /// 上傳個人裝備庫到雲端 (覆寫模式)
  ///
  /// [ownerKey] 4 位數識別碼
  /// [items] 裝備列表
  Future<GearLibraryCloudResult<int>> uploadLibrary({
    required String ownerKey,
    required List<GearLibraryItem> items,
  }) async {
    try {
      // 驗證 owner_key
      if (!_isValidOwnerKey(ownerKey)) {
        return GearLibraryCloudResult.failure('owner_key 必須為 4 位數字');
      }

      LogService.info('上傳裝備庫: ${items.length} 個項目...', source: _source);

      final response = await _apiClient.post({
        'action': ApiConfig.actionUploadGearLibrary,
        'owner_key': ownerKey,
        'items': items.map((item) => item.toJson()).toList(),
      });

      if (response.statusCode != 200) {
        return GearLibraryCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearLibraryCloudResult.failure(data['error'] ?? '上傳失敗');
      }

      final count = data['count'] as int? ?? items.length;
      LogService.info('成功上傳 $count 個裝備項目', source: _source);
      return GearLibraryCloudResult.success(count);
    } catch (e) {
      LogService.error('上傳裝備庫失敗: $e', source: _source);
      return GearLibraryCloudResult.failure('$e');
    }
  }

  /// 從雲端下載個人裝備庫
  ///
  /// [ownerKey] 4 位數識別碼
  Future<GearLibraryCloudResult<List<GearLibraryItem>>> downloadLibrary({required String ownerKey}) async {
    try {
      // 驗證 owner_key
      if (!_isValidOwnerKey(ownerKey)) {
        return GearLibraryCloudResult.failure('owner_key 必須為 4 位數字');
      }

      LogService.info('下載裝備庫...', source: _source);

      final response = await _apiClient.post({'action': ApiConfig.actionDownloadGearLibrary, 'owner_key': ownerKey});

      if (response.statusCode != 200) {
        return GearLibraryCloudResult.failure('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        return GearLibraryCloudResult.failure(data['error'] ?? '下載失敗');
      }

      final items =
          (data['items'] as List<dynamic>?)
              ?.map((item) => GearLibraryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      LogService.info('成功下載 ${items.length} 個裝備項目', source: _source);
      return GearLibraryCloudResult.success(items);
    } catch (e) {
      LogService.error('下載裝備庫失敗: $e', source: _source);
      return GearLibraryCloudResult.failure('$e');
    }
  }

  /// 驗證 owner_key 格式
  bool _isValidOwnerKey(String key) {
    if (key.length != 4) return false;
    return RegExp(r'^\d{4}$').hasMatch(key);
  }
}

/// 裝備庫雲端操作結果
class GearLibraryCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  GearLibraryCloudResult._({required this.isSuccess, this.data, this.error});

  factory GearLibraryCloudResult.success(T data) {
    return GearLibraryCloudResult._(isSuccess: true, data: data);
  }

  factory GearLibraryCloudResult.failure(String error) {
    return GearLibraryCloudResult._(isSuccess: false, error: error);
  }
}
