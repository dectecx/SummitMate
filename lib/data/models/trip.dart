import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums/sync_status.dart';

part 'trip.g.dart';

/// 行程資料模型
/// 用於管理多個不同的登山計畫
@JsonSerializable(fieldRename: FieldRename.snake)
@HiveType(typeId: 8)
class Trip extends HiveObject {
  /// 行程 ID
  @HiveField(0)
  final String id;

  /// 所屬使用者 ID
  @HiveField(1)
  final String userId;

  /// 行程名稱
  @HiveField(2)
  String name;

  /// 開始日期
  @HiveField(3)
  @JsonKey(fromJson: _parseDate)
  DateTime startDate;

  /// 結束日期
  @HiveField(4)
  @JsonKey(fromJson: _parseDateNullable)
  DateTime? endDate;

  /// 每天的名稱 (自定義)
  @HiveField(5)
  @JsonKey(defaultValue: <String>[])
  List<String> dayNames;

  /// 行程描述
  @HiveField(6)
  String? description;

  /// 封面圖片 URL
  @HiveField(7)
  String? coverImage;

  /// 是否為當前作用中行程
  @HiveField(8)
  @JsonKey(name: 'is_active', defaultValue: false, fromJson: _parseBool)
  bool isActive;

  /// 同步狀態
  @HiveField(9)
  @JsonKey(defaultValue: SyncStatus.pendingCreate)
  SyncStatus syncStatus;

  /// 建立時間
  @HiveField(10)
  @JsonKey(fromJson: _parseDate)
  final DateTime createdAt;

  /// 建立者
  @HiveField(11)
  final String createdBy;

  /// 更新時間
  @HiveField(12)
  DateTime updatedAt;

  /// 更新者
  @HiveField(13)
  String updatedBy;

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    this.endDate,
    List<String>? dayNames,
    this.description,
    this.coverImage,
    this.isActive = false,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) : dayNames = dayNames ?? [],
       updatedAt = updatedAt ?? createdAt,
       updatedBy = updatedBy ?? createdBy;

  /// 行程天數
  int get durationDays {
    if (endDate == null) return 1;
    final diff = endDate!.difference(startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
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

  /// 從 JSON 建立 Trip 物件
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// 轉換為 JSON 物件
  Map<String, dynamic> toJson() => _$TripToJson(this);

  @override
  String toString() {
    return 'Trip(id: $id, userId: $userId, name: $name, isActive: $isActive, syncStatus: $syncStatus)';
  }
}
