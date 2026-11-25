import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the banner shown at the bottom of a screen. Tests and platforms without ads use the empty default;
/// `buildApp` swaps in the AdMob banner on phones.
final adBannerBuilderProvider = Provider<WidgetBuilder>((ref) => (_) => const SizedBox.shrink());

/// A banner slot that takes no space when there is no ad (offline, failed to load, or ads are off).
class AdBannerSlot extends ConsumerWidget {
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(adBannerBuilderProvider)(context);
}

/// Google's public sample banner ad units. Replace them (and the app IDs in Info.plist / AndroidManifest)
/// with real ones before release.
String get testBannerUnitId => Platform.isIOS ? 'ca-app-pub-3940256099942544/2934735716' : 'ca-app-pub-3940256099942544/6300978111';

/// Starts the ad SDK and returns the builder for real banners.
WidgetBuilder initialiseAdMob() {
  MobileAds.instance.initialize(); // not awaited: the first banner simply loads a moment later
  return (_) => const AdMobBanner();
}

class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key});

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: testBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    // The fixed-size banner is centred on a surface-coloured strip; without it the sides show black.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad)),
        ),
      ),
    );
  }
}
