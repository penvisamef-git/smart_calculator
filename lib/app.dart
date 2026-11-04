import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'core/strings.dart';
import 'screens/splash_screen.dart';
import 'services/premium_service.dart';
import 'services/settings_controller.dart';

class SmartCalculatorApp extends StatelessWidget {
  const SmartCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isPremium = context.select<PremiumService, bool>((p) => p.isPremium);
    final palette = settings.palette(isPremium: isPremium);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppThemes.build(palette, font: settings.font),
        locale: settings.locale,
        supportedLocales: [for (final c in S.supported) Locale(c)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
