/// 連線狀態服務介面
/// 統一管理網路連線狀態與離線模式
abstract interface class IConnectivityService {
  /// 是否有實際網路連線
  bool get hasConnection;

  /// App 是否啟用離線模式
  bool get isOfflineModeEnabled;

  /// 是否處於離線狀態 (無網路 OR 啟用離線模式)
  bool get isOffline;

  /// 是否處於線上狀態
  bool get isOnline;

  /// 主動檢查連線狀態
  Future<bool> checkConnectivity();

  /// 連線狀態變化串流
  Stream<bool> get onConnectivityChanged;

  /// 釋放資源
  void dispose();
}
