import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';

import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../../core/error/app_error_handler.dart';
import 'sync_state.dart';

/// 管理資料同步狀態的 Cubit
@injectable
class SyncCubit extends Cubit<SyncState> with SafeEmitMixin<SyncState> {
  static const String _source = 'SyncCubit';

  final ISyncEngine _syncEngine;
  final IConnectivityService _connectivityService;

  SyncCubit(this._syncEngine, this._connectivityService) : super(const SyncInitial()) {
    _init();
  }

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<int>? _pendingCountSubscription;
  DateTime? _lastSyncTime;

  void _init() {
    _initLastSyncTime();

    // 監聽連線狀態
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (state is SyncInitial) {
        final s = state as SyncInitial;
        safeEmit(SyncInitial(lastSyncTime: s.lastSyncTime, pendingCount: s.pendingCount, isOnline: isOnline));
      } else if (state is SyncInProgress) {
        final s = state as SyncInProgress;
        safeEmit(SyncInProgress(message: s.message, pendingCount: s.pendingCount, isOnline: isOnline));
      } else if (state is SyncSuccess) {
        final s = state as SyncSuccess;
        safeEmit(
          SyncSuccess(
            timestamp: s.timestamp,
            message: s.message,
            pushedCount: s.pushedCount,
            pulledCount: s.pulledCount,
            conflictCount: s.conflictCount,
            pendingCount: s.pendingCount,
            isOnline: isOnline,
          ),
        );
      } else if (state is SyncFailure) {
        final s = state as SyncFailure;
        safeEmit(
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
    _pendingCountSubscription = _syncEngine.watchPendingSyncCount().listen((count) {
      if (state is SyncInitial) {
        final s = state as SyncInitial;
        safeEmit(SyncInitial(lastSyncTime: s.lastSyncTime, pendingCount: count, isOnline: s.isOnline));
      } else if (state is SyncInProgress) {
        final s = state as SyncInProgress;
        safeEmit(SyncInProgress(message: s.message, pendingCount: count, isOnline: s.isOnline));
      } else if (state is SyncSuccess) {
        final s = state as SyncSuccess;
        safeEmit(
          SyncSuccess(
            timestamp: s.timestamp,
            message: s.message,
            pushedCount: s.pushedCount,
            pulledCount: s.pulledCount,
            conflictCount: s.conflictCount,
            pendingCount: count,
            isOnline: s.isOnline,
          ),
        );
      } else if (state is SyncFailure) {
        final s = state as SyncFailure;
        safeEmit(
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
  void _initLastSyncTime() async {
    _lastSyncTime = await _syncEngine.getLastSyncTime();
    if (_lastSyncTime != null) {
      safeEmit(SyncInitial(lastSyncTime: _lastSyncTime, pendingCount: state.pendingCount, isOnline: state.isOnline));
    }
  }

  /// 執行完整同步
  ///
  /// [force] 是否強制執行同步 (忽略節流與最小間隔)
  Future<void> syncAll({bool force = false}) async {
    if (_connectivityService.isOffline) {
      safeEmit(
        SyncFailure(
          errorMessage: '目前處於離線模式，無法同步',
          lastSuccessTime: _lastSyncTime,
          pendingCount: state.pendingCount,
          isOnline: false,
        ),
      );
      return;
    }

    safeEmit(SyncInProgress(message: '正在同步資料...', pendingCount: state.pendingCount, isOnline: state.isOnline));
    LogService.info('Starting syncAll...', source: _source);

    try {
      final result = await _syncEngine.runSyncCycle(force: force);

      if (result.isSuccess) {
        _lastSyncTime = result.syncedAt;
        if (result.skipReason != null) {
          LogService.info('Sync skipped: ${result.skipReason}', source: _source);
          safeEmit(
            SyncSuccess(
              timestamp: result.syncedAt,
              message: '同步完成 (已略過: ${result.skipReason})',
              pendingCount: state.pendingCount,
              isOnline: state.isOnline,
            ),
          );
        } else {
          safeEmit(
            SyncSuccess(
              timestamp: result.syncedAt,
              message: '同步成功',
              pushedCount: result.pushedCount,
              pulledCount: result.pulledCount,
              conflictCount: result.conflictCount,
              pendingCount: state.pendingCount,
              isOnline: state.isOnline,
            ),
          );
        }
      } else {
        safeEmit(
          SyncFailure(
            errorMessage: result.errorMessage ?? '同步失敗',
            lastSuccessTime: _lastSyncTime,
            pendingCount: state.pendingCount,
            isOnline: state.isOnline,
          ),
        );
      }
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      safeEmit(
        SyncFailure(
          errorMessage: AppErrorHandler.getUserMessage(e),
          lastSuccessTime: _lastSyncTime,
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

  /// 上傳行程 (與雲端同步)
  Future<void> uploadItinerary() async {
    await syncAll(force: true);
  }

  /// 重置狀態
  void reset() {
    safeEmit(const SyncInitial());
  }
}
