import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trip.dart';
import '../../domain/enums/sync_status.dart';

part 'trip_model.g.dart';

/// 行程持久化模型 (Persistence Model)
///
/// 用於 Hive/Isar 本地儲存。
/// 業務邏輯與不可變操作請使用 [Trip]（domain/entities/trip.dart）。
@JsonSerializable(fieldRename: FieldRename.snake)
@HiveType(typeId: 8)
class TripModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? description;

  @HiveField(4)
  @JsonKey(fromJson: _parseDate)
  DateTime startDate;

  @HiveField(5)
  @JsonKey(fromJson: _parseDateNullable)
  DateTime? endDate;

  @HiveField(6)
  String? coverImage;

  @HiveField(7)
  @JsonKey(name: 'is_active', defaultValue: false, fromJson: _parseBool)
  bool isActive;

  @HiveField(8)
  @JsonKey(name: 'linked_event_id')
  String? linkedEventId;

  @HiveField(9)
  @JsonKey(defaultValue: <String>[])
  List<String> dayNames;

  @HiveField(10)
  @JsonKey(defaultValue: SyncStatus.pendingCreate)
  SyncStatus syncStatus;

  @HiveField(11)
  @JsonKey(fromJson: _parseDate)
  final DateTime createdAt;

  @HiveField(12)
  final String createdBy;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  String updatedBy;

  TripModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    this.coverImage,
    this.isActive = false,
    this.linkedEventId,
    List<String>? dayNames,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  }) : dayNames = dayNames ?? [];

  /// 轉換為 Domain Entity
  Trip toDomain() {
    return Trip(
      id: id,
      userId: userId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      coverImage: coverImage,
      isActive: isActive,
      linkedEventId: linkedEventId,
      dayNames: dayNames,
      syncStatus: syncStatus,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  /// 從 Domain Entity 建立 Persistence Model
  factory TripModel.fromDomain(Trip entity) {
    return TripModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      startDate: entity.startDate,
      endDate: entity.endDate,
      coverImage: entity.coverImage,
      isActive: entity.isActive,
      linkedEventId: entity.linkedEventId,
      dayNames: List.from(entity.dayNames),
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  /// 解析布林值 (處理字串 "true"/"false")
  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value is String) return value.toUpperCase() == 'TRUE';
    return false;
  }

  /// 解析日期
  static DateTime _parseDate(dynamic value) {
    if (value == null || value == '') throw ArgumentError('Date is required');
    if (value is DateTime) return value;
    return DateTime.parse(value.toString()).toLocal();
  }

  /// 解析可空日期
  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null || value == '') return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  factory TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);
  Map<String, dynamic> toJson() => _$TripModelToJson(this);

  @override
  String toString() => 'TripModel(id: $id, name: $name, isActive: $isActive)';
}
