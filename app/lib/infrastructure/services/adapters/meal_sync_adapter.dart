import 'package:injectable/injectable.dart';
import '../../../domain/interfaces/i_sync_adapter.dart';
import '../../../domain/enums/sync_status.dart';
import '../../../data/datasources/interfaces/i_trip_local_data_source.dart';
import '../../../data/datasources/interfaces/i_trip_meal_remote_data_source.dart';

/// 糧食計畫（Pull-only 模式）同步適配器。
///
/// `MealPlanDay` 採**遠端權威**設計：本地編輯僅暫存，
/// 同步時以遠端資料完整取代本地（`replaceMealPlanDays`）。
/// Push 操作為 no-op（糧食計畫的 CRUD 由 Repository 實時呼叫 API，
/// 不走 offline pending 流程）。
@lazySingleton
class MealSyncAdapter implements ISyncAdapter {
  final ITripLocalDataSource _tripLocalDataSource;
  final ITripMealRemoteDataSource _remoteDataSource;

  MealSyncAdapter(this._tripLocalDataSource, this._remoteDataSource);

  @override
  String get tableName => 'meal_plan_days_table';

  /// 糧食天數為遠端權威，資料表沒有 `sync_status` 欄位。
  @override
  bool get tracksSyncStatus => false;

  // ── Push (no-op) ──

  @override
  Future<SyncPushResult> pushPending() async => const SyncPushResult();

  @override
  Future<SyncPushResult> pushPendingForTrip(String tripId) async => const SyncPushResult();

  // ── Pull ──

  @override
  Future<SyncMergeResult> pullRemote() async {
    final trips = await _tripLocalDataSource.getAllTrips();
    final activeTrips = trips.where((t) => t.syncStatus != SyncStatus.pendingDelete).toList();

    var aggregate = const SyncMergeResult();
    for (final trip in activeTrips) {
      aggregate = aggregate + await _pullForTrip(trip.id);
    }
    return aggregate;
  }

  @override
  Future<SyncMergeResult> pullRemoteForTrip(String tripId) => _pullForTrip(tripId);

  // ── Private helpers ──

  Future<SyncMergeResult> _pullForTrip(String tripId) async {
    try {
      final remoteItems = await _remoteDataSource.getMealPlanDays(tripId);
      await _tripLocalDataSource.replaceMealPlanDays(tripId, remoteItems);
      return SyncMergeResult(pulledCount: remoteItems.length, remoteWinsCount: remoteItems.length);
    } catch (e) {
      return SyncMergeResult(errors: ['meal_plan_days_table ($tripId) pull 失敗: $e']);
    }
  }
}
