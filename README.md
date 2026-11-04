# Smart Calculator

Flutter app for Android and iOS — powered by **Cyber Tech System**.

- 3‑second animated splash
- Calculator with live result and smart percent (`200 + 10% = 220`)
- History saved on the phone (Hive): rename, search, delete one, delete all
- Free: history kept 30 days, 3 shares per day (+1 per rewarded ad), banner ads
- Premium $0.99 one‑time: no ads, history forever, unlimited sharing, all colors
- 6 color themes + custom accent (Premium), 8 font styles
- 8 languages: English, ខ្មែរ, 中文, Français, 한국어, Tiếng Việt, 日本語, Español
- USD ⇄ Riel converter on the calculator (tap the rate to edit it)
- Quick tools: discount, VAT, tip & split bill, loan, profit margin, USD ⇄ Riel
- Voice input (microphone button) in all 8 languages
- Android home screen widget showing the last calculation
- History: pin favourites (long-press or Pin), tags (Shop, Home, Rent, Food, Work, Travel), monthly summary

---

## 1. Run it on your Mac

```bash
cd Smart_Calculator
flutter pub get
flutter run            # pick your phone or emulator
```

Run the tests:

```bash
flutter test
```

> iOS needs Xcode + CocoaPods: `cd ios && pod install` the first time.

Everything uses **Google's test ads** right now, so you can tap ads safely.

---

## 2. Project map

```
lib/
  main.dart                    start-up: storage, services, providers
  app.dart                     MaterialApp, theme, language
  core/
    constants.dart             ← AD IDS, PRODUCT ID, LIMITS, STORE LINKS
    calc_engine.dart           math: parse, evaluate, format
    app_theme.dart             the 6 color themes
    strings.dart               English + Khmer texts
  models/history_item.dart
  services/
    storage.dart               Hive boxes (all data stays on the phone)
    history_repository.dart    add / rename / delete / search / 30-day cleanup
    share_service.dart         3 shares per day + bonus from ads
    ads_service.dart           AdMob consent, banner, rewarded ad
    premium_service.dart       $0.99 purchase + restore
    settings_controller.dart   theme, language, vibration, live result
    calculator_controller.dart
  screens/                     splash, calculator, history, share, themes, premium, settings
  widgets/                     shared buttons, ad banner
test/                          math, history, share limit, all screens (EN + KM)
```

---

## 3. Before you publish on Google Play

### a) AdMob (ads)
1. Go to **admob.google.com** → Apps → Add app → Android → "Smart Calculator".
2. Copy the **App ID** (`ca-app-pub-XXXX~YYYY`) into
   `android/app/src/main/AndroidManifest.xml` (replace the test id).
3. Create 2 ad units: **Banner** and **Rewarded**. Paste their IDs into
   `lib/core/constants.dart` (`ANDROID_BANNER_ID`, `ANDROID_REWARDED_ID`).
4. In `constants.dart` set `useTestAds = false` — only for the release build.
5. In AdMob → Privacy & messaging, create a **GDPR** message (needed for EU users).

> Never tap your own real ads. Google can close your account.

### b) Upload key (signing)
```bash
keytool -genkey -v -keystore ~/smart-calculator-upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties` (do NOT share or commit this file):
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=/Users/blackcorp/smart-calculator-upload.jks
```
Keep the `.jks` file and passwords safe — you need them for every update.

### c) Build and upload
```bash
flutter build appbundle --release
```
Upload `build/app/outputs/bundle/release/app-release.aab` to
**Play Console → Testing → Internal testing**.

### d) Create the $0.99 product
After the first upload, in Play Console:
**Monetize → Products → In-app products → Create product**
- Product ID: `premium_unlock` (must match `constants.dart`)
- Name: Smart Calculator Premium
- Price: $0.99
- Activate it.

Add yourself as a **license tester** (Settings → License testing) to buy
without being charged.

### e) Store listing
- App ID on Play: `com.cybertechsystem.smartcalculator` — it can never change after the first upload.
- Privacy policy URL is required (because of ads).
- Data safety form: the app shows ads (AdMob collects device identifiers); calculations are stored only on the device.

---

## 4. iOS (after your Apple account is approved)

1. App Store Connect → create the app with bundle ID `com.cybertechsystem.smartCalculator`.
2. Sign the **Paid Apps Agreement**, add bank + tax info.
3. Create an **In-App Purchase → Non-Consumable**: `premium_unlock`, $0.99.
4. AdMob → add the iOS app → put the iOS App ID in `ios/Runner/Info.plist`
   (`GADApplicationIdentifier`) and the iOS ad unit IDs in `constants.dart`.
5. AdMob → Privacy & messaging → create an **IDFA explainer** message
   (shows Apple's tracking popup).
6. Set `appStoreUrl` in `constants.dart` once you have the App Store link.
7. `flutter build ipa` and upload with Xcode / Transporter.

---

## 5. Change things quickly

| What | Where |
|---|---|
| Free history days / shares per day | `lib/core/constants.dart` |
| Colors / add a theme | `lib/core/app_theme.dart` |
| Texts (English + Khmer) | `lib/core/strings.dart` |
| App icon | replace `assets/icon/*.png`, run `dart run flutter_launcher_icons` |
| Version | `version:` in `pubspec.yaml` (raise it for every store update) |

---

## 6. Release checklist (do these before uploading to the store)

1. `lib/core/constants.dart` → paste your real AdMob **banner** and **rewarded** IDs, set `useTestAds = false`.
2. `android/app/src/main/AndroidManifest.xml` → replace the test AdMob **App ID** with yours.
3. Create `android/key.properties` + upload key (section 3b). Without it the build is signed with the debug key and Play will reject it.
4. Raise `version:` in `pubspec.yaml` for every upload (e.g. `1.0.0+1` → `1.0.1+2`).
5. `flutter build appbundle --release` → upload `app-release.aab`.
6. Play Console → **Data safety**: the app uses the microphone only for voice input (not stored or sent by the app), shows ads (AdMob), stores calculations only on the device.
7. Play Console → create in-app product `premium_unlock` ($0.99, one-time) after the first upload.
8. Test on a real phone with a **license tester** account: buy, restore, ads hidden after buying.

### iOS home screen widget
The Android widget is included. An iOS widget needs a "Widget Extension" target
and an App Group made in Xcode (it cannot be added from code only). Everything
else works on iOS.
