import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../core/models/paginated_list.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../data/repositories/interfaces/i_gear_repository.dart';
import '../../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../../data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../../../data/models/enums/sync_status.dart';
import 'trip_state.dart';

/// Manage Trip state and operations
@injectable
class TripCubit extends Cubit<TripState> {
  static const String _source = 'TripCubit';

  final ITripRepository _tripRepository;
  final ISyncService _syncService;
  final IAuthService _authService;

  final Uuid _uuid = const Uuid();

  TripCubit(this._tripRepository, this._syncService, this._authService) : super(const TripInitial());

  /// 載入所有行程並自動判定活動行程
  Future<void> loadTrips() async {
    try {
      emit(const TripLoading());

      final userId = _authService.currentUserId ?? 'guest';
      final tripsResult = await _tripRepository.getAllTrips(userId);

      final trips = switch (tripsResult) {
        Success(value: final v) => v,
        Failure(exception: final e) => throw e,
      };
      // 依建立時間排序 (最新的在前)
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final activeTripResult = await _tripRepository.getActiveTrip(userId);
      var activeTrip = (activeTripResult is Success<Trip?, Exception>) ? activeTripResult.value : null;

      // 若無活動行程但有行程資料，強制設定第一筆為活動行程
      if (activeTrip == null && trips.isNotEmpty) {
        await _setActiveTripInternal(trips.first.id);
        final newActiveResult = await _tripRepository.getActiveTrip(userId);
        activeTrip = switch (newActiveResult) {
          Success(value: final v) => v,
          Failure() => null, // Ignore error when setting default
        };
      } else if (activeTrip == null && trips.isEmpty) {
        // 若完全無行程，由 UI 決定是否引導建立
      }

      emit(TripLoaded(trips: trips, activeTrip: activeTrip));
    } catch (e) {
      LogService.error('Error loading trips: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 新增行程
  ///
  /// [name] 行程名稱
  /// [startDate] 開始日期
  /// [endDate] 結束日期 (可選)
  /// [description] 描述
  /// [coverImage] 封面圖片 URL
  /// [setAsActive] 是否建立後立即設為活動行程
  Future<void> addTrip({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? coverImage,
    bool setAsActive = true,
  }) async {
    try {
      final currentUserId = _authService.currentUserId ?? 'guest';
      final trip = Trip(
        id: _uuid.v4(),
        userId: currentUserId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        coverImage: coverImage,
        isActive: false, // 將透過 setActiveTrip 設定
        syncStatus: SyncStatus.pendingCreate,
        createdAt: DateTime.now(),
        createdBy: currentUserId,
        updatedAt: DateTime.now(),
        updatedBy: currentUserId,
      );

      final result = await _tripRepository.addTrip(trip);
      switch (result) {
        case Success():
          break; // Success
        case Failure(exception: final e):
          throw e;
      }

      LogService.info('Added trip: ${trip.name}', source: _source);

      if (setAsActive) {
        await setActiveTrip(trip.id);
      } else {
        await loadTrips();
      }
    } catch (e) {
      LogService.error('Error adding trip: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
      // 重新載入以確保狀態一致
      await loadTrips();
    }
  }

  /// 匯入行程 (例如從雲端)
  /// 注意：此方法不會直接觸發 SyncCubit，應由 UI 處理副作用
  ///
  /// [trip] 欲匯入的行程物件
  Future<void> importTrip(Trip trip) async {
    try {
      final result = await _tripRepository.addTrip(trip);
      switch (result) {
        case Success():
          break;
        case Failure(exception: final e):
          throw e;
      }
      LogService.info('Imported trip: ${trip.name} (${trip.id})', source: _source);
      await loadTrips();
    } catch (e) {
      LogService.error('Error importing trip: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 設定活動行程
  ///
  /// [tripId] 行程 ID
  Future<void> setActiveTrip(String tripId) async {
    try {
      await _setActiveTripInternal(tripId);
      LogService.info('Set active trip: $tripId', source: _source);
      await loadTrips();
    } catch (e) {
      LogService.error('Error setting active trip: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  Future<void> _setActiveTripInternal(String tripId) async {
    final result = await _tripRepository.setActiveTrip(tripId);
    switch (result) {
      case Success():
        return;
      case Failure(exception: final e):
        throw e;
    }
  }

  /// 刪除行程
  ///
  /// [tripId] 行程 ID
  Future<void> deleteTrip(String tripId) async {
    try {
      final currentState = state;
      if (currentState is TripLoaded) {
        // 若刪除的是當前活動行程，先切換到其他行程
        if (currentState.activeTrip?.id == tripId) {
          final otherTrips = currentState.trips.where((t) => t.id != tripId);
          if (otherTrips.isNotEmpty) {
            await _setActiveTripInternal(otherTrips.first.id);
          }
        }
      }

      final result = await _tripRepository.deleteTrip(tripId);
      switch (result) {
        case Success():
          break;
        case Failure(exception: final e):
          throw e;
      }
      LogService.info('Deleted trip: $tripId', source: _source);
      await loadTrips();
    } catch (e) {
      LogService.error('Error deleting trip: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新行程
  ///
  /// [trip] 更新後的行程物件
  Future<void> updateTrip(Trip trip) async {
    try {
      final result = await _tripRepository.updateTrip(trip);
      switch (result) {
        case Success():
          break;
        case Failure(exception: final e):
          throw e;
      }
      LogService.info('Updated trip: ${trip.name}', source: _source);
      await loadTrips();
    } catch (e) {
      LogService.error('Error updating trip: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 上傳完整行程至雲端 (包含行程表與裝備)
  ///
  /// [trip] 欲上傳的行程物件
  Future<bool> uploadFullTrip(Trip trip) async {
    try {
      // 1. 蒐集資料
      final gearRepo = getIt<IGearRepository>();
      final itineraryRepo = getIt<IItineraryRepository>();
      final allGear = gearRepo.getAllItems();
      final tripGear = allGear.where((g) => g.tripId == trip.id).toList();

      // 2. 依次上傳 Trip Meta, Itinerary, Gear
      // 先上傳 Trip 本身
      final uploadTripResult = await _tripRepository.uploadTripToRemote(trip);
      if (uploadTripResult is Failure) {
        LogService.error('Trip metadata upload failed: ${(uploadTripResult as Failure).exception}', source: _source);
        return false;
      }

      // 直接使用 ItineraryRepository 進行同步，不再透過 SyncService 包裝
      try {
        await itineraryRepo.sync(trip.id);
      } catch (e) {
        LogService.warning('Trip Itinerary sync had issues: $e', source: _source);
        // 不中斷，繼續處理 Gear
      }

      // 上傳裝備 (Trip Gear)
      try {
        final gearRemote = getIt<ITripGearRemoteDataSource>();
        await gearRemote.replaceAllTripGear(trip.id, tripGear);
      } catch (e) {
        LogService.error('Trip Gear upload failed: $e', source: _source);
        return false;
      }

      LogService.info('Full trip upload successful: ${trip.name}', source: _source);
      return true;
    } catch (e) {
      LogService.error('Full trip upload exception: $e', source: _source);
      return false;
    }
  }

  /// 透過 SyncService 取得雲端行程列表
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({String? cursor, int? limit}) {
    return _syncService.getCloudTrips(cursor: cursor, limit: limit);
  }

  /// 根據 ID 取得行程 (優先從 State 讀取，若無則查 Repo)
  Future<Trip?> getTripById(String id) async {
    if (state is TripLoaded) {
      final loadedParams = state as TripLoaded;
      try {
        return loadedParams.trips.firstWhere((t) => t.id == id);
      } catch (_) {}
    }
    final result = await _tripRepository.getTripById(id);
    return result is Success ? (result as Success<Trip?, Exception>).value : null;
  }

  // 建立預設行程 (相容 Provider 邏輯)
  Future<void> createDefaultTrip() async {
    await addTrip(name: '我的登山行程', startDate: DateTime.now());
  }

  /// 重置狀態 (例如登出時)
  void reset() {
    emit(const TripInitial());
  }
}
