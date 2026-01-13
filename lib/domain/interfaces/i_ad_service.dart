/// 廣告服務介面
/// 負責管理廣告的載入與顯示
abstract interface class IAdService {
  /// 初始化廣告 SDK
  Future<void> initialize();

  /// 載入插頁式廣告
  /// 建議在預期會顯示廣告的流程前呼叫
  Future<void> loadInterstitial();

  /// 顯示插頁式廣告
  /// 若廣告尚未載入完成，則不會執行任何動作
  void showInterstitial();

  /// 釋放資源
  void dispose();

  // --- 擴充功能 (預先實作) ---

  /// 載入獎勵廣告
  Future<void> loadRewardedAd();

  /// 顯示獎勵廣告
  /// [onUserEarnedReward] 當用戶獲得獎勵時的回調
  void showRewardedAd({required Function(int amount, String type) onUserEarnedReward});

  /// 載入開屏廣告
  Future<void> loadAppOpenAd();

  /// 顯示開屏廣告 (若可用)
  void showAppOpenAd();
}
