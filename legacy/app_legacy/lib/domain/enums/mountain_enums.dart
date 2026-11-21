/// 山岳類別
enum MountainCategory {
  /// 百岳
  baiyue('百岳'),

  /// 小百岳
  xiaoBaiyue('小百岳'),

  /// 中級山
  intermediate('中級山'),

  /// 郊山
  suburban('郊山');

  final String label;
  const MountainCategory(this.label);
}

/// 山岳區域
enum MountainRegion {
  /// 北部
  north('北部'),

  /// 中部
  central('中部'),

  /// 南部
  south('南部'),

  /// 東部
  east('東部'),

  /// 其他
  other('其他');

  final String label;
  const MountainRegion(this.label);
}

/// 連結類型
enum LinkType {
  /// 步道資訊
  trail,

  /// 入山證
  permit,

  /// 山屋/營地
  cabin,

  /// GPX 下載
  gpx,

  /// 裝備清單 PDF
  gearPdf,

  /// 住宿
  accommodation,

  /// 其他
  other,
}
