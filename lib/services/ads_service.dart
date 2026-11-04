import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// AdMob: privacy consent, banner ads and the rewarded "+1 share" ad.
/// Nothing here runs for Premium users.
class AdsService extends ChangeNotifier {
  bool _started = false;
  bool _canRequestAds = false;
  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  bool get canRequestAds => _canRequestAds;
  bool get rewardedReady => _rewarded != null;

  /// Asks for consent where required (EU/UK, and Apple's tracking prompt if
  /// you set up the IDFA message in AdMob), then starts the SDK.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        done.complete();
      },
      (_) => done.complete(),
    );
    await done.future;

    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!_canRequestAds) return;

    await MobileAds.instance.initialize();
    notifyListeners();
    loadRewarded();
  }

  void loadRewarded() {
    if (!_canRequestAds || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Rewarded ad failed: $error');
          // Try again later.
          Future.delayed(const Duration(seconds: 30), loadRewarded);
        },
      ),
    );
  }

  /// Shows the rewarded ad. Completes with true if the user earned the reward.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) result.complete(false);
        loadRewarded();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    notifyListeners();
    return result.future;
  }

  /// Called when the user becomes Premium.
  void stopAll() {
    _rewarded?.dispose();
    _rewarded = null;
    notifyListeners();
  }
}
