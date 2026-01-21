import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/config/ad_helper.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// 共用橫幅廣告 Widget
/// 自動管理廣告生命週期
class BannerAdWidget extends StatefulWidget {
  final String location;
  final AdSize adSize;

  const BannerAdWidget({super.key, required this.location, this.adSize = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  static const String _tag = 'BannerAdWidget';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdHelper.isSupported) return;

    LogService.debug('Loading Banner Ad for ${widget.location}...', source: _tag);
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          LogService.debug('Banner Ad loaded for ${widget.location}', source: _tag);
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          LogService.error('Banner Ad failed to load for ${widget.location}: $error', source: _tag);
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return SafeArea(
        top: false,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    // 廣告未載入時的回退：顯示空 Widget 且不佔空間
    return const SizedBox.shrink();
  }
}
