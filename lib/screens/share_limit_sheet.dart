import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../services/ads_service.dart';
import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../widgets/common.dart';
import 'premium_screen.dart';

/// Shown when the 3 free shares are used. Returns true when the user earned
/// a bonus share from a rewarded ad (the caller then shares right away).
Future<bool> showShareLimitSheet(BuildContext context, String text) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _LimitSheet(text: text),
  );
  return result ?? false;
}

class _LimitSheet extends StatefulWidget {
  const _LimitSheet({required this.text});
  final String text;

  @override
  State<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends State<_LimitSheet> {
  bool _busy = false;

  Future<void> _watchAd() async {
    final ads = context.read<AdsService>();
    final shares = context.read<ShareService>();
    if (!ads.rewardedReady) {
      ads.loadRewarded();
      showSnack(context, context.trRead('adNotReady'));
      return;
    }
    setState(() => _busy = true);
    final earned = await ads.showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);
    if (earned) {
      shares.addBonusShare();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shares = context.watch<ShareService>();
    final ready = context.watch<AdsService>().rewardedReady;
    final wait = shares.timeUntilReset();
    final time = '${wait.inHours}h ${wait.inMinutes % 60}m';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AppConfig.freeSharesPerDay,
                (_) => Container(
                  width: 26,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('limitTitle', {'max': AppConfig.freeSharesPerDay}),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('limitReset', {'time': time}),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.muted),
            ),
            const SizedBox(height: 18),
            _Option(
              icon: Icons.play_arrow_rounded,
              iconBg: Color.lerp(p.surface, p.accent, .2)!,
              iconFg: p.accent,
              title: context.tr('watchAd'),
              subtitle: context.tr('watchAdSub'),
              trailing: _busy || !ready
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.accent,
                      ),
                    )
                  : Text(
                      '+1',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
              onTap: _busy ? null : _watchAd,
            ),
            const SizedBox(height: 10),
            _Option(
              icon: Icons.workspace_premium_rounded,
              iconBg: AppPalette.gold,
              iconFg: AppPalette.onGold,
              bg: const Color(0xFF2A230E),
              border: const Color(0xFF6B5A22),
              titleColor: const Color(0xFFFFF4D6),
              subColor: const Color(0xFFD9C58F),
              title: context.tr('unlimitedSharing'),
              subtitle: context.tr('unlimitedSub'),
              trailing: Text(
                context.watch<PremiumService>().price,
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.gold,
                ),
              ),
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop(false);
                nav.push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.text));
                Navigator.pop(context, false);
              },
              child: Text(
                context.tr('copyInstead'),
                style: TextStyle(fontWeight: FontWeight.w600, color: p.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.bg,
    this.border,
    this.titleColor,
    this.subColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? border;
  final Color? titleColor;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: bg ?? p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border ?? p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconFg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? p.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subColor ?? p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
