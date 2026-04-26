import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// 平台與裝置資訊服務
/// 用於封裝平台判斷邏輯，避免直接引用 dart:io
@lazySingleton
class PlatformService {
  /// 是否為 Web 平台
  bool get isWeb => kIsWeb;

  /// 是否為 Android 平台
  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 是否為 iOS 平台
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 是否為桌面平台 (Windows, macOS, Linux)
  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// 是否為行動裝置 App (iOS/Android)
  bool get isMobileApp => isAndroid || isIOS;

  /// 取得平台名稱
  String get platformName {
    if (kIsWeb) return 'Web';
    return defaultTargetPlatform.name;
  }
}
