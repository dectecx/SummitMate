import 'package:hive/hive.dart';

part 'trip.g.dart';

/// 行程 (Trip) 模型
/// 用於管理多個不同的登山計畫
@HiveType(typeId: 10)
class Trip extends HiveObject {
  /// 行程唯一識別碼 (UUID)
  @HiveField(0)
  String id;

  /// 行程名稱，e.g., "2024 嘉明湖三日"
  @HiveField(1)
  String name;

  /// 行程開始日期
  @HiveField(2)
  DateTime startDate;

  /// 行程結束日期 (可選)
  @HiveField(3)
  DateTime? endDate;

  /// 行程描述/備註
  @HiveField(4)
  String? description;

  /// 封面圖片 (asset 路徑或 URL)
  @HiveField(5)
  String? coverImage;

  /// 是否為當前啟用的行程
  @HiveField(6)
  bool isActive;

  /// 建立時間
  @HiveField(7)
  DateTime createdAt;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.description,
    this.coverImage,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 行程天數
  int get durationDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// 從 JSON 建立
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['trip_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString())?.toLocal() : null,
      description: json['description']?.toString(),
      coverImage: json['cover_image']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 'TRUE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'trip_id': id,
      'name': name,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'description': description,
      'cover_image': coverImage,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() => 'Trip(id: $id, name: $name, isActive: $isActive)';
}
