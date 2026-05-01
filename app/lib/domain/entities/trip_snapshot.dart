import 'package:freezed_annotation/freezed_annotation.dart';
import 'itinerary_item.dart';

part 'trip_snapshot.freezed.dart';
part 'trip_snapshot.g.dart';

/// 行程快照領域實體 (Domain Entity)
/// 用於揪團活動中展示行程預覽
@freezed
abstract class TripSnapshot with _$TripSnapshot {
  const factory TripSnapshot({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    @Default([]) List<ItineraryItem> itinerary,
  }) = _TripSnapshot;

  factory TripSnapshot.fromJson(Map<String, dynamic> json) => _$TripSnapshotFromJson(json);
}
