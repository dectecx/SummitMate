import 'package:hive/hive.dart';

part 'itinerary_item.g.dart';

/// 行程節點
@HiveType(typeId: 1)
class ItineraryItem extends HiveObject {
  /// 節點唯一識別碼 (PK)
  @HiveField(0)
  String uuid;

  /// 關聯的行程 ID (FK → Trip)
  @HiveField(1)
  String tripId;

  /// 行程天數，e.g., "D0", "D1", "D2"
  @HiveField(2)
  String day;

  /// 地標名稱，e.g., "向陽山屋"
  @HiveField(3)
  String name;

  /// 預計時間 (HH:mm 格式)
  @HiveField(4)
  String estTime;

  /// 實際打卡時間 (本地欄位)
  @HiveField(5)
  DateTime? actualTime;

  /// 海拔高度 (公尺)
  @HiveField(6)
  int altitude;

  /// 里程 (公里)
  @HiveField(7)
  double distance;

  /// 備註
  @HiveField(8)
  String note;

  /// 對應 assets 圖片檔名
  @HiveField(9)
  String? imageAsset;

  /// 是否已打卡
  @HiveField(10)
  bool isCheckedIn;

  /// 打卡時間
  @HiveField(11)
  DateTime? checkedInAt;

  ItineraryItem({
    this.uuid = '',
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
  });

  /// 從 JSON 建立
  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    // 解析 est_time：API 可能返回 ISO 格式，需轉為 HH:mm
    String parseEstTime(dynamic value) {
      if (value == null || value.toString().isEmpty) return '';
      final str = value.toString();
      // 如果是 ISO 格式 (包含 T)，解析並提取時間
      if (str.contains('T')) {
        try {
          final dt = DateTime.parse(str).toLocal();
          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          return str;
        }
      }
      return str;
    }

    return ItineraryItem(
      uuid: json['uuid']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      estTime: parseEstTime(json['est_time']),
      actualTime: json['actual_time'] != null ? DateTime.tryParse(json['actual_time'].toString())?.toLocal() : null,
      altitude: (json['altitude'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      note: json['note']?.toString() ?? '',
      imageAsset: json['image_asset']?.toString(),
      isCheckedIn: json['is_checked_in'] == true,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())?.toLocal()
          : null,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'trip_id': tripId,
      'day': day,
      'name': name,
      'est_time': estTime,
      'actual_time': actualTime?.toUtc().toIso8601String(),
      'altitude': altitude,
      'distance': distance,
      'note': note,
      'image_asset': imageAsset,
    };
  }
}
