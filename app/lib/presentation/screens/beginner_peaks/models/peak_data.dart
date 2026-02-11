/// 單座山岳的詳細資料模型
class PeakData {
  /// 山岳名稱 (例如：合歡北峰)
  final String name;

  /// 海拔高度 (公尺)
  final int height;

  /// 日出特色描述
  final String feature;

  /// 體能限制/要求描述
  final String limit;

  /// 入園/入山申請規定
  final String permit;

  /// 推薦指數 (1-5)
  final int recommendation;

  /// 難度等級 (1-5)
  final int difficulty;

  /// 管理單位 (例如：太魯閣國家公園)
  final String manage;

  /// 住宿資訊
  final String accommodation;

  /// 往返距離描述
  final String distance;

  /// 總爬升高度描述
  final String climb;

  /// 所需天數描述
  final String days;

  /// 地理位置 (縣市鄉鎮)
  final String location;

  /// 是否為百岳
  final bool isBaiyue;

  /// 取得顯示名稱 (若非百岳會自動標註)
  String get displayName => isBaiyue ? name : '$name (非百岳)';

  PeakData({
    required this.name,
    required this.height,
    required this.feature,
    required this.limit,
    required this.permit,
    required this.recommendation,
    required this.difficulty,
    required this.manage,
    required this.accommodation,
    required this.distance,
    required this.climb,
    required this.days,
    required this.location,
    this.isBaiyue = true,
  });
}
