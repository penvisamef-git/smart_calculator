import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/ads_service.dart';
import 'services/calculator_controller.dart';
import 'services/history_repository.dart';
import 'services/premium_service.dart';
import 'services/settings_controller.dart';
import 'services/share_service.dart';
import 'services/storage.dart';
import 'services/voice_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();

  final settings = SettingsController(Storage.settings);
  final premium = PremiumService(Storage.settings);
  final history = HistoryRepository(Storage.history)
    ..purgeExpired(isPremium: premium.isPremium);
  final share = ShareService(Storage.settings);
  final ads = AdsService();
  final calculator = CalculatorController(history);

  // Stop ads the moment the user becomes Premium.
  premium.addListener(() {
    if (premium.isPremium) ads.stopAll();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: premium),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: share),
        ChangeNotifierProvider.value(value: ads),
        ChangeNotifierProvider.value(value: calculator),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: const SmartCalculatorApp(),
    ),
  );

  unawaited(premium.init());
  unawaited(
    WidgetService.show(history.items.isEmpty ? null : history.items.first),
  );
}
