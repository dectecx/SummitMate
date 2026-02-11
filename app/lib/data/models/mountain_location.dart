/// 山岳地點資訊
class MountainLocation {
  /// 地點 ID
  final String id;

  /// 地點名稱
  final String name;

  /// 海拔 (公尺)
  final int altitude;

  /// 所在區域
  final MountainRegion region;

  /// 簡介
  final String introduction;

  /// 特色
  final String features;

  /// 登山口清單
  final List<String> trailheads;

  /// 地圖對照 (例如: 上河文化 M19)
  final String mapRef;

  /// 管轄單位
  final String jurisdiction;

  /// 是否適合新手
  final bool isBeginnerFriendly;

  /// 照片 URL 清單
  final List<String> photoUrls;

  /// 中央氣象署 PID (例如 D055)
  final String cwaPid;

  /// Windy 座標參數
  final String windyParams;

  /// 山岳類別
  final MountainCategory category;

  /// 其他相關連結
  final List<MountainLink> links;

  const MountainLocation({
    required this.id,
    required this.name,
    required this.altitude,
    required this.region,
    required this.introduction,
    required this.features,
    required this.trailheads,
    required this.mapRef,
    required this.jurisdiction,
    this.isBeginnerFriendly = false,
    this.photoUrls = const [],
    required this.cwaPid,
    required this.windyParams,
    required this.category,
    this.links = const [],
  });

  /// 取得特定類型的連結 URL (如果有的話)
  String? getLinkUrl(LinkType type) {
    try {
      return links.firstWhere((link) => link.type == type).url;
    } catch (_) {
      return null;
    }
  }
}

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

/// 山岳相關連結
class MountainLink {
  /// 連結類型
  final LinkType type;

  /// 顯示標題
  final String title;

  /// 連結網址
  final String url;

  const MountainLink({required this.type, required this.title, required this.url});
}
