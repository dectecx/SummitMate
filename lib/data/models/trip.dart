import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trip.g.dart';

/// 行程 (Trip) 模型
/// 用於管理多個不同的登山計畫
@HiveType(typeId: 10)
@JsonSerializable(fieldRename: FieldRename.snake)
class Trip extends HiveObject {
  /// 行程唯一識別碼 (UUID)
  @HiveField(0)
  @JsonKey(readValue: _readId, name: 'trip_id')
  String id;

  /// 行程名稱，e.g., "2024 嘉明湖三日"
  @HiveField(1)
  @JsonKey(defaultValue: '')
  String name;

  /// 行程開始日期
  @HiveField(2)
  @JsonKey(fromJson: _parseDate)
  DateTime startDate;

  /// 行程結束日期 (可選)
  @HiveField(3)
  @JsonKey(fromJson: _parseDateNullable)
  DateTime? endDate;

  /// 行程描述/備註
  @HiveField(4)
  String? description;

  /// 封面圖片 (asset 路徑或 URL)
  @HiveField(5)
  String? coverImage;

  /// 是否為當前啟用的行程
  @HiveField(6)
  @JsonKey(name: 'is_active', defaultValue: false, fromJson: _parseBool)
  bool isActive;

  /// 建立時間
  @HiveField(7)
  @JsonKey(fromJson: _parseDateWithDefault)
  DateTime createdAt;

  /// 自訂天數名稱列表 (有序)
  /// 若為空，則依賴 startDate/endDate 自動生成 D1, D2...
  @HiveField(8)
  @JsonKey(defaultValue: <String>[])
  List<String> dayNames;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.description,
    this.coverImage,
    this.isActive = false,
    DateTime? createdAt,
    List<String>? dayNames,
  }) : createdAt = createdAt ?? DateTime.now(),
       dayNames = dayNames ?? [];

  /// 行程天數
  int get durationDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// 讀取 ID，支援 'trip_id' 或 'id'
  static Object? _readId(Map map, String key) {
    return map['trip_id'] ?? map['id'] ?? '';
  }

  /// 解析布林值 (支援 'TRUE' 字串)
  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value is String) {
      return value.toUpperCase() == 'TRUE';
    }
    return false;
  }

  /// 解析日期 (必填，空字串預設為 now)
  static DateTime _parseDate(dynamic value) {
    if (value == null || value == '') return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  /// 解析日期 (可選，空字串返回 null)
  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null || value == '') return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// 解析日期 (預設為 now)
  static DateTime _parseDateWithDefault(dynamic value) {
    if (value == null || value == '') return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// 從 JSON 建立
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$TripToJson(this);

  @override
  String toString() => 'Trip(id: $id, name: $name, isActive: $isActive)';
}
