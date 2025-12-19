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

  /// 檢查必要的環境變數是否已設定
  static bool get isConfigured => gasBaseUrl.isNotEmpty;

  /// 取得有效的 API URL
  /// 如果環境變數未設定，會使用 fallback
  static String getApiUrl({String? fallback}) {
    if (gasBaseUrl.isNotEmpty) return gasBaseUrl;
    if (fallback != null) return fallback;
    throw StateError('GAS_BASE_URL not configured. Run with --dart-define-from-file=.env.dev');
  }
}
