import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'sync_state.dart';

/// 管理資料同步狀態的 Cubit
class SyncCubit extends Cubit<SyncState> {
  static const String _source = 'SyncCubit';

  final ISyncService _syncService;
  final IConnectivityService _connectivityService;

  SyncCubit({ISyncService? syncService, IConnectivityService? connectivityService})
    : _syncService = syncService ?? getIt<ISyncService>(),
      _connectivityService = connectivityService ?? getIt<IConnectivityService>(),
      super(const SyncInitial()) {
    _initLastSyncTime();
  }

  /// 初始化上次同步時間
  void _initLastSyncTime() {
    final lastSync = _syncService.lastItinerarySync;
    if (lastSync != null) {
      emit(SyncInitial(lastSyncTime: lastSync));
    }
  }

  /// 執行完整同步
  Future<void> syncAll({bool force = false}) async {
    if (_connectivityService.isOffline) {
      emit(SyncFailure(errorMessage: '目前處於離線模式，無法同步', lastSuccessTime: _getLastSyncTime()));
      return;
    }

    emit(const SyncInProgress(message: '正在同步資料...'));
    LogService.info('Starting syncAll...', source: _source);

    try {
      final result = await _syncService.syncAll(isAuto: !force);

      if (result.isSuccess) {
        if (result.skipReason != null) {
          // 被節流或跳過，視為成功但不更新 UI 顯示強烈訊息
          LogService.info('Sync skipped: ${result.skipReason}', source: _source);
          emit(SyncSuccess(timestamp: result.syncedAt, message: '同步完成 (已略過)'));
        } else {
          emit(SyncSuccess(timestamp: result.syncedAt, message: '同步成功'));
        }
      } else {
        emit(SyncFailure(errorMessage: result.errorMessage ?? '同步失敗', lastSuccessTime: _getLastSyncTime()));
      }
    } catch (e) {
      LogService.error('Sync failed: $e', source: _source);
      emit(SyncFailure(errorMessage: '同步發生錯誤', lastSuccessTime: _getLastSyncTime()));
    }
  }

  /// 同步行程資料
  Future<void> syncItinerary() async {
    await syncAll();
  }

  /// 檢查行程衝突
  Future<bool> checkItineraryConflict() async {
    try {
      return await _syncService.checkItineraryConflict();
    } catch (e) {
      LogService.error('Check conflict failed: $e', source: _source);
      return false;
    }
  }

  /// 上傳行程 (覆寫雲端)
  Future<void> uploadItinerary() async {
    if (_connectivityService.isOffline) {
      emit(SyncFailure(errorMessage: '目前處於離線模式，無法上傳', lastSuccessTime: _getLastSyncTime()));
      return;
    }

    emit(const SyncInProgress(message: '正在上傳行程...'));
    try {
      final result = await _syncService.uploadItinerary();
      if (result.isSuccess) {
        emit(SyncSuccess(timestamp: DateTime.now(), message: '行程上傳成功'));
      } else {
        emit(SyncFailure(errorMessage: result.errorMessage ?? '上傳失敗', lastSuccessTime: _getLastSyncTime()));
      }
    } catch (e) {
      LogService.error('Upload failed: $e', source: _source);
      emit(SyncFailure(errorMessage: '上傳發生錯誤', lastSuccessTime: _getLastSyncTime()));
    }
  }

  DateTime? _getLastSyncTime() {
    return _syncService.lastItinerarySync;
  }
}
