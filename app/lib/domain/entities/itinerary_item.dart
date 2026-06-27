import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/sync_status.dart';
import '../interfaces/i_syncable_entity.dart';

part 'itinerary_item.freezed.dart';
part 'itinerary_item.g.dart';

/// 行程節點實體 (Domain Entity)
@freezed
abstract class ItineraryItem with _$ItineraryItem implements SyncableEntity {
  const ItineraryItem._();

  const factory ItineraryItem({
    required String id,
    required String tripId,
    required String day,
    required String name,
    required String estTime,
    DateTime? actualTime,
    @Default(0) int altitude,
    @Default(0.0) double distance,
    @Default('') String note,
    String? imageAsset,
    @Default(false) bool isCheckedIn,
    DateTime? checkedInAt,
    @Default(SyncStatus.synced) SyncStatus syncStatus,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);
}
