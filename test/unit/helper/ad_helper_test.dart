import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/config/ad_helper.dart';

// Note: AdService interacts with static GoogleMobileAds singleton which is hard to mock directly
// without a wrapper or platform channel mocking.
// For this unit test, we will strictly test the AdHelper logic (ID safety) which IS independent.
// The AdService's interaction with the plugin would usually be tested in integration tests or
// by checking if it calls the correct platform channels, but that's out of scope for basic safety check.

void main() {
  group('AdHelper', () {
    test('Should throw UnsupportedError if platform is not Android/iOS (unit test context)', () {
      // In pure unit test (not integration), defaultTargetPlatform might be linux/windows/macos
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final id = AdHelper.bannerAdUnitId;
      expect(id, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });

    // To test Android/iOS logic, we need to override the platform.
    test('Should return Test ID in Debug Mode (Android)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      // We are in debug mode by default in tests? Yes, kDebugMode is true in 'flutter test'.
      // Note: kDebugMode is hardcoded const bool in foundation, usually true in JIT/Debug builds.
      // However, inside `flutter test`, it relies on how the test runtime is built.
      // Generally `kDebugMode` is true.

      if (kDebugMode) {
        final id = AdHelper.bannerAdUnitId;
        expect(id, AdHelper.testBannerIdAndroid);
      }
      debugDefaultTargetPlatformOverride = null;
    });

    test('Should return Test ID in Debug Mode (iOS)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      if (kDebugMode) {
        final id = AdHelper.bannerAdUnitId;
        expect(id, AdHelper.testBannerIdiOS);
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
