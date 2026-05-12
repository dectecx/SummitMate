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
  ) : super(const TripInitial());

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
      final updatedTrip = trip.copyWith(updatedAt: DateTime.now(), updatedBy: _authService.currentUserId ?? '');
      final result = await _tripRepository.saveTrip(updatedTrip);
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
    try {
      final allGear = await _gearRepository.getAllItems();
      final tripGear = allGear.where((g) => g.tripId == trip.id).toList();

      final uploadTripResult = await _tripRepository.uploadToCloud(trip);
      if (uploadTripResult is Failure) {
        LogService.error('Trip metadata upload failed: ${(uploadTripResult as Failure).exception}', source: _source);
        return false;
      }

      try {
        await _itineraryRepository.sync(trip.id);
      } catch (e) {
        LogService.warning('Trip Itinerary sync had issues: $e', source: _source);
      }

      try {
        await _gearRemoteDataSource.replaceAllTripGear(trip.id, tripGear);
      } catch (e) {
        LogService.error('Trip Gear upload failed: $e', source: _source);
        return false;
      }

      // 上傳成功後，更新本地行程的同步狀態
      final now = DateTime.now();
      final updatedTrip = trip.copyWith(
        syncStatus: SyncStatus.synced,
        cloudSyncedAt: now,
        updatedAt: now,
      );
      await _tripRepository.saveTrip(updatedTrip);
      await loadTrips(); // 刷新 UI 狀態

      LogService.info('Full trip upload successful: ${trip.name}', source: _source);
      return true;
    } catch (e) {
      LogService.error('Full trip upload exception: $e', source: _source);
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
    final trip = (state as TripLoaded).activeTrip;
    if (trip == null) return false;
    return uploadFullTrip(trip);
  }
}
