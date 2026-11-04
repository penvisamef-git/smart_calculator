import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Everything you may need to change before release lives here.
class AppConfig {
  AppConfig._();

  static const appName = 'Smart Calculator';

  /// Opened when the "Powered by Cyber Tech System" logo is tapped.
  static const companyUrl = 'https://ctscambodia.com/';

  // ---- Free plan limits ----
  static const freeHistoryDays = 30;
  static const freeSharesPerDay = 3;

  // ---- In-app purchase ----
  /// Create a NON-CONSUMABLE product with this exact ID in Google Play
  /// Console and App Store Connect, priced at $0.99.
  static const premiumProductId = 'premium_unlock';

  // ---- Store links (added to shared text) ----
  static const androidPackage = 'com.cybertechsystem.smartcalculator';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// Fill in after the app is created in App Store Connect,
  /// e.g. https://apps.apple.com/app/id1234567890
  static const appStoreUrl = '';

  static String get storeUrl {
    if (!kIsWeb && Platform.isIOS && appStoreUrl.isNotEmpty) return appStoreUrl;
    return playStoreUrl;
  }

  // ---- AdMob ----
  /// While this is true the app uses Google's official TEST ad units.
  /// Set it to false only for the release build, after you paste your real
  /// ad unit IDs below. Never click your own real ads.
  static const useTestAds = false;

  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // iOS: still Google's test unit until the iOS app is added in AdMob.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-9064984582846776/2914731423'; // Calculator Banner
  }

  static String get rewardedAdUnitId {
    if (useTestAds) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    // iOS: still Google's test unit until the iOS app is added in AdMob.
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-9064984582846776/6805874976'; // Extra Share (rewarded)
  }
}
