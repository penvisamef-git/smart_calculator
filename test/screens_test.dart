// Renders every screen on a small and a large phone, in English and Khmer.
// Fails if anything overflows or throws.
// To also save screenshots into test/goldens/:
//   SCREENSHOTS=1 flutter test test/screens_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:smart_calculator/core/app_fonts.dart';
import 'package:smart_calculator/core/app_theme.dart';
import 'package:smart_calculator/core/strings.dart';
import 'package:smart_calculator/screens/calculator_screen.dart';
import 'package:smart_calculator/screens/history_screen.dart';
import 'package:smart_calculator/screens/premium_screen.dart';
import 'package:smart_calculator/screens/settings_screen.dart';
import 'package:smart_calculator/screens/share_screen.dart';
import 'package:smart_calculator/screens/splash_screen.dart';
import 'package:smart_calculator/screens/themes_screen.dart';
import 'package:smart_calculator/screens/tools_screen.dart';
import 'package:smart_calculator/screens/summary_screen.dart';
import 'package:smart_calculator/services/voice_service.dart';
import 'package:smart_calculator/services/ads_service.dart';
import 'package:smart_calculator/services/calculator_controller.dart';
import 'package:smart_calculator/services/history_repository.dart';
import 'package:smart_calculator/services/premium_service.dart';
import 'package:smart_calculator/services/settings_controller.dart';
import 'package:smart_calculator/services/share_service.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  if (paths.any((p) => !File(p).existsSync())) return;
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

final _screenshots = Platform.environment['SCREENSHOTS'] == '1';

void main() {
  late Directory dir;
  late Box settingsBox;
  late Box<Map> historyBox;

  setUpAll(() async {
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '';
    final mf = '$sdk/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf']);
    await _loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    await _loadFont('Orbitron', ['assets/fonts/Orbitron.ttf']);
    await _loadFont('NotoSansKhmer', ['test/fonts/NotoSansKhmer.ttf']);
    for (final f in ['Inter', 'Poppins', 'Nunito', 'JetBrainsMono', 'Quicksand', 'Rajdhani']) {
      await _loadFont(f, [for (final w in [400, 500, 600, 700]) 'assets/fonts/$f-$w.ttf']);
    }
    dir = await Directory.systemTemp.createTemp('screens');
    Hive.init(dir.path);
    settingsBox = await Hive.openBox('settings');
    historyBox = await Hive.openBox<Map>('history');
  });

  Widget app(Widget home, {required String lang, String font = 'cyber'}) {
    settingsBox.put('language', lang);
    settingsBox.put('fontId', font);
    final settings = SettingsController(settingsBox);
    final premium = PremiumService(settingsBox);
    final history = HistoryRepository(historyBox);
    if (history.count == 0) {
      final a = history.add('12500+8000×3', 36500);
      history.rename(a.id, lang == 'km' ? 'ទិញឥវ៉ាន់ផ្សារ' : 'Market shopping');
      history.add('45000÷3', 15000);
      final r = history.add('450×4100', 1845000);
      history.rename(r.id, 'Rent Oct');
    }
    final calc = CalculatorController(history)..load(history.items.first);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: premium),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: ShareService(settingsBox)),
        ChangeNotifierProvider.value(value: AdsService()),
        ChangeNotifierProvider.value(value: calc),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.build(AppThemes.cyberTeal, font: settings.font, fontFallback: const ['NotoSansKhmer']),
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('km')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );
  }

  final screens = <String, Widget Function()>{
    'calculator': () => const CalculatorScreen(),
    'history': () => const HistoryScreen(),
    'share': () => const ShareScreen(),
    'themes': () => const ThemesScreen(),
    'premium': () => const PremiumScreen(),
    'settings': () => const SettingsScreen(),
    'tools': () => const ToolsScreen(),
    'summary': () => const SummaryScreen(),
  };
  const sizes = {'small': Size(360, 640), 'large': Size(390, 844)};

  for (final lang in S.supported) {
    for (final s in sizes.entries) {
      if (s.key == 'large' && lang != 'en' && lang != 'km') continue;
      for (final e in screens.entries) {
        testWidgets('${e.key} $lang ${s.key}', (tester) async {
          tester.view.physicalSize = s.value * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(app(e.value(), lang: lang));
          await tester.pumpAndSettle();
          if (_screenshots) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/${e.key}_${lang}_${s.key}.png'),
            );
          }
        });
      }
    }
  }

  for (final f in AppFont.all) {
    for (final e in {'calculator': screens['calculator']!, 'settings': screens['settings']!}.entries) {
      testWidgets('font ${f.id} ${e.key}', (tester) async {
        tester.view.physicalSize = sizes['small']! * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(e.value(), lang: 'en', font: f.id));
        await tester.pumpAndSettle();
        if (_screenshots) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/font_${f.id}_${e.key}.png'));
        }
      });
    }
  }

  testWidgets('font picker and language picker open', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const SettingsScreen(), lang: 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Font style'));
    await tester.pumpAndSettle();
    if (_screenshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/font_picker.png'));
    }
    await tester.tap(find.text('Modern'));
    await tester.pumpAndSettle();
    expect(find.text('Modern'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    if (_screenshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/language_picker.png'));
    }
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsOneWidget);
  });

  for (final lang in ['en', 'km', 'fr', 'vi']) {
    testWidgets('every tool opens and calculates ($lang)', (tester) async {
      tester.view.physicalSize = sizes['small']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const ToolsScreen(), lang: lang));
      await tester.pumpAndSettle();
      const keys = ['toolDiscount', 'toolVat', 'toolTip', 'toolLoan', 'toolMargin', 'toolCurrency'];
      for (var i = 0; i < keys.length; i++) {
        final card = find.text(S.of(lang, keys[i]));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsWidgets);
        if (_screenshots && lang == 'en') {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/tool_$i.png'));
        }
        Navigator.of(tester.element(find.byType(TextField).first)).pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('converter shows riel on calculator', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    settingsBox.put('convertMode', 'usd');
    await tester.pumpWidget(app(const CalculatorScreen(), lang: 'en'));
    await tester.pumpAndSettle();
    expect(find.textContaining('៛'), findsWidgets);
    if (_screenshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/convert.png'));
    }
    settingsBox.put('convertMode', 'off');
  });

  testWidgets('splash mid-animation', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const SplashScreen(), lang: 'en'));
    await tester.pump(const Duration(milliseconds: 2200));
    if (_screenshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/splash.png'));
    }
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorScreen), findsOneWidget);
  });
}
