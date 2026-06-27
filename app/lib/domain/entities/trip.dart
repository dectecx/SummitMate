import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/sync_status.dart';
import '../interfaces/i_syncable_entity.dart';

import 'meal_plan_day.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

/// 行程領域實體 (Domain Entity)
///
/// 不可變物件，承載行程的業務規則
/// 不依賴持久化框架（如 Drift）
@freezed
abstract class Trip with _$Trip implements SyncableEntity {
  const Trip._();

  const factory Trip({
    required String id,
    required String userId,
    required String name,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String? coverImage,
    @Default(false) bool isActive,
    String? linkedEventId,
    @Default([]) List<String> dayNames,
    @Default([]) List<MealPlanDay> mealPlanDays,
    @Default(SyncStatus.pendingCreate) SyncStatus syncStatus,

    /// 最後一次成功上傳至雲端的時間 (null 表示從未上傳)
    DateTime? cloudSyncedAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _Trip;

  /// 行程是否已存在於雲端 (至少上傳過一次)
  bool get isCloudReady => syncStatus == SyncStatus.synced || cloudSyncedAt != null;

  /// 行程是否為純本地 (從未上傳至雲端)
  bool get isLocalOnly => syncStatus == SyncStatus.pendingCreate && cloudSyncedAt == null;

  /// 行程天數（含開始日，最少為 1 天）
  int get durationDays {
    if (endDate == null) return 1;
    final diff = endDate!.difference(startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
