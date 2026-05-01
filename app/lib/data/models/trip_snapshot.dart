import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'itinerary_item.dart';

part 'trip_snapshot.g.dart';

/// 行程快照
/// 用於揪團活動中展示行程預覽，通常為唯讀資料
@HiveType(typeId: 21)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TripSnapshot {
  /// 行程名稱
  @HiveField(0)
  final String name;

  /// 開始日期
  @HiveField(1)
  final DateTime startDate;

  /// 結束日期
  @HiveField(2)
  final DateTime? endDate;

  /// 行程項目列表
  @HiveField(3)
  @JsonKey(defaultValue: [])
  final List<ItineraryItemModel> itinerary;

  TripSnapshot({required this.name, required this.startDate, this.endDate, this.itinerary = const []});

  factory TripSnapshot.fromJson(Map<String, dynamic> json) => _$TripSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$TripSnapshotToJson(this);
}
