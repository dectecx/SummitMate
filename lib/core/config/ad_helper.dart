import 'package:flutter/foundation.dart';
import '../env_config.dart';

/// 廣告輔助類別
/// 管理廣告單元 ID (Ad Unit IDs) 與環境設定
class AdHelper {
  // 注意：以下 ID 需替換為真實的 AdMob ID (目前使用 Test ID 作為 placeholder)
  // 若未設定真實 ID，即使在 Release 模式下也建議暫時使用 Test ID 以免發生錯誤

  // Google 官方測試 ID (Test IDs)
  /// Android 橫幅廣告測試 ID
  static const String testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';

  /// iOS 橫幅廣告測試 ID
  static const String testBannerIdiOS = 'ca-app-pub-3940256099942544/2934735716';

  /// Android 插頁式廣告測試 ID
  static const String testInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';

  /// iOS 插頁式廣告測試 ID
  static const String testInterstitialIdiOS = 'ca-app-pub-3940256099942544/4411468910';

  /// Android 獎勵廣告測試 ID
  static const String testRewardedIdAndroid = 'ca-app-pub-3940256099942544/5224354917';

  /// iOS 獎勵廣告測試 ID
  static const String testRewardedIdiOS = 'ca-app-pub-3940256099942544/1712485313';

  /// Android 獎勵插頁式廣告測試 ID
  static const String testRewardedInterstitialIdAndroid = 'ca-app-pub-3940256099942544/5354046379';

  /// iOS 獎勵插頁式廣告測試 ID
  static const String testRewardedInterstitialIdiOS = 'ca-app-pub-3940256099942544/6978759866';

  /// Android 開屏廣告測試 ID
  static const String testAppOpenIdAndroid = 'ca-app-pub-3940256099942544/3419835294';

  /// iOS 開屏廣告測試 ID
  static const String testAppOpenIdiOS = 'ca-app-pub-3940256099942544/5662855259';

  /// 檢查目前平台是否支援廣告
  static bool get isSupported {
    if (kIsWeb) return false; // 暫不支援 Web
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 取得橫幅廣告 ID
  /// 順序: EnvConfig -> Test ID (Debug) -> Real ID (Fallback placeholder) -> Error
  static String get bannerAdUnitId {
    if (!isSupported) return '';

    // 1. 優先使用環境變數設定的真實 ID
    if (defaultTargetPlatform == TargetPlatform.android && EnvConfig.admobBannerIdAndroid.isNotEmpty) {
      return EnvConfig.admobBannerIdAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && EnvConfig.admobBannerIdiOS.isNotEmpty) {
      return EnvConfig.admobBannerIdiOS;
    }

    // 2. 若無真實 ID，Debug 模式下回傳測試 ID
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) return testBannerIdAndroid;
      if (defaultTargetPlatform == TargetPlatform.iOS) return testBannerIdiOS;
    }

    // 3. 若 Release 模式且無真實 ID，理論上應回傳空或拋錯，避免顯示測試廣告
    // 這裡為了防止 crash 回傳空字串 (AdService 會捕捉 LoadAdError)
    // 或者可選擇回傳 _testBannerId 以便測試 (依照用戶需求：若未設定真實 ID，即使 Release 也建議使用 Test ID?)
    // 用戶原話: "若未設定真實 ID，即使在 Release 模式下也建議暫時使用 Test ID 以免發生錯誤"
    // 因此這裡 fallback 到測試 ID
    if (defaultTargetPlatform == TargetPlatform.android) return testBannerIdAndroid;
    if (defaultTargetPlatform == TargetPlatform.iOS) return testBannerIdiOS;

    return '';
  }

  /// 取得插頁式廣告 ID
  static String get interstitialAdUnitId {
    if (!isSupported) return '';

    if (defaultTargetPlatform == TargetPlatform.android && EnvConfig.admobInterstitialIdAndroid.isNotEmpty) {
      return EnvConfig.admobInterstitialIdAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && EnvConfig.admobInterstitialIdiOS.isNotEmpty) {
      return EnvConfig.admobInterstitialIdiOS;
    }

    // Fallback to Test IDs
    if (defaultTargetPlatform == TargetPlatform.android) return testInterstitialIdAndroid;
    if (defaultTargetPlatform == TargetPlatform.iOS) return testInterstitialIdiOS;

    return '';
  }

  /// 取得獎勵廣告 ID
  static String get rewardedAdUnitId {
    if (!isSupported) return '';
    // 目前僅回傳測試 ID
    if (defaultTargetPlatform == TargetPlatform.android) return testRewardedIdAndroid;
    if (defaultTargetPlatform == TargetPlatform.iOS) return testRewardedIdiOS;
    return '';
  }

  /// 取得獎勵插頁式廣告 ID
  static String get rewardedInterstitialAdUnitId {
    if (!isSupported) return '';
    // 目前僅回傳測試 ID
    if (defaultTargetPlatform == TargetPlatform.android) return testRewardedInterstitialIdAndroid;
    if (defaultTargetPlatform == TargetPlatform.iOS) return testRewardedInterstitialIdiOS;
    return '';
  }

  /// 取得開屏廣告 ID
  static String get appOpenAdUnitId {
    if (!isSupported) return '';
    // 目前僅回傳測試 ID
    if (defaultTargetPlatform == TargetPlatform.android) return testAppOpenIdAndroid;
    if (defaultTargetPlatform == TargetPlatform.iOS) return testAppOpenIdiOS;
    return '';
  }
}
