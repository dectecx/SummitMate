import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/sync_status.dart';

part 'gear_library_item.freezed.dart';
part 'gear_library_item.g.dart';

/// 裝備庫實體 (Domain Entity)
@freezed
abstract class GearLibraryItem with _$GearLibraryItem {
  const GearLibraryItem._();

  const factory GearLibraryItem({
    required String id,
    required String userId,
    required String name,
    required double weight,
    required String category,
    String? notes,
    @Default(false) bool isArchived,
    @Default(SyncStatus.pendingCreate) SyncStatus syncStatus,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _GearLibraryItem;

  /// 重量轉換為公斤
  double get weightInKg => weight / 1000;

  factory GearLibraryItem.fromJson(Map<String, dynamic> json) => _$GearLibraryItemFromJson(json);
}
