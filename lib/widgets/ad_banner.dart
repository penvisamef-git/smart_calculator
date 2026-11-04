import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../services/ads_service.dart';
import '../services/premium_service.dart';

/// Adaptive banner ad at the bottom of a screen. Hidden for Premium users.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final canRequest = context.watch<AdsService>().canRequestAds;
    final isPremium = context.watch<PremiumService>().isPremium;
    if (isPremium) {
      _disposeAd();
    } else if (canRequest && !_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;
    if (!mounted) return;
    _ad = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _ad = null;
          debugPrint('Banner failed: $err');
        },
      ),
    )..load();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumService>().isPremium;
    final ad = _ad;
    if (isPremium || ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
