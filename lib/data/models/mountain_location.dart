/// 山岳地點資訊
class MountainLocation {
  /// 地點 ID
  final String id;

  /// 地點名稱
  final String name;

  /// 中央氣象署 PID (例如 D055)
  final String cwaPid;

  /// Windy 座標參數
  final String windyParams;

  /// 其他相關連結
  final List<MountainLink> links;

  const MountainLocation({
    required this.id,
    required this.name,
    required this.cwaPid,
    required this.windyParams,
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

  const MountainLink({
    required this.type,
    required this.title,
    required this.url,
  });
}
