/// 環境配置
/// 從編譯時定義的變數讀取敏感設定
///
/// 使用方式：
/// ```bash
/// # 開發環境
/// flutter run --dart-define-from-file=.env.dev
///
/// # 正式環境
/// flutter run --release --dart-define-from-file=.env.prod
/// ```
class EnvConfig {
  // Google Apps Script URL
  // 從 --dart-define 或環境變數讀取
  static const String gasBaseUrl = String.fromEnvironment(
    'GAS_BASE_URL',
    defaultValue: '', // 空字串表示未設定
  );

  // 是否為開發模式
  static const bool isDev = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev') == 'dev';

  // 是否啟用 Debug Log
  static const bool enableDebugLog = String.fromEnvironment('DEBUG_LOG', defaultValue: 'false') == 'true';

  // CWA API Key (Central Weather Administration)
  static const String cwaApiKey = String.fromEnvironment('CWA_API_KEY', defaultValue: '');

  // CWA API Host (Direct or Proxy)
  static const String cwaApiHost = String.fromEnvironment('CWA_API_HOST', defaultValue: 'https://opendata.cwa.gov.tw');

  // AdMob IDs (Optional, fallback to test IDs if empty)
  static const String admobBannerIdAndroid = String.fromEnvironment('ADMOB_BANNER_ID_ANDROID', defaultValue: '');
  static const String admobBannerIdiOS = String.fromEnvironment('ADMOB_BANNER_ID_IOS', defaultValue: '');
  static const String admobInterstitialIdAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID_ANDROID',
    defaultValue: '',
  );
  static const String admobInterstitialIdiOS = String.fromEnvironment('ADMOB_INTERSTITIAL_ID_IOS', defaultValue: '');

  /// 檢查必要的環境變數是否已設定
  static bool get isConfigured => gasBaseUrl.isNotEmpty && cwaApiKey.isNotEmpty;

  /// 取得有效的 API URL
  /// 如果環境變數未設定，會使用 fallback
  static String getApiUrl({String? fallback}) {
    if (gasBaseUrl.isNotEmpty) return gasBaseUrl;
    if (fallback != null) return fallback;
    throw StateError('GAS_BASE_URL not configured. Run with --dart-define-from-file=.env.dev');
  }
}
