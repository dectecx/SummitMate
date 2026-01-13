import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../../data/repositories/interfaces/i_gear_repository.dart';
import '../../../core/error/result.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../domain/interfaces/i_auth_service.dart';
import '../../../data/models/enums/sync_status.dart';
import 'trip_state.dart';

/// Manage Trip state and operations
class TripCubit extends Cubit<TripState> {
  static const String _source = 'TripCubit';

  final ITripRepository _tripRepository;
  final ISyncService _syncService;
  final IAuthService _authService;
  final Uuid _uuid = const Uuid();

  TripCubit({ITripRepository? tripRepository, ISyncService? syncService, IAuthService? authService})
    : _tripRepository = tripRepository ?? getIt<ITripRepository>(),
      _syncService = syncService ?? getIt<ISyncService>(),
      _authService = authService ?? getIt<IAuthService>(),
      super(const TripInitial());

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
      emit(TripError(e.toString()));
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
      emit(TripError(e.toString()));
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
      emit(TripError(e.toString()));
    }
  }

  /// 設定活動行程
  ///
  /// [tripId] 行程 ID
  Future<void> setActiveTrip(String tripId) async {
    try {
      await _setActiveTripInternal(tripId);
      await loadTrips();
    } catch (e) {
      LogService.error('Error setting active trip: $e', source: _source);
      emit(TripError(e.toString()));
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
    LogService.info('Set active trip: $tripId', source: _source);
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
      emit(TripError(e.toString()));
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
      emit(TripError(e.toString()));
    }
  }

  /// 上傳完整行程至雲端 (包含行程表與裝備)
  ///
  /// [trip] 欲上傳的行程物件
  Future<bool> uploadFullTrip(Trip trip) async {
    try {
      // 1. 蒐集資料
      // 透過 DI 存取其他 Repo，因 Cubit 無法直接存取其他 Provider
      // 理想上應透過 Service 處理，但為了維持架構一致性暫時使用 DI
      final itineraryRepo = getIt<IItineraryRepository>();
      final gearRepo = getIt<IGearRepository>();

      // 注意：目前 Repository API 缺乏依 TripID 過濾的功能，因此先全抓再過濾
      final allItineraries = itineraryRepo.getAllItems();
      final allGear = gearRepo.getAllItems();

      final tripItineraries = allItineraries.where((i) => i.tripId == trip.id).toList();
      final tripGear = allGear.where((g) => g.tripId == trip.id).toList();

      // 2. 呼叫 Repository 執行上傳
      final result = await _tripRepository.uploadFullTrip(
        trip: trip,
        itineraryItems: tripItineraries,
        gearItems: tripGear,
      );

      if (result is Failure) {
        LogService.error(
          'Full trip upload failed: ${(result as Failure).exception}',
          source: _source,
        ); // No cast needed in Dart 3 if flow analysis works, but explicit switch/case is better
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
  Future<Result<List<Trip>, Exception>> getCloudTrips() {
    return _syncService.getCloudTrips();
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
