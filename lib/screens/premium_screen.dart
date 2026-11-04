import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../services/premium_service.dart';
import '../widgets/common.dart';

/// $0.99 one-time unlock: no ads, history forever, unlimited sharing,
/// all colors.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const _bg = Color(0xFF0B0F0E);
  static const _cream = Color(0xFFFFF7E3);
  static const _muted = Color(0xFFA89B78);
  static const _line = Color(0xFF2A2618);
  static const _border = Color(0xFF3A3320);

  late final PremiumService _premium = context.read<PremiumService>();

  @override
  void initState() {
    super.initState();
    _premium.addListener(_onChange);
  }

  @override
  void dispose() {
    _premium.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    final key = switch (_premium.state) {
      PurchaseUiState.failed => 'purchaseFailed',
      PurchaseUiState.nothingToRestore => 'nothingRestore',
      PurchaseUiState.storeUnavailable => 'storeUnavailable',
      _ => null,
    };
    if (key != null) {
      showSnack(context, context.trRead(key));
      _premium.clearState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final busy =
        premium.state == PurchaseUiState.buying ||
        premium.state == PurchaseUiState.restoring;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1810),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: _border),
                    ),
                    fixedSize: const Size(44, 44),
                  ),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded, color: _cream),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: premium.isPremium
                    ? _done(context)
                    : _offer(context, premium),
              ),
              if (premium.isPremium)
                BigButton(
                  label: context.tr('startCalc'),
                  background: AppPalette.gold,
                  foreground: AppPalette.onGold,
                  height: 58,
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                )
              else ...[
                BigButton(
                  label: context.tr('unlockFor', {'price': premium.price}),
                  background: AppPalette.gold,
                  foreground: AppPalette.onGold,
                  height: 58,
                  onPressed: busy ? null : premium.buy,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('oneTime'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: busy ? null : premium.restore,
                  child: busy && premium.state == PurchaseUiState.restoring
                      ? Text(
                          context.tr('restoring'),
                          style: const TextStyle(color: _muted),
                        )
                      : Text(
                          context.tr('restore'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.gold,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _offer(BuildContext context, PremiumService premium) {
    final rows = [
      (context.tr('ads'), context.tr('adsFree'), context.tr('adsPro')),
      (
        context.tr('history'),
        context.tr('historyFree', {'n': AppConfig.freeHistoryDays}),
        context.tr('forever'),
      ),
      (
        context.tr('sharing'),
        context.tr('sharingFree', {'n': AppConfig.freeSharesPerDay}),
        context.tr('unlimited'),
      ),
      (context.tr('colorThemes'), '4', context.tr('themesPro')),
    ];
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppPalette.gold,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.gold.withValues(alpha: .35),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 46,
              color: AppPalette.onGold,
            ),
          ),
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Smart Calculator\n'),
                TextSpan(
                  text: 'Premium',
                  style: TextStyle(color: AppPalette.gold),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kBrandFont,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: _cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('payOnce'),
            style: const TextStyle(fontSize: 15, color: Color(0xFFCDBF98)),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF1A1810)),
                  children: [
                    _cell(
                      context.tr('feature'),
                      header: true,
                      align: TextAlign.left,
                    ),
                    _cell(context.tr('free'), header: true),
                    _cell('Premium', header: true, gold: true),
                  ],
                ),
                for (final r in rows)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _line)),
                    ),
                    children: [
                      _cell(r.$1, align: TextAlign.left, strong: true),
                      _cell(r.$2),
                      Container(
                        color: const Color(0xFF16130A),
                        child: _cell(r.$3, gold: true, strong: true),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String t, {
    bool header = false,
    bool gold = false,
    bool strong = false,
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(
        t,
        textAlign: align,
        style: TextStyle(
          fontSize: header ? 12 : 14,
          fontWeight: header || strong ? FontWeight.w700 : FontWeight.w400,
          color: gold
              ? AppPalette.gold
              : (header ? _muted : (strong ? _cream : _muted)),
        ),
      ),
    );
  }

  Widget _done(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppPalette.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 50,
            color: AppPalette.onGold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('youArePremium'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: kBrandFont,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _cream,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('premiumDone'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFFCDBF98),
          ),
        ),
      ],
    );
  }
}
