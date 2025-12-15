import 'package:hive/hive.dart';

part 'itinerary_item.g.dart';

/// 行程節點
@HiveType(typeId: 1)
class ItineraryItem extends HiveObject {
  /// 行程天數，e.g., "D0", "D1", "D2"
  @HiveField(0)
  String day;

  /// 地標名稱，e.g., "向陽山屋"
  @HiveField(1)
  String name;

  /// 預計時間 (HH:mm 格式)
  @HiveField(2)
  String estTime;

  /// 實際打卡時間 (本地欄位)
  @HiveField(3)
  DateTime? actualTime;

  /// 海拔高度 (公尺)
  @HiveField(4)
  int altitude;

  /// 里程 (公里)
  @HiveField(5)
  double distance;

  /// 備註
  @HiveField(6)
  String note;

  /// 對應 assets 圖片檔名
  @HiveField(7)
  String? imageAsset;

  ItineraryItem({
    this.day = '',
    this.name = '',
    this.estTime = '',
    this.actualTime,
    this.altitude = 0,
    this.distance = 0.0,
    this.note = '',
    this.imageAsset,
  });

  /// 是否已打卡
  bool get isCheckedIn => actualTime != null;

  /// 從 JSON 建立
  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    // 解析 est_time：API 可能返回 ISO 格式，需轉為 HH:mm
    String parseEstTime(dynamic value) {
      if (value == null || value.toString().isEmpty) return '';
      final str = value.toString();
      // 如果是 ISO 格式 (包含 T)，解析並提取時間
      if (str.contains('T')) {
        try {
          final dt = DateTime.parse(str);
          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          return str;
        }
      }
      return str;
    }

    return ItineraryItem(
      day: json['day']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      estTime: parseEstTime(json['est_time']),
      altitude: (json['altitude'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      note: json['note']?.toString() ?? '',
      imageAsset: json['image_asset']?.toString(),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'name': name,
      'est_time': estTime,
      'actual_time': actualTime?.toIso8601String(),
      'altitude': altitude,
      'distance': distance,
      'note': note,
      'image_asset': imageAsset,
    };
  }
}
