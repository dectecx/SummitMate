/// Google Apps Script API Error Codes
/// Synced with gas/_config.gs
class GasErrorCodes {
  // Read-only private constructor
  const GasErrorCodes._();

  // ============================================================
  // General (00XX)
  // ============================================================
  static const String success = '0000';
  static const String unknownAction = '0001';
  static const String invalidParams = '0002';
  static const String systemError = '0099';

  // ============================================================
  // Trips (01XX)
  // ============================================================
  static const String tripNotFound = '0101';
  static const String tripSheetMissing = '0102';
  static const String tripIdRequired = '0103';
  static const String tripInvalidDate = '0104';
  static const String tripCreateFailed = '0105';
  static const String tripUpdateFailed = '0106';
  static const String tripSyncFailed = '0107';

  // ============================================================
  // Itinerary (02XX)
  // ============================================================
  static const String itinerarySheetMissing = '0201';

  // ============================================================
  // Messages (03XX)
  // ============================================================
  static const String messageNotFound = '0301';
  static const String messageAlreadyExists = '0302';
  static const String messageSheetMissing = '0303';

  // ============================================================
  // Gear (04XX)
  // ============================================================
  static const String gearNotFound = '0401';
  static const String gearKeyInvalid = '0402';
  static const String gearKeyDuplicate = '0403';
  static const String gearKeyRequired = '0404';
  static const String gearMissingFields = '0405';

  // ============================================================
  // Polls (05XX)
  // ============================================================
  static const String pollNotFound = '0501';
  static const String pollClosed = '0502';
  static const String pollExpired = '0503';
  static const String pollAddOptionDisabled = '0504';
  static const String pollOptionLimit = '0505';
  static const String pollCreatorOnly = '0506';
  static const String pollSheetMissing = '0507';
  static const String pollOptionHasVotes = '0508';
  static const String pollOptionNotFound = '0509';

  // ============================================================
  // Weather (06XX)
  // ============================================================
  static const String weatherNotReady = '0601';

  // ============================================================
  // GearLibrary (07XX)
  // ============================================================
  static const String gearLibraryKeyInvalid = '0701';

  // ============================================================
  // Auth (08XX)
  // ============================================================
  /// 信箱已被註冊
  static const String authEmailExists = '0801';

  /// 信箱或密碼錯誤
  static const String authInvalidCredentials = '0802';

  /// 帳號已停用或刪除
  static const String authAccountDisabled = '0803';

  /// 認證 Token 無效
  static const String authAccessTokenInvalid = '0804';

  /// 缺少認證資訊
  static const String authRequired = '0805';

  /// Users 工作表不存在
  static const String authSheetMissing = '0806';

  /// 驗證碼錯誤
  static const String authCodeInvalid = '0807';

  /// 驗證碼已過期
  static const String authCodeExpired = '0808';

  /// Token 已過期
  static const String authAccessTokenExpired = '0809';
}
