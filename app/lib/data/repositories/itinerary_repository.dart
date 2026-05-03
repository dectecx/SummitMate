import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/repositories/i_itinerary_repository.dart';
import '../datasources/interfaces/i_itinerary_local_data_source.dart';
import '../datasources/interfaces/i_itinerary_remote_data_source.dart';

/// 行程節點 Repository 實作
@LazySingleton(as: IItineraryRepository)
class ItineraryRepository implements IItineraryRepository {
  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;

  ItineraryRepository({
    required IItineraryLocalDataSource localDataSource,
    required IItineraryRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  Future<List<ItineraryItem>> getByTripId(String tripId) async {
    return await _localDataSource.getByTripId(tripId);
  }

  @override
  Future<ItineraryItem?> getById(String id) async {
    return await _localDataSource.getById(id);
  }

  @override
  Future<Result<void, Exception>> add(ItineraryItem item) async {
    try {
      await _localDataSource.add(item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> update(ItineraryItem item) async {
    try {
      await _localDataSource.update(item);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> delete(String id) async {
    try {
      await _localDataSource.deleteById(id);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> clearByTripId(String tripId) async {
    try {
      await _localDataSource.clearByTripId(tripId);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> saveAll(List<ItineraryItem> items) async {
    try {
      // 策略：保留本地打卡紀錄 (Drift 實作中應考慮 upsert 或手動合併)
      final existingItems = await _localDataSource.getAll();
      final localDataMap = {for (var item in existingItems) item.id: item};

      await _localDataSource.clear();

      for (final item in items) {
        var itemToSave = item;
        final localItem = localDataMap[item.id];
        if (localItem != null) {
          // 合併本地打卡狀態
          itemToSave = item.copyWith(
            isCompleted: localItem.isCompleted,
            // TODO: 若 ItineraryItem 有 actualTime 等屬性，在此合併
          );
        }
        await _localDataSource.add(itemToSave);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> toggleCheckIn(String id) async {
    try {
      final item = await _localDataSource.getById(id);
      if (item != null) {
        final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
        await _localDataSource.update(updatedItem);
        return const Success(null);
      }
      return const Failure(GeneralException('Item not found'));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> sync(String tripId) async {
    try {
      final remoteItems = await _remoteDataSource.getItinerary(tripId);
      await saveAll(remoteItems);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
