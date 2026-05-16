/// 定義應用程式中的主要畫面分頁。
enum AppView {
  /// 行程分頁
  itinerary,

  /// 裝備分頁
  gear,

  /// 揪團與訊息分頁
  collaboration,

  /// 資訊與教學分頁
  info,

  /// 未知或未分類畫面
  unknown;

  /// 從字串轉換為 AppView 列舉
  static AppView fromString(String value) {
    return AppView.values.firstWhere((e) => e.name == value, orElse: () => AppView.unknown);
  }
}
