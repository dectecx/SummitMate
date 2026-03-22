import 'package:injectable/injectable.dart';
import '../../../core/di/injection.dart';
import '../../models/gear_library_item.dart';
import '../../../infrastructure/clients/network_aware_client.dart';
import '../../../infrastructure/tools/log_service.dart';

/// 個人裝備庫 (Gear Library) 的遠端資料來源介面
abstract class IGearLibraryRemoteDataSource {
  /// 取得所有雲端裝備庫項目
  Future<List<GearLibraryItem>> getLibrary();

  /// 新增裝備至雲端庫
  Future<GearLibraryItem> addLibraryItem(GearLibraryItem item);

  /// 更新雲端裝備庫項目
  Future<void> updateLibraryItem(GearLibraryItem item);

  /// 從雲端庫刪除裝備
  Future<void> deleteLibraryItem(String itemId);

  /// 批量替換雲端所有裝備
  Future<void> replaceAllLibraryItems(List<GearLibraryItem> items);
}

/// 個人裝備庫 (Gear Library) 的遠端資料來源實作
@LazySingleton(as: IGearLibraryRemoteDataSource)
class GearLibraryRemoteDataSource implements IGearLibraryRemoteDataSource {
  static const String _source = 'GearLibraryRemoteDataSource';
  final NetworkAwareClient _apiClient;

  GearLibraryRemoteDataSource(this._apiClient);

  @override
  Future<List<GearLibraryItem>> getLibrary() async {
    try {
      LogService.info('取得個人裝備庫列表...', source: _source);
      final response = await _apiClient.get('/gear-library');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => GearLibraryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('getLibrary 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<GearLibraryItem> addLibraryItem(GearLibraryItem item) async {
    try {
      LogService.info('新增裝備至雲端庫: ${item.name}', source: _source);
      // NOTE: CreateGearLibraryItemRequest 只需要某些欄位，但 GearLibraryItem.toJson() 包含 id, user_id 等
      // 後端 handler 會自行映射需要的欄位
      final response = await _apiClient.post('/gear-library', data: item.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GearLibraryItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      LogService.error('addLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> updateLibraryItem(GearLibraryItem item) async {
    try {
      LogService.info('更新雲端裝備項目: ${item.id}', source: _source);
      final response = await _apiClient.put('/gear-library/${item.id}', data: item.toJson());

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('updateLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> deleteLibraryItem(String itemId) async {
    try {
      LogService.info('刪除雲端裝備項目: $itemId', source: _source);
      final response = await _apiClient.delete('/gear-library/$itemId');

      if (response.statusCode != 200 && response.statusCode != 240) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('deleteLibraryItem 失敗: $e', source: _source);
      rethrow;
    }
  }

  @override
  Future<void> replaceAllLibraryItems(List<GearLibraryItem> items) async {
    try {
      LogService.info('批量替換雲端裝備庫: 數量 ${items.length}', source: _source);

      final response = await _apiClient.put('/gear-library', data: items.map((e) => e.toJson()).toList());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('replaceAllLibraryItems 失敗: $e', source: _source);
      rethrow;
    }
  }
}
