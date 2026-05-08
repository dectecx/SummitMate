import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import 'package:summitmate/domain/domain.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import 'sync_state.dart';

/// 管理資料同步狀態的 Cubit
@injectable
class SyncCubit extends Cubit<SyncState> {
  static const String _source = 'SyncCubit';

  final ISyncService _syncService;
  final IConnectivityService _connectivityService;
  final IItineraryRepository _itineraryRepository;
  final IAuthService _authService;
  final ITripRepository _tripRepository;

  SyncCubit(
    this._syncService,
    this._connectivityService,
    this._itineraryRepository,
    this._authService,
    this._tripRepository,
  ) : super(const SyncInitial()) {
    _init();
  }

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<int>? _pendingCountSubscription;

  void _init() {
    _initLastSyncTime();

    // 監聽連線狀態
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (state is SyncInitial) {
        final s = state as SyncInitial;
        emit(SyncInitial(lastSyncTime: s.lastSyncTime, pendingCount: s.pendingCount, isOnline: isOnline));
      } else if (state is SyncInProgress) {
        final s = state as SyncInProgress;
        emit(SyncInProgress(message: s.message, pendingCount: s.pendingCount, isOnline: isOnline));
      } else if (state is SyncSuccess) {
        final s = state as SyncSuccess;
        emit(SyncSuccess(timestamp: s.timestamp, message: s.message, pendingCount: s.pendingCount, isOnline: isOnline));
      } else if (state is SyncFailure) {
        final s = state as SyncFailure;
        emit(
          SyncFailure(
            errorMessage: s.errorMessage,
            lastSuccessTime: s.lastSuccessTime,
            pendingCount: s.pendingCount,
            isOnline: isOnline,
          ),
        );
      }

      if (isOnline) {
        if (state is SyncFailure && (state as SyncFailure).errorMessage.contains('離線')) {
          LogService.info('網路恢復，自動觸發同步...', source: _source);
          syncAll(force: false);
        }
      }
    });

    // 監聽待同步項目數量
    _pendingCountSubscription = _syncService.watchPendingSyncCount().listen((count) {
      if (state is SyncInitial) {
        final s = state as SyncInitial;
        emit(SyncInitial(lastSyncTime: s.lastSyncTime, pendingCount: count, isOnline: s.isOnline));
      } else if (state is SyncInProgress) {
        final s = state as SyncInProgress;
        emit(SyncInProgress(message: s.message, pendingCount: count, isOnline: s.isOnline));
      } else if (state is SyncSuccess) {
        final s = state as SyncSuccess;
        emit(SyncSuccess(timestamp: s.timestamp, message: s.message, pendingCount: count, isOnline: s.isOnline));
      } else if (state is SyncFailure) {
        final s = state as SyncFailure;
        emit(
          SyncFailure(
            errorMessage: s.errorMessage,
            lastSuccessTime: s.lastSuccessTime,
            pendingCount: count,
            isOnline: s.isOnline,
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _pendingCountSubscription?.cancel();
    return super.close();
  }

  /// 初始化上次同步時間
  void _initLastSyncTime() {
    final lastSync = _syncService.lastItinerarySync;
    if (lastSync != null) {
      emit(SyncInitial(lastSyncTime: lastSync, pendingCount: state.pendingCount, isOnline: state.isOnline));
    }
  }

  /// 執行完整同步
  ///
  /// [force] 是否強制執行同步 (忽略節流與最小間隔)
  Future<void> syncAll({bool force = false}) async {
    if (_connectivityService.isOffline) {
      emit(
        SyncFailure(
          errorMessage: '目前處於離線模式，無法同步',
          lastSuccessTime: _getLastSyncTime(),
          pendingCount: state.pendingCount,
          isOnline: false,
        ),
      );
      return;
    }

    emit(SyncInProgress(message: '正在同步資料...', pendingCount: state.pendingCount, isOnline: state.isOnline));
    LogService.info('Starting syncAll...', source: _source);

    try {
      final result = await _syncService.syncAll(isAuto: !force);

      if (result.isSuccess) {
        if (result.skipReason != null) {
          LogService.info('Sync skipped: ${result.skipReason}', source: _source);
          emit(
            SyncSuccess(
              timestamp: result.syncedAt,
              message: '同步完成 (已略過)',
              pendingCount: state.pendingCount,
              isOnline: state.isOnline,
            ),
          );
        } else {
          emit(
            SyncSuccess(
              timestamp: result.syncedAt,
              message: '同步成功',
              pendingCount: state.pendingCount,
              isOnline: state.isOnline,
            ),
          );
        }
      } else {
        emit(
          SyncFailure(
            errorMessage: result.errorMessage ?? '同步失敗',
            lastSuccessTime: _getLastSyncTime(),
            pendingCount: state.pendingCount,
            isOnline: state.isOnline,
          ),
        );
      }
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      emit(
        SyncFailure(
          errorMessage: '同步發生錯誤',
          lastSuccessTime: _getLastSyncTime(),
          pendingCount: state.pendingCount,
          isOnline: state.isOnline,
        ),
      );
    }
  }

  /// 檢查行程衝突 (目前固定回傳無衝突)
  Future<bool> checkItineraryConflict() async {
    return false;
  }

  /// 上傳行程 (強製觸發同步)
  Future<void> uploadItinerary() async {
    if (_connectivityService.isOffline) {
      emit(
        SyncFailure(
          errorMessage: '目前處於離線模式，無法上傳',
          lastSuccessTime: _getLastSyncTime(),
          pendingCount: state.pendingCount,
          isOnline: false,
        ),
      );
      return;
    }

    // 取得當前活動行程 ID
    final activeTrip = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final tripId = activeTrip is Success<Trip?, Exception> ? activeTrip.value?.id : null;

    if (tripId == null) {
      emit(
        SyncFailure(
          errorMessage: '找不到活動行程',
          lastSuccessTime: _getLastSyncTime(),
          pendingCount: state.pendingCount,
          isOnline: state.isOnline,
        ),
      );
      return;
    }

    emit(SyncInProgress(message: '正在上傳行程...', pendingCount: state.pendingCount, isOnline: state.isOnline));
    try {
      final result = await _itineraryRepository.sync(tripId);
      if (result is Success) {
        emit(
          SyncSuccess(
            timestamp: DateTime.now(),
            message: '行程上傳成功',
            pendingCount: state.pendingCount,
            isOnline: state.isOnline,
          ),
        );
      } else {
        emit(
          SyncFailure(
            errorMessage: '上傳失敗',
            lastSuccessTime: _getLastSyncTime(),
            pendingCount: state.pendingCount,
            isOnline: state.isOnline,
          ),
        );
      }
    } catch (e) {
      LogService.error('Upload failed: $e', source: _source);
      emit(
        SyncFailure(
          errorMessage: '上傳發生錯誤',
          lastSuccessTime: _getLastSyncTime(),
          pendingCount: state.pendingCount,
          isOnline: state.isOnline,
        ),
      );
    }
  }

  DateTime? _getLastSyncTime() {
    return _syncService.lastItinerarySync;
  }
}
