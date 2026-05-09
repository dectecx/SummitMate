import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/core.dart';
import '../../../domain/domain.dart';
import '../../api/mappers/gear_set_api_mapper.dart';
import '../../api/services/gear_set_api_service.dart';
import '../interfaces/i_gear_cloud_remote_data_source.dart';

/// 雲端裝備庫遠端資料來源實作，對接後端 /gear-sets API
@LazySingleton(as: IGearCloudRemoteDataSource)
class GearCloudRemoteDataSource implements IGearCloudRemoteDataSource {
  final GearSetApiService _api;

  GearCloudRemoteDataSource(this._api);

  @override
  Future<Result<List<GearSet>, Exception>> getGearSets({bool? myUploadedOnly}) async {
    try {
      final response = await _api.listGearSets(page: 1, limit: 50, myUploaded: myUploadedOnly);
      final sets = response.data.map(GearSetApiMapper.fromResponse).toList();
      return Success(sets);
    } on DioException catch (e) {
      return Failure(Exception('取得裝備組合列表失敗: ${e.message}'));
    } catch (e) {
      return Failure(Exception('未知錯誤: $e'));
    }
  }

  @override
  Future<Result<GearSet, Exception>> downloadGearSet(String id, {String? key}) async {
    try {
      final detail = await _api.getGearSet(id, key: key);
      return Success(GearSetApiMapper.fromResponse(detail));
    } on DioException catch (e) {
      return Failure(Exception('下載失敗: ${e.message}'));
    } catch (e) {
      return Failure(Exception('未知錯誤: $e'));
    }
  }

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
      final request = GearSetApiMapper.toCreateRequest(
        title: title,
        author: author,
        visibility: visibility,
        items: items,
        meals: meals,
        downloadKey: key,
      );
      final response = await _api.createGearSet(request);
      return Success(GearSetApiMapper.fromResponse(response));
    } on DioException catch (e) {
      return Failure(Exception('上傳失敗: ${e.message}'));
    } catch (e) {
      return Failure(Exception('未知錯誤: $e'));
    }
  }

  @override
  Future<Result<GearSet, Exception>> updateGearSet({
    required String id,
    required String title,
    required String author,
    required GearSetVisibility visibility,
    required List<GearItem> items,
    List<DailyMealPlan>? meals,
    String? key,
  }) async {
    try {
      final request = GearSetApiMapper.toCreateRequest(
        title: title,
        author: author,
        visibility: visibility,
        items: items,
        meals: meals,
        downloadKey: key,
      );
      final response = await _api.updateGearSet(id, request);
      return Success(GearSetApiMapper.fromResponse(response));
    } on DioException catch (e) {
      return Failure(Exception('更新失敗: ${e.message}'));
    } catch (e) {
      return Failure(Exception('未知錯誤: $e'));
    }
  }

  @override
  Future<Result<bool, Exception>> deleteGearSet(String id) async {
    try {
      await _api.deleteGearSet(id);
      return const Success(true);
    } on DioException catch (e) {
      return Failure(Exception('刪除失敗: ${e.message}'));
    } catch (e) {
      return Failure(Exception('未知錯誤: $e'));
    }
  }
}
