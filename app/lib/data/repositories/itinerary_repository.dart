import 'package:injectable/injectable.dart';
import '../../core/error/result.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/repositories/i_itinerary_repository.dart';
import '../models/itinerary_item_model.dart';
import '../datasources/interfaces/i_itinerary_local_data_source.dart';
import '../datasources/interfaces/i_itinerary_remote_data_source.dart';

/// 行程 Repository 實作
@LazySingleton(as: IItineraryRepository)
class ItineraryRepository implements IItineraryRepository {
  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;

  ItineraryRepository({
    required IItineraryLocalDataSource localDataSource,
    required IItineraryRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Result<void, Exception>> init() async {
    return const Success(null);
  }

  @override
  List<ItineraryItem> getByTripId(String tripId) {
    return _localDataSource
        .getByTripId(tripId)
        .map((m) => m.toDomain())
        .toList();
  }

  @override
  ItineraryItem? getById(String id) {
    return _localDataSource.getById(id)?.toDomain();
  }

  @override
  Future<Result<void, Exception>> add(ItineraryItem item) async {
    try {
      final model = ItineraryItemModel.fromDomain(item);
      await _localDataSource.add(model);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> update(ItineraryItem item) async {
    try {
      final model = ItineraryItemModel.fromDomain(item);
      await _localDataSource.update(model);
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
      // 策略：保留本地打卡紀錄
      final existingModels = _localDataSource.getAll();
      final actualTimeMap = {for (var m in existingModels) m.id: (m.actualTime, m.isCheckedIn, m.checkedInAt)};

      await _localDataSource.clear();

      for (final item in items) {
        final model = ItineraryItemModel.fromDomain(item);
        final localData = actualTimeMap[model.id];
        if (localData != null) {
          model.actualTime = localData.$1;
          model.isCheckedIn = localData.$2;
          model.checkedInAt = localData.$3;
        }
        await _localDataSource.add(model);
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> toggleCheckIn(String id) async {
    try {
      final model = _localDataSource.getById(id);
      if (model != null) {
        model.isCheckedIn = !model.isCheckedIn;
        model.checkedInAt = model.isCheckedIn ? DateTime.now() : null;
        model.actualTime = model.checkedInAt;
        await _localDataSource.update(model);
        return const Success(null);
      }
      return const Failure(GeneralException('Item not found'));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> sync(String tripId) async {
    // Basic sync logic: Fetch from remote and save to local
    try {
      final remoteItems = await _remoteDataSource.getItinerary(tripId);
      for (final item in remoteItems) {
        await _localDataSource.add(ItineraryItemModel.fromDomain(item));
      }
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
