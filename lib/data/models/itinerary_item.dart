import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'itinerary_item.g.dart';

/// 行程節點
@HiveType(typeId: 1)
@JsonSerializable(fieldRename: FieldRename.snake)
class ItineraryItem extends HiveObject {
  /// 節點唯一識別碼 (PK)
  @HiveField(0)
  String id;

  /// 關聯的行程 ID (FK → Trip)
  @HiveField(1)
  String tripId;

  /// 行程天數，e.g., "D0", "D1", "D2"
  @HiveField(2)
  @JsonKey(defaultValue: '')
  String day;

  /// 地標名稱，e.g., "向陽山屋"
  @HiveField(3)
  @JsonKey(defaultValue: '')
  String name;

  /// 預計時間 (HH:mm 格式)
  @HiveField(4)
  @JsonKey(fromJson: _parseEstTime, defaultValue: '')
  String estTime;

  /// 實際打卡時間 (本地欄位)
  @HiveField(5)
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime? actualTime;

  /// 海拔高度 (公尺)
  @HiveField(6)
  @JsonKey(defaultValue: 0)
  int altitude;

  /// 里程 (公里)
  @HiveField(7)
  @JsonKey(defaultValue: 0.0)
  double distance;

  /// 備註
  @HiveField(8)
  @JsonKey(defaultValue: '')
  String note;

  /// 對應 assets 圖片檔名
  @HiveField(9)
  String? imageAsset;

  /// 是否已打卡
  @HiveField(10)
  @JsonKey(defaultValue: false, name: 'is_checked_in')
  bool isCheckedIn;

  /// 打卡時間
  @HiveField(11)
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime? checkedInAt;

  /// 建立者 ID
  @HiveField(12)
  @JsonKey(name: 'created_by')
  String? createdBy;

  /// 更新者 ID
  @HiveField(13)
  @JsonKey(name: 'updated_by')
  String? updatedBy;

  ItineraryItem({
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
    this.createdBy,
    this.updatedBy,
  });

  /// 解析 est_time：API 可能返回 ISO 格式，需轉為 HH:mm
  static String _parseEstTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final str = value.toString();
    // 如果是 ISO 格式 (包含 T)，解析並提取時間
    if (str.contains('T')) {
      final dt = DateTime.parse(str).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return str;
  }

  /// DateTime 解析
  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) throw ArgumentError('Invalid date format: $value');
    return dt.toLocal();
  }

  /// 從 JSON 建立
  factory ItineraryItem.fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);

  /// 轉換為 JSON
  Map<String, dynamic> toJson() => _$ItineraryItemToJson(this);
}
