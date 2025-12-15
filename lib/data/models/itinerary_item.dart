import 'package:isar/isar.dart';

part 'itinerary_item.g.dart';

/// 行程節點 Collection
/// 來源：由 Google Sheets 下載覆寫，但 actualTime 保留本地紀錄
@collection
class ItineraryItem {
  /// Isar Auto ID
  Id? id;

  /// 行程天數，e.g., "D0", "D1", "D2"
  String day = '';

  /// 地標名稱，e.g., "向陽山屋"
  String name = '';

  /// 預計時間 (HH:mm 格式)
  String estTime = '';

  /// 實際打卡時間 (本地欄位)
  DateTime? actualTime;

  /// 海拔高度 (公尺)
  int altitude = 0;

  /// 里程 (公里)
  double distance = 0.0;

  /// 備註
  String note = '';

  /// 對應 assets 圖片檔名
  String? imageAsset;

  /// 建構子
  ItineraryItem();

  /// 是否已打卡
  @ignore
  bool get isCheckedIn => actualTime != null;

  /// 從 JSON 建立 (用於 Google Sheets 資料解析)
  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem()
      ..day = json['day'] as String? ?? ''
      ..name = json['name'] as String? ?? ''
      ..estTime = json['est_time'] as String? ?? ''
      ..altitude = (json['altitude'] as num?)?.toInt() ?? 0
      ..distance = (json['distance'] as num?)?.toDouble() ?? 0.0
      ..note = json['note'] as String? ?? ''
      ..imageAsset = json['image_asset'] as String?;
  }

  /// 轉換為 JSON (用於調試)
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
