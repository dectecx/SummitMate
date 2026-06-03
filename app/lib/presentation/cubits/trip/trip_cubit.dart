import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../core/core.dart';
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
  final ISyncEngine _syncEngine;

  static const String _source = 'TripCubit';

  StreamSubscription<String>? _tripUpdateSubscription;

  TripCubit(this._tripRepository, this._authService, this._syncEngine) : super(const TripInitial()) {
    _tripUpdateSubscription = _tripRepository.tripUpdateStream.listen((tripId) {
      // 當行程更新時，重新載入列表以更新 UI 狀態 (如 SyncStatus)
      loadTrips();
    });
  }

  @override
  Future<void> close() {
    _tripUpdateSubscription?.cancel();
    return super.close();
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
      final result = await _syncEngine.getCloudTrips();
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
      final result = await _syncEngine.runSyncCycle(force: true);
      await loadTrips();
      return result.isSuccess;
    } catch (e) {
      LogService.error('Full trip upload exception: $e', source: _source);
      return false;
    }
  }

  /// 從雲端下載整個行程的資料到本地 (Metadata + Itinerary + Gear)
  Future<bool> downloadFullTrip(Trip trip) async {
    try {
      final result = await _syncEngine.runSyncCycle(force: true);
      await loadTrips();
      return result.isSuccess;
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
