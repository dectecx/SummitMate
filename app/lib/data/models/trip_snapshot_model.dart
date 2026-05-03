import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'itinerary_item_model.dart';
import '../../domain/entities/trip_snapshot.dart';

part 'trip_snapshot_model.g.dart';

/// 行程快照持久化模型 (Persistence Model)
@HiveType(typeId: 18)
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TripSnapshotModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime? endDate;

  @HiveField(3)
  @JsonKey(defaultValue: [])
  final List<ItineraryItemModel> itinerary;

  TripSnapshotModel({required this.name, required this.startDate, this.endDate, this.itinerary = const []});

  /// 轉換為 Domain Entity
  TripSnapshot toDomain() {
    return TripSnapshot(
      name: name,
      startDate: startDate,
      endDate: endDate,
      itinerary: itinerary.map((i) => i.toDomain()).toList(),
    );
  }

  /// 從 Domain Entity 建立 Model
  factory TripSnapshotModel.fromDomain(TripSnapshot entity) {
    return TripSnapshotModel(
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      itinerary: entity.itinerary.map((i) => ItineraryItemModel.fromDomain(i)).toList(),
    );
  }

  factory TripSnapshotModel.fromJson(Map<String, dynamic> json) => _$TripSnapshotModelFromJson(json);

  Map<String, dynamic> toJson() => _$TripSnapshotModelToJson(this);
}
