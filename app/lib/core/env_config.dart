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
  // 後端預設 API 網址
  // 從 --dart-define 或環境變數讀取
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1', // 預設指向 Android Emulator
  );

  // 執行期自訂 API 網址暫存
  static String? _customApiBaseUrl;

  // 取得目前有效的 API 網址 (自訂優先)
  static String get apiBaseUrl => _customApiBaseUrl ?? _defaultApiBaseUrl;

  // 初始化自訂網址 (通常於 DI 初始化時由 SharedPreferences 載入)
  static void initCustomApiUrl(String? customUrl) {
    _customApiBaseUrl = customUrl;
  }

  // 設定並更新自訂網址
  static void setCustomApiUrl(String? customUrl) {
    _customApiBaseUrl = customUrl;
  }

  // 是否正在使用自訂 API 網址
  static bool get isUsingCustomApiUrl => _customApiBaseUrl != null;

  // 取得預設的環境變數網址
  static String get defaultApiBaseUrl => _defaultApiBaseUrl;

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
  static bool get isConfigured => apiBaseUrl.isNotEmpty && cwaApiKey.isNotEmpty;

  /// 取得有效的 API URL
  /// 如果環境變數未設定，會使用 fallback
  static String getApiUrl({String? fallback}) {
    if (apiBaseUrl.isNotEmpty) return apiBaseUrl;
    if (fallback != null) return fallback;
    throw StateError('API_BASE_URL not configured. Run with --dart-define-from-file=.env.dev');
  }
}
