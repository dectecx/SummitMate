import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../core/core.dart';
import '../../../data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/di/injection.dart';
import '../../../infrastructure/infrastructure.dart';
import '../app_error/app_error_cubit.dart';
import 'trip_state.dart';

/// Manage Trip state and operations
@injectable
class TripCubit extends Cubit<TripState> {
  final ITripRepository _tripRepository;
  final IAuthService _authService;
  final IGearRepository _gearRepository;
  final IItineraryRepository _itineraryRepository;
  final ITripGearRemoteDataSource _gearRemoteDataSource;

  static const String _source = 'TripCubit';

  TripCubit(
    this._tripRepository,
    this._authService,
    this._gearRepository,
    this._itineraryRepository,
    this._gearRemoteDataSource,
  ) : super(const TripInitial()) {
    _tripRepository.tripUpdateStream.listen((tripId) {
      // 當行程更新時，重新載入列表以更新 UI 狀態 (如 SyncStatus)
      loadTrips();
    });
  }

  /// 載入行程列表
  Future<void> loadTrips() async {
    emit(const TripLoading());
    try {
      final result = await _tripRepository.getAllTrips(_authService.currentUserId ?? '');

      if (result is Success<List<Trip>, Exception>) {
        final trips = result.value;
        final activeTripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? '');

        Trip? activeTrip;
        if (activeTripResult is Success<Trip?, Exception>) {
          activeTrip = activeTripResult.value;
        }

        emit(TripLoaded(trips: trips, activeTrip: activeTrip));
      } else {
        final error = (result as Failure).exception;
        getIt<AppErrorCubit>().reportError(error);
        emit(TripError(AppErrorHandler.getUserMessage(error)));
      }
    } catch (e) {
      LogService.error('載入行程失敗: $e', source: _source);
      getIt<AppErrorCubit>().reportError(e);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 新增行程
  Future<Trip?> addTrip({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
  }) async {
    try {
      final newTrip = Trip(
        id: const Uuid().v7(),
        userId: _authService.currentUserId ?? '',
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: DateTime.now(),
        createdBy: _authService.currentUserId ?? '',
        updatedAt: DateTime.now(),
        updatedBy: _authService.currentUserId ?? '',
      );

      final result = await _tripRepository.saveTrip(newTrip);
      if (result is Success) {
        await _tripRepository.setActiveTrip(_authService.currentUserId ?? '', newTrip.id);
        await loadTrips();
        return newTrip;
      } else {
        emit(TripError(AppErrorHandler.getUserMessage((result as Failure).exception)));
        return null;
      }
    } catch (e) {
      LogService.error('新增行程失敗: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
      return null;
    }
  }

  /// 更新行程
  Future<void> updateTrip(Trip trip) async {
    try {
      final newStatus = trip.syncStatus == SyncStatus.synced ? SyncStatus.pendingUpdate : trip.syncStatus;
      final updatedTrip = trip.copyWith(
        syncStatus: newStatus,
        updatedAt: DateTime.now(),
        updatedBy: _authService.currentUserId ?? '',
      );
      final result = await _tripRepository.saveTrip(updatedTrip);

      // 手動更新當前狀態中的 trips 列表與 activeTrip，確保 UI 立即反映變更
      if (result is Success && state is TripLoaded) {
        final currentState = state as TripLoaded;
        final updatedTrips = currentState.trips.map((t) => t.id == updatedTrip.id ? updatedTrip : t).toList();
        emit(
          currentState.copyWith(
            trips: updatedTrips,
            activeTrip: currentState.activeTrip?.id == updatedTrip.id ? updatedTrip : currentState.activeTrip,
          ),
        );
      }

      if (result is Success) {
        await loadTrips();
      } else {
        emit(TripError(AppErrorHandler.getUserMessage((result as Failure).exception)));
      }
    } catch (e) {
      LogService.error('更新行程失敗: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 取得特定行程
  Future<Trip?> getTripById(String id) async {
    final result = await _tripRepository.getTripById(id);
    if (result is Success<Trip?, Exception>) {
      return result.value;
    }
    return null;
  }

  /// 設定目前活躍行程
  Future<void> setActiveTrip(String tripId) async {
    emit(const TripLoading());
    try {
      final result = await _tripRepository.setActiveTrip(_authService.currentUserId ?? '', tripId);
      if (result is Success) {
        await loadTrips();
      } else {
        emit(TripError(AppErrorHandler.getUserMessage((result as Failure).exception)));
      }
    } catch (e) {
      LogService.error('設定活躍行程失敗: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 建立預設行程
  Future<void> createDefaultTrip() async {
    await addTrip(name: '我的第一趟旅程', startDate: DateTime.now(), description: '自動建立的行程');
  }

  /// 重置狀態
  void reset() {
    emit(const TripInitial());
  }

  /// 匯入行程
  Future<void> importTrip(Trip trip) async {
    emit(const TripLoading());
    try {
      final newTrip = trip.copyWith(
        id: const Uuid().v7(),
        userId: _authService.currentUserId ?? '',
        isActive: false,
        syncStatus: SyncStatus.pendingCreate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _tripRepository.saveTrip(newTrip);
      if (result is Success) {
        await loadTrips();
      } else {
        emit(TripError(AppErrorHandler.getUserMessage((result as Failure).exception)));
      }
    } catch (e) {
      LogService.error('匯入行程失敗: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 取得雲端行程列表
  Future<Result<List<Trip>, Exception>> getCloudTrips() async {
    try {
      final result = await _tripRepository.getRemoteTrips();
      return switch (result) {
        Success(value: final v) => Success(v.items),
        Failure(exception: final e) => Failure(e),
      };
    } catch (e) {
      LogService.error('取得雲端行程失敗: $e', source: _source);
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 刪除行程
  Future<void> deleteTrip(String id) async {
    try {
      final result = await _tripRepository.deleteTrip(id);
      if (result is Success) {
        await loadTrips();
      } else {
        emit(TripError(AppErrorHandler.getUserMessage((result as Failure).exception)));
      }
    } catch (e) {
      LogService.error('刪除行程失敗: $e', source: _source);
      emit(TripError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 上傳整個行程的資料到雲端 (Metadata + Itinerary + Gear)
  Future<bool> uploadFullTrip(Trip trip) async {
    // 如果已經同步過且沒有待更新的變更，直接返回成功
    if (trip.syncStatus == SyncStatus.synced && trip.cloudSyncedAt != null) {
      return true;
    }

    try {
      final allGear = await _gearRepository.getAllItems();
      final tripGear = allGear.where((g) => g.tripId == trip.id).toList();

      // 1. 上傳行程 Metadata 並取得後端產生的 ID
      final uploadTripResult = await _tripRepository.uploadToCloud(trip);
      if (uploadTripResult is Failure) {
        LogService.error('Trip metadata upload failed: ${(uploadTripResult as Failure).exception}', source: _source);
        return false;
      }

      final serverTripId = (uploadTripResult as Success<String, Exception>).value;
      var finalTripId = trip.id;

      // 2. 如果後端傳回的 ID 與本地不同，則需要進行本地資料遷移
      if (serverTripId != trip.id) {
        LogService.info('Migrating local trip ID from ${trip.id} to $serverTripId', source: _source);
        final migrateResult = await _tripRepository.updateLocalTripId(trip.id, serverTripId);
        if (migrateResult is Failure) {
          LogService.error('Local trip ID migration failed: ${migrateResult.exception}', source: _source);
          return false;
        }
        finalTripId = serverTripId;
      }

      // 3. 同步行程節點
      try {
        await _itineraryRepository.sync(finalTripId);
      } catch (e) {
        LogService.warning('Trip Itinerary sync had issues: $e', source: _source);
      }

      // 4. 上傳裝備
      try {
        // 確保裝備物件也對應到新的 Trip ID
        final updatedTripGear = tripGear.map((g) => g.copyWith(tripId: finalTripId)).toList();
        await _gearRemoteDataSource.replaceAllTripGear(finalTripId, updatedTripGear);
      } catch (e) {
        LogService.error('Trip Gear upload failed: $e', source: _source);
        return false;
      }

      // 5. 上傳成功後，更新本地行程的同步狀態
      final now = DateTime.now();
      final updatedTrip = trip.copyWith(
        id: finalTripId,
        syncStatus: SyncStatus.synced,
        cloudSyncedAt: now,
        updatedAt: now,
      );
      final saveResult = await _tripRepository.saveTrip(updatedTrip);
      if (saveResult is Failure) {
        LogService.error('Failed to save updated trip: ${saveResult.exception}', source: _source);
        return false;
      }

      // 手動更新當前狀態中的 trips 列表與 activeTrip，確保 UI 立即反映變更
      if (state is TripLoaded) {
        final currentState = state as TripLoaded;
        final updatedTrips = currentState.trips
            .map((t) => t.id == trip.id || t.id == finalTripId ? updatedTrip : t)
            .toList();
        emit(currentState.copyWith(trips: updatedTrips, activeTrip: updatedTrip));
      }

      await loadTrips();
      LogService.info('Full trip upload successful: ${trip.name}', source: _source);
      return true;
    } catch (e) {
      LogService.error('Full trip upload exception: $e', source: _source);
      return false;
    }
  }

  /// 從雲端下載整個行程的資料到本地 (Metadata + Itinerary + Gear)
  Future<bool> downloadFullTrip(Trip trip) async {
    try {
      final tripResult = await _tripRepository.syncTripDetails(trip.id);
      if (tripResult is Failure) {
        LogService.error('Trip metadata download failed: ${(tripResult as Failure).exception}', source: _source);
        return false;
      }

      try {
        await _itineraryRepository.sync(trip.id);
      } catch (e) {
        LogService.warning('Trip Itinerary sync download had issues: $e', source: _source);
      }

      try {
        await _tripRepository.syncMealPlan(trip.id);
      } catch (e) {
        LogService.warning('Trip MealPlan sync download had issues: $e', source: _source);
      }

      try {
        await _gearRepository.sync(trip.id);
      } catch (e) {
        LogService.error('Trip Gear sync download failed: $e', source: _source);
        return false;
      }

      await loadTrips(); // 刷新 UI 狀態
      LogService.info('Full trip download successful: ${trip.name}', source: _source);
      return true;
    } catch (e) {
      LogService.error('Full trip download exception: $e', source: _source);
      return false;
    }
  }

  /// 檢查當前活動行程是否已同步到雲端
  ///
  /// 供 CloudGuard 等元件使用，快速判斷是否可使用雲端功能
  bool isActiveTripCloudReady() {
    if (state is! TripLoaded) return false;
    return (state as TripLoaded).isActiveTripCloudReady;
  }

  /// 快速上傳當前活動行程至雲端
  ///
  /// 適用於 CloudGuard / CloudSyncBanner 的一鍵上傳場景
  Future<bool> uploadActiveTrip() async {
    if (state is! TripLoaded) return false;
    final currentState = state as TripLoaded;
    final trip = currentState.activeTrip;
    if (trip == null) return false;
    return uploadFullTrip(trip);
  }
}

/// 同步方向
enum SyncDirection {
  /// 上傳 (本地覆蓋雲端)
  upload,

  /// 下載 (雲端覆蓋本地)
  download,
}
