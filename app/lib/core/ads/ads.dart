import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the ad shown as one card inside a list. Tests and platforms without ads use the empty default;
/// `buildApp` swaps in the AdMob banner on phones.
final adBannerBuilderProvider = Provider<WidgetBuilder>((ref) => (_) => const SizedBox.shrink());

/// An ad's place inside a list. It takes no space when there is no ad (offline, failed to load, or ads are off).
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

class _AdMobBannerState extends State<AdMobBanner> with AutomaticKeepAliveClientMixin {
  BannerAd? _ad;
  bool _loaded = false;

  /// Scrolling the card off screen must not throw the ad away and request a new one.
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return AdCard(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

/// A loaded ad dressed as a list card, clearly marked as an ad and set apart from its neighbours so it is not
/// tapped by accident. The ad itself is never scaled.
class AdCard extends StatelessWidget {
  const AdCard({super.key, required this.width, required this.height, required this.child});
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) => Padding(
        // the side margin of the other cards, given up on a screen too narrow for it
        padding: EdgeInsets.symmetric(horizontal: ((box.maxWidth - width) / 2).clamp(0.0, 20.0), vertical: 10),
        child: Card(
          margin: EdgeInsets.zero, // every pixel of the width belongs to the ad
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 6),
                  child: Text('廣告', textAlign: TextAlign.right, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
                Center(child: SizedBox(width: width, height: height, child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
