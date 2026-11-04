import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../services/history_repository.dart';
import '../services/premium_service.dart';
import '../services/settings_controller.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'premium_screen.dart';
import 'themes_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = context.watch<SettingsController>();
    final premium = context.watch<PremiumService>();
    final hasHistory = context.select<HistoryRepository, bool>(
      (h) => h.count > 0,
    );
    void open(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: context.tr('settings')),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _premiumCard(
                      context,
                      premium,
                      () => open(const PremiumScreen()),
                    ),
                    const SizedBox(height: 16),
                    SectionLabel(context.tr('general')),
                    const SizedBox(height: 6),
                    _Group(
                      children: [
                        _Row(
                          title: context.tr('colorTheme'),
                          value: settings
                              .palette(isPremium: premium.isPremium)
                              .name,
                          onTap: () => open(const ThemesScreen()),
                        ),
                        _Row(
                          title: context.tr('language'),
                          value: S.nativeNames[settings.language],
                          onTap: () => showLanguagePicker(context),
                        ),
                        _Row(
                          title: context.tr('fontStyle'),
                          value: settings.font.name,
                          onTap: () => showFontPicker(context),
                        ),
                        _SwitchRow(
                          title: context.tr('vibration'),
                          subtitle: context.tr('vibrationSub'),
                          value: settings.vibration,
                          onChanged: settings.setVibration,
                        ),
                        _SwitchRow(
                          title: context.tr('liveResult'),
                          subtitle: context.tr('liveResultSub'),
                          value: settings.liveResult,
                          onChanged: settings.setLiveResult,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SectionLabel(context.tr('history')),
                    const SizedBox(height: 6),
                    _Group(
                      children: [
                        _Row(
                          title: context.tr('keepHistory'),
                          value: premium.isPremium
                              ? context.tr('forever')
                              : context.tr('historyFree', {
                                  'n': AppConfig.freeHistoryDays,
                                }),
                          trailing: premium.isPremium
                              ? null
                              : PremiumTag(context.tr('forever')),
                          onTap: premium.isPremium
                              ? null
                              : () => open(const PremiumScreen()),
                        ),
                        _Row(
                          title: context.tr('deleteAll'),
                          danger: true,
                          icon: Icons.delete_outline_rounded,
                          onTap: hasHistory
                              ? () => confirmDeleteAll(context)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SectionLabel(context.tr('purchase')),
                    const SizedBox(height: 6),
                    _Group(
                      children: [
                        _Row(
                          title: context.tr('restore'),
                          onTap: () {
                            premium.restore();
                            open(const PremiumScreen());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        context.tr('poweredBy').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: p.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Tooltip(
                        message: context.tr('visitWebsite'),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => openCompanyWebsite(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Image.asset(
                              'assets/images/cyber_logo.png',
                              height: 48,
                              semanticLabel: context.tr('visitWebsite'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${AppConfig.appName} · ${context.tr('version')} $appVersion',
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumCard(
    BuildContext context,
    PremiumService premium,
    VoidCallback onTap,
  ) {
    return Material(
      color: const Color(0xFF2A230E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF6B5A22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: premium.isPremium ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppPalette.onGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        premium.isPremium ? 'premiumActive' : 'freePlan',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFF4D6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        premium.isPremium ? 'premiumActiveSub' : 'freePlanSub',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD9C58F),
                      ),
                    ),
                  ],
                ),
              ),
              if (!premium.isPremium)
                Text(
                  premium.price,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.gold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.border.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: p.border.withValues(alpha: .7)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.icon,
  });
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? const Color(0xFFFF8A80) : p.text;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: danger ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(value!, style: TextStyle(fontSize: 13, color: p.muted)),
                const SizedBox(width: 8),
              ],
              ?trailing,
              if (trailing == null && onTap != null && !danger)
                Icon(Icons.chevron_right_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: p.onAccent,
      activeTrackColor: p.accent,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: p.text,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: p.muted)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}

/// Opens https://ctscambodia.com/ in the browser.
Future<void> openCompanyWebsite(BuildContext context) async {
  final ok = await launchUrl(
    Uri.parse(AppConfig.companyUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    showSnack(context, context.trRead('cantOpenLink'));
  }
}

Future<void> showLanguagePicker(BuildContext context) {
  final settings = context.read<SettingsController>();
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                ctx.tr('chooseLanguage'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
            for (final code in S.supported)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(
                  S.nativeNames[code]!,
                  style: TextStyle(fontSize: 16, color: p.text),
                ),
                trailing: code == settings.language
                    ? Icon(Icons.check_circle_rounded, color: p.accent)
                    : null,
                onTap: () {
                  settings.setLanguage(code);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> showFontPicker(BuildContext context) {
  final settings = context.read<SettingsController>();
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  ctx.tr('chooseFont'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  for (final f in AppFont.all)
                    _FontTile(
                      font: f,
                      selected: f.id == settings.font.id,
                      onTap: () {
                        settings.setFont(f.id);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.font,
    required this.selected,
    required this.onTap,
  });
  final AppFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: font.name,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? p.accent : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '12 + 34 = 46',
                    style: TextStyle(
                      fontFamily: font.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: selected ? p.accent : p.text,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  font.name,
                  style: TextStyle(
                    fontFamily: font.body,
                    fontSize: 12,
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
