import 'package:hive_ce/hive.dart';

part 'favorite_type.g.dart';

/// 收藏類型
@HiveType(typeId: 22)
enum FavoriteType {
  /// 山岳
  @HiveField(0)
  mountain,

  /// 揪團
  @HiveField(1)
  groupEvent,

  /// 路線
  @HiveField(2)
  route,

  /// 其他
  @HiveField(3)
  other;

  /// 取得值
  String get value {
    switch (this) {
      case FavoriteType.mountain:
        return 'mountain';
      case FavoriteType.groupEvent:
        return 'group_event';
      case FavoriteType.route:
        return 'route';
      case FavoriteType.other:
        return 'other';
    }
  }

  /// 從字串轉換
  static FavoriteType fromValue(String value) {
    switch (value) {
      case 'mountain':
        return FavoriteType.mountain;
      case 'group_event':
        return FavoriteType.groupEvent;
      case 'route':
        return FavoriteType.route;
      case 'other':
      default:
        return FavoriteType.other;
    }
  }
}
