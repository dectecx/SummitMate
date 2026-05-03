/// 收藏類型
enum FavoriteType {
  /// 山岳
  mountain,

  /// 揪團
  groupEvent,

  /// 路線
  route,

  /// 其他
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
