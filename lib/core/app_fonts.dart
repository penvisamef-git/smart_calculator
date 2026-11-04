import 'package:flutter/material.dart';

/// A font style the user can pick in Settings.
/// [display] is used for numbers and titles, [body] for normal text
/// (null = the phone's own font). Khmer, Chinese, Japanese and Korean text
/// automatically falls back to the phone's font for those scripts.
class AppFont {
  const AppFont({
    required this.id,
    required this.name,
    required this.display,
    this.body,
  });

  final String id;
  final String name;
  final String? display;
  final String? body;

  static const cyber = AppFont(id: 'cyber', name: 'Cyber', display: 'Orbitron');
  static const all = [
    cyber,
    AppFont(id: 'inter', name: 'Modern', display: 'Inter', body: 'Inter'),
    AppFont(id: 'poppins', name: 'Smooth', display: 'Poppins', body: 'Poppins'),
    AppFont(id: 'nunito', name: 'Friendly', display: 'Nunito', body: 'Nunito'),
    AppFont(
      id: 'mono',
      name: 'Code',
      display: 'JetBrainsMono',
      body: 'JetBrainsMono',
    ),
    AppFont(
      id: 'quicksand',
      name: 'Soft',
      display: 'Quicksand',
      body: 'Quicksand',
    ),
    AppFont(
      id: 'rajdhani',
      name: 'Tech',
      display: 'Rajdhani',
      body: 'Rajdhani',
    ),
    AppFont(id: 'system', name: 'Phone default', display: null),
  ];

  static AppFont byId(String? id) =>
      all.firstWhere((f) => f.id == id, orElse: () => cyber);
}

/// Makes the chosen display font available to every widget.
@immutable
class AppFontTheme extends ThemeExtension<AppFontTheme> {
  const AppFontTheme(this.font);
  final AppFont font;

  @override
  AppFontTheme copyWith({AppFont? font}) => AppFontTheme(font ?? this.font);

  @override
  AppFontTheme lerp(ThemeExtension<AppFontTheme>? other, double t) =>
      other is AppFontTheme && t >= .5 ? other : this;
}

extension FontX on BuildContext {
  /// Font for big numbers and titles.
  String? get displayFont =>
      Theme.of(this).extension<AppFontTheme>()?.font.display;
}

/// The brand font (splash screen and Premium title always use it).
const kBrandFont = 'Orbitron';
