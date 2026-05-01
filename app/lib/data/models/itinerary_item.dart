import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/itinerary_item.dart';

part 'itinerary_item.g.dart';

/// 行程節點模型 (Persistence Model)
@HiveType(typeId: 1)
@JsonSerializable(fieldRename: FieldRename.snake)
class ItineraryItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String day;

  @HiveField(3)
  @JsonKey(defaultValue: '')
  String name;

  @HiveField(4)
  @JsonKey(fromJson: _parseEstTime, defaultValue: '')
  String estTime;

  @HiveField(5)
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime? actualTime;

  @HiveField(6)
  @JsonKey(defaultValue: 0)
  int altitude;

  @HiveField(7)
  @JsonKey(defaultValue: 0.0)
  double distance;

  @HiveField(8)
  @JsonKey(defaultValue: '')
  String note;

  @HiveField(9)
  String? imageAsset;

  @HiveField(10)
  @JsonKey(defaultValue: false, name: 'is_checked_in')
  bool isCheckedIn;

  @HiveField(11)
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime? checkedInAt;

  @HiveField(12)
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  DateTime? createdAt;

  @HiveField(13)
  @JsonKey(name: 'created_by')
  String? createdBy;

  @HiveField(14)
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  DateTime? updatedAt;

  @HiveField(15)
  @JsonKey(name: 'updated_by')
  String? updatedBy;

  ItineraryItemModel({
    required this.id,
    this.tripId = '',
    this.day = '',
    this.name = '',
    this.estTime = '',
    this.actualTime,
    this.altitude = 0,
    this.distance = 0.0,
    this.note = '',
    this.imageAsset,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  /// 轉換為 Domain Entity
  ItineraryItem toDomain() {
    return ItineraryItem(
      id: id,
      tripId: tripId,
      day: day,
      name: name,
      estTime: estTime,
      actualTime: actualTime,
      altitude: altitude,
      distance: distance,
      note: note,
      imageAsset: imageAsset,
      isCheckedIn: isCheckedIn,
      checkedInAt: checkedInAt,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Model
  factory ItineraryItemModel.fromDomain(ItineraryItem entity) {
    return ItineraryItemModel(
      id: entity.id,
      tripId: entity.tripId,
      day: entity.day,
      name: entity.name,
      estTime: entity.estTime,
      actualTime: entity.actualTime,
      altitude: entity.altitude,
      distance: entity.distance,
      note: entity.note,
      imageAsset: entity.imageAsset,
      isCheckedIn: entity.isCheckedIn,
      checkedInAt: entity.checkedInAt,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  static String _parseEstTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final str = value.toString();
    if (str.contains('T')) {
      final dt = DateTime.parse(str).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return str;
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) throw ArgumentError('Invalid date format: $value');
    return dt.toLocal();
  }

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) => _$ItineraryItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$ItineraryItemModelToJson(this);
}
