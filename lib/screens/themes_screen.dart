import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/strings.dart';
import '../services/premium_service.dart';
import '../services/settings_controller.dart';
import '../widgets/common.dart';
import 'premium_screen.dart';

/// Color panel: preset themes + custom accent color (Premium).
class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late String _pick = context.read<SettingsController>().themeId;
  late Color? _custom = context.read<SettingsController>().customAccent;
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isPremium = context.watch<PremiumService>().isPremium;
    final settings = context.watch<SettingsController>();
    var preview = AppThemes.byId(_pick);
    if (_custom != null) preview = preview.withAccent(_custom!);
    final locked =
        !isPremium && (AppThemes.byId(_pick).premium || _custom != null);
    final isCurrent =
        _pick == settings.themeId && _custom == settings.customAccent;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: context.tr('colors')),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    _Preview(palette: preview),
                    const SizedBox(height: 18),
                    SectionLabel(context.tr('themes')),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: .95,
                      children: [
                        for (final t in AppThemes.all)
                          _ThemeTile(
                            theme: t,
                            selected: _pick == t.id,
                            locked: t.premium && !isPremium,
                            onTap: () => setState(() {
                              _pick = t.id;
                              _custom = null;
                              _applied = false;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionLabel(
                      context.tr('customAccent'),
                      trailing: isPremium
                          ? null
                          : PremiumTag(context.tr('premiumTag')),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in AppThemes.customAccents)
                          Semantics(
                            button: true,
                            selected: _custom == c,
                            label: 'Accent color',
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _custom = _custom == c ? null : c;
                                _applied = false;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _custom == c
                                        ? p.text
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (locked) ...[
                Panel(
                  color: const Color(0xFF2A230E),
                  borderColor: const Color(0xFF6B5A22),
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('inPremium'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFFFF4D6),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PremiumScreen(),
                          ),
                        ),
                        child: Text(
                          context.tr('unlockPrice', {
                            'price': context.watch<PremiumService>().price,
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              BigButton(
                label: _applied || (isCurrent && !locked)
                    ? context.tr('applied')
                    : context.tr('applyTheme'),
                background: preview.accent,
                foreground: preview.onAccent,
                onPressed: locked
                    ? null
                    : () {
                        settings.setTheme(_pick, customAccent: _custom);
                        setState(() => _applied = true);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Widget key(String s, {bool op = false, bool eq = false}) => Container(
      decoration: BoxDecoration(
        color: eq ? p.accent : p.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        s,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: eq ? p.onAccent : (op ? p.accent : p.text),
        ),
      ),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
      ),
      child: SizedBox(
        height: 104,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '12,500 + 8,000 × 3',
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '36,500',
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 92,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 43 / 30,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  key('7'),
                  key('×', op: true),
                  key('4'),
                  key('+', op: true),
                  key('0'),
                  key('=', eq: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.onTap,
  });
  final AppPalette theme;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: theme.name + (locked ? ' (Premium)' : ''),
      excludeSemantics: true,
      child: Material(
        color: p.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? p.accent : p.border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(6),
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _dot(theme.surface),
                            const SizedBox(width: 4),
                            _dot(theme.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      theme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppPalette.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppPalette.onGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
  );
}
