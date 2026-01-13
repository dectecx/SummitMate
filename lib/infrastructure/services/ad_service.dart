import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/interfaces/i_ad_service.dart';
import '../../core/config/ad_helper.dart';
import '../../infrastructure/tools/log_service.dart';

/// 廣告服務實作
class AdService implements IAdService {
  static const String _tag = 'AdService';
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  @override
  Future<void> initialize() async {
    if (!AdHelper.isSupported) {
      LogService.info('AdMob not supported on this platform/environment.', source: _tag);
      return;
    }
    try {
      await MobileAds.instance.initialize();
      LogService.info('Google Mobile Ads initialized', source: _tag);
      // 預先載入插頁式廣告 (可選)
    } catch (e) {
      LogService.error('Failed to initialize AdMob: $e', source: _tag);
    }
  }

  /// 載入插頁式廣告
  @override
  Future<void> loadInterstitial() async {
    if (!AdHelper.isSupported) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    LogService.debug('Loading Interstitial Ad...', source: _tag);

    await InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          LogService.info('Interstitial Ad Loaded', source: _tag);
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          LogService.error('Interstitial Ad Failed to Load: $error', source: _tag);
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// 顯示插頁式廣告
  @override
  void showInterstitial() {
    if (_interstitialAd == null) {
      LogService.warning('Interstitial Ad not ready', source: _tag);
      // 若廣告還沒好，嘗試重新載入以備下次使用
      loadInterstitial();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        LogService.debug('Interstitial Ad Dismissed', source: _tag);
        ad.dispose();
        _interstitialAd = null;
        // 關閉後立即載入下一個 (可選，視頻率控制而定)
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        LogService.error('Interstitial Ad Failed to Show: $error', source: _tag);
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null; // 顯示後即視為消耗
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }

  // --- Rewarded Ad ---

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  @override
  Future<void> loadRewardedAd() async {
    if (!AdHelper.isSupported) return;
    if (_isRewardedLoading || _rewardedAd != null) return;

    _isRewardedLoading = true;
    LogService.debug('Loading Rewarded Ad...', source: _tag);

    await RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          LogService.info('Rewarded Ad Loaded', source: _tag);
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          LogService.error('Rewarded Ad Failed to Load: $error', source: _tag);
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  @override
  void showRewardedAd({required Function(int amount, String type) onUserEarnedReward}) {
    if (_rewardedAd == null) {
      LogService.warning('Rewarded Ad not ready', source: _tag);
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        LogService.debug('Rewarded Ad Dismissed', source: _tag);
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        LogService.error('Rewarded Ad Failed to Show: $error', source: _tag);
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        LogService.info('User earned reward: ${reward.amount} ${reward.type}', source: _tag);
        onUserEarnedReward(reward.amount.toInt(), reward.type);
      },
    );
    _rewardedAd = null;
  }

  // --- App Open Ad ---

  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  bool _isShowingAppOpenAd = false;

  @override
  Future<void> loadAppOpenAd() async {
    if (!AdHelper.isSupported) return;
    if (_isAppOpenLoading || _appOpenAd != null) return;

    _isAppOpenLoading = true;
    LogService.debug('Loading App Open Ad...', source: _tag);

    await AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          LogService.info('App Open Ad Loaded', source: _tag);
          _appOpenAd = ad;
          _isAppOpenLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          LogService.error('App Open Ad Failed to Load: $error', source: _tag);
          _appOpenAd = null;
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  @override
  void showAppOpenAd() {
    if (_appOpenAd == null) {
      LogService.warning('App Open Ad not ready', source: _tag);
      loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) {
      LogService.debug('App Open Ad is already showing', source: _tag);
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        _isShowingAppOpenAd = false;
        LogService.debug('App Open Ad Dismissed', source: _tag);
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _isShowingAppOpenAd = false;
        LogService.error('App Open Ad Failed to Show: $error', source: _tag);
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _isShowingAppOpenAd = true;
    _appOpenAd!.show();
    _appOpenAd = null; // Mark as consumed
  }
}
