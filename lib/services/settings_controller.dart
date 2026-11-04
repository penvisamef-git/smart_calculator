import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/strings.dart';

/// User settings: theme, language, vibration, live result.
class SettingsController extends ChangeNotifier {
  SettingsController(this._box) {
    _themeId =
        _box.get('themeId', defaultValue: AppThemes.cyberTeal.id) as String;
    final accent = _box.get('customAccent') as int?;
    _customAccent = accent == null ? null : Color(accent);
    _language = _box.get('language', defaultValue: _deviceLanguage()) as String;
    _vibration = _box.get('vibration', defaultValue: true) as bool;
    _liveResult = _box.get('liveResult', defaultValue: true) as bool;
    _fontId = _box.get('fontId', defaultValue: AppFont.cyber.id) as String;
    _khrRate = (_box.get('khrRate', defaultValue: 4100.0) as num).toDouble();
    _convertMode = _box.get('convertMode', defaultValue: 'off') as String;
  }

  final Box _box;

  late String _themeId;
  Color? _customAccent;
  late String _language;
  late bool _vibration;
  late bool _liveResult;
  late String _fontId;
  late double _khrRate;
  late String _convertMode;

  String get themeId => _themeId;
  Color? get customAccent => _customAccent;
  String get language => _language;
  bool get vibration => _vibration;
  bool get liveResult => _liveResult;
  AppFont get font => AppFont.byId(_fontId);

  /// How many riel for 1 US dollar (user can edit).
  double get khrRate => _khrRate;

  /// Converter on the calculator: 'off', 'usd' (answer is USD → show riel)
  /// or 'khr' (answer is riel → show USD).
  String get convertMode => _convertMode;

  void setKhrRate(double v) {
    if (v <= 0) return;
    _khrRate = v;
    _box.put('khrRate', v);
    notifyListeners();
  }

  /// off → usd → khr → off
  void cycleConvertMode() {
    _convertMode = switch (_convertMode) {
      'off' => 'usd',
      'usd' => 'khr',
      _ => 'off',
    };
    _box.put('convertMode', _convertMode);
    notifyListeners();
  }

  /// The palette in use. Premium themes / custom accent fall back to the
  /// default theme if the user is not Premium (e.g. after a refund).
  AppPalette palette({required bool isPremium}) {
    var p = AppThemes.byId(_themeId);
    if (p.premium && !isPremium) p = AppThemes.cyberTeal;
    if (_customAccent != null && isPremium) p = p.withAccent(_customAccent!);
    return p;
  }

  Locale get locale => Locale(_language);

  void setTheme(String id, {Color? customAccent}) {
    _themeId = id;
    _customAccent = customAccent;
    _box.put('themeId', id);
    if (customAccent == null) {
      _box.delete('customAccent');
    } else {
      _box.put('customAccent', customAccent.toARGB32());
    }
    notifyListeners();
  }

  void setLanguage(String code) {
    _language = code;
    _box.put('language', code);
    notifyListeners();
  }

  void setFont(String id) {
    _fontId = id;
    _box.put('fontId', id);
    notifyListeners();
  }

  void setVibration(bool v) {
    _vibration = v;
    _box.put('vibration', v);
    notifyListeners();
  }

  void setLiveResult(bool v) {
    _liveResult = v;
    _box.put('liveResult', v);
    notifyListeners();
  }

  static String _deviceLanguage() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return S.supported.contains(code) ? code : 'en';
  }
}
