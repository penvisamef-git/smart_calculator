import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// One color theme of the app. Read it in widgets with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.name,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.muted,
    required this.isLight,
    this.premium = false,
  });

  final String id;
  final String name;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color text;
  final Color muted;
  final bool isLight;
  final bool premium;

  // Shared colors that stay the same in every theme.
  static const gold = Color(0xFFF2C14E);
  static const onGold = Color(0xFF2A1E00);
  static const danger = Color(0xFFFF6B61);
  static const success = Color(0xFF5FD3A8);

  AppPalette withAccent(Color c) => copyWith(
    accent: c,
    onAccent: c.computeLuminance() > 0.4
        ? const Color(0xFF061419)
        : Colors.white,
  );

  @override
  AppPalette copyWith({Color? accent, Color? onAccent}) => AppPalette(
    id: id,
    name: name,
    bg: bg,
    surface: surface,
    surfaceAlt: surfaceAlt,
    border: border,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    text: text,
    muted: muted,
    isLight: isLight,
    premium: premium,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      id: t < .5 ? id : other.id,
      name: t < .5 ? name : other.name,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      isLight: t < .5 ? isLight : other.isLight,
      premium: t < .5 ? premium : other.premium,
    );
  }
}

class AppThemes {
  AppThemes._();

  static const cyberTeal = AppPalette(
    id: 'teal',
    name: 'Cyber Teal',
    bg: Color(0xFF061419),
    surface: Color(0xFF0E2A33),
    surfaceAlt: Color(0xFF0B242C),
    border: Color(0xFF1F4A57),
    accent: Color(0xFF3FB8C3),
    onAccent: Color(0xFF061419),
    text: Color(0xFFE6F6F8),
    muted: Color(0xFF8FB5BD),
    isLight: false,
  );
  static const midnight = AppPalette(
    id: 'midnight',
    name: 'Midnight',
    bg: Color(0xFF0B1020),
    surface: Color(0xFF18213A),
    surfaceAlt: Color(0xFF131A2E),
    border: Color(0xFF2A3658),
    accent: Color(0xFF7AA2FF),
    onAccent: Color(0xFF0B1020),
    text: Color(0xFFE8EDFF),
    muted: Color(0xFF9AA6C8),
    isLight: false,
  );
  static const paper = AppPalette(
    id: 'paper',
    name: 'Paper',
    bg: Color(0xFFF3F7F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE8EFF1),
    border: Color(0xFFCFDDE1),
    accent: Color(0xFF0B7A86),
    onAccent: Colors.white,
    text: Color(0xFF0C2A33),
    muted: Color(0xFF4D6B73),
    isLight: true,
  );
  static const mint = AppPalette(
    id: 'mint',
    name: 'Mint',
    bg: Color(0xFF06170F),
    surface: Color(0xFF0F2B20),
    surfaceAlt: Color(0xFF0B2219),
    border: Color(0xFF245446),
    accent: Color(0xFF5FD3A8),
    onAccent: Color(0xFF06170F),
    text: Color(0xFFE3F7EE),
    muted: Color(0xFF8DBFA9),
    isLight: false,
  );
  static const angkorGold = AppPalette(
    id: 'gold',
    name: 'Angkor Gold',
    bg: Color(0xFF16110A),
    surface: Color(0xFF2A2112),
    surfaceAlt: Color(0xFF211A0E),
    border: Color(0xFF4A3B1E),
    accent: Color(0xFFF2C14E),
    onAccent: Color(0xFF2A1E00),
    text: Color(0xFFFFF4D6),
    muted: Color(0xFFC9B583),
    isLight: false,
    premium: true,
  );
  static const lotusPink = AppPalette(
    id: 'lotus',
    name: 'Lotus Pink',
    bg: Color(0xFF1A0D14),
    surface: Color(0xFF33192A),
    surfaceAlt: Color(0xFF281420),
    border: Color(0xFF5A2E48),
    accent: Color(0xFFF28CC0),
    onAccent: Color(0xFF1A0D14),
    text: Color(0xFFFFE8F3),
    muted: Color(0xFFC99AB2),
    isLight: false,
    premium: true,
  );

  static const all = [cyberTeal, midnight, paper, mint, angkorGold, lotusPink];

  /// Custom accent colors (Premium).
  static const customAccents = [
    Color(0xFF3FB8C3),
    Color(0xFF5FD3A8),
    Color(0xFF7AA2FF),
    Color(0xFFB18CFF),
    Color(0xFFF28CC0),
    Color(0xFFFF8A65),
    Color(0xFFF2C14E),
    Color(0xFFE6F6F8),
  ];

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => cyberTeal);

  /// [fontFallback] is only used by screenshot tests.
  static ThemeData build(
    AppPalette p, {
    AppFont font = AppFont.cyber,
    List<String>? fontFallback,
  }) {
    final base = p.isLight ? ThemeData.light() : ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      colorScheme:
          (p.isLight ? const ColorScheme.light() : const ColorScheme.dark())
              .copyWith(
                primary: p.accent,
                onPrimary: p.onAccent,
                surface: p.surface,
                onSurface: p.text,
                error: AppPalette.danger,
              ),
      textTheme: base.textTheme.apply(
        bodyColor: p.text,
        displayColor: p.text,
        fontFamily: font.body,
        fontFamilyFallback: fontFallback,
      ),
      dividerColor: p.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface,
        contentTextStyle: TextStyle(color: p.text),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceAlt,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.accent),
      extensions: [p, AppFontTheme(font)],
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
