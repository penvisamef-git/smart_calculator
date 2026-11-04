import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/calc_engine.dart';
import '../core/strings.dart';
import '../services/calculator_controller.dart';
import '../services/history_repository.dart';
import '../services/settings_controller.dart';
import '../services/voice_service.dart';
import '../core/tools_math.dart';
import '../widgets/ad_banner.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'share_screen.dart';
import 'themes_screen.dart';
import 'tools_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const _layout = [
    ['AC', 'fn'],
    ['( )', 'fn'],
    ['%', 'fn'],
    [Ops.div, 'op'],
    ['7', 'n'],
    ['8', 'n'],
    ['9', 'n'],
    [Ops.mul, 'op'],
    ['4', 'n'],
    ['5', 'n'],
    ['6', 'n'],
    [Ops.sub, 'op'],
    ['1', 'n'],
    ['2', 'n'],
    ['3', 'n'],
    [Ops.add, 'op'],
    ['0', 'n'],
    ['.', 'n'],
    ['back', 'fn'],
    ['=', 'eq'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final keyH = ((c.maxHeight * .52 - 40) / 5).clamp(
                      46.0,
                      68.0,
                    );
                    return Column(
                      children: [
                        _topBar(context),
                        const SizedBox(height: 12),
                        const Expanded(child: _Display()),
                        const SizedBox(height: 12),
                        _chips(context),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: ((c.maxWidth - 30) / 4) / keyH,
                          children: [
                            for (final k in _layout)
                              _CalcKey(label: k[0], kind: k[1]),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const AdBanner(),
          ],
        ),
      ),
      backgroundColor: p.bg,
    );
  }

  Widget _topBar(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SquareIconButton(
            icon: Icons.history_rounded,
            tooltip: context.tr('history'),
            onPressed: () => _push(context, const HistoryScreen()),
          ),
          const SizedBox(width: 8),
          SquareIconButton(
            icon: Icons.grid_view_rounded,
            tooltip: context.tr('tools'),
            onPressed: () => _push(context, const ToolsScreen()),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Calculator',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                  color: context.palette.text,
                ),
              ),
            ),
          ),
          SquareIconButton(
            icon: Icons.palette_outlined,
            tooltip: context.tr('colors'),
            onPressed: () => _push(context, const ThemesScreen()),
          ),
          const SizedBox(width: 8),
          SquareIconButton(
            icon: Icons.settings_outlined,
            tooltip: context.tr('settings'),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _chips(BuildContext context) {
    final mode = context.select<SettingsController, String>(
      (s) => s.convertMode,
    );
    final listening = context.select<VoiceService, bool>((v) => v.listening);
    return Row(
      children: [
        _RoundToggle(
          tooltip: context.tr('voice'),
          icon: listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          active: listening,
          onPressed: () => _voice(context),
        ),
        const SizedBox(width: 8),
        _RoundToggle(
          tooltip: context.tr('convert'),
          label: switch (mode) {
            'usd' => r'$→៛',
            'khr' => r'៛→$',
            _ => r'$⇄៛',
          },
          active: mode != 'off',
          onPressed: () =>
              context.read<SettingsController>().cycleConvertMode(),
        ),
        const Spacer(),
        PillButton(
          icon: Icons.copy_rounded,
          label: context.tr('copy'),
          onPressed: () {
            final calc = context.read<CalculatorController>();
            final v = calc.liveValue;
            if (v == null) return;
            final text =
                calc.lastSaved?.line ??
                (RegExp(r'^[−]?[0-9.]+$').hasMatch(calc.expression)
                    ? CalcEngine.formatNumber(v)
                    : '${calc.pretty} = ${CalcEngine.formatNumber(v)}');
            Clipboard.setData(ClipboardData(text: text));
            showSnack(context, context.trRead('copied'));
          },
        ),
        const SizedBox(width: 8),
        PillButton(
          icon: Icons.share_outlined,
          label: context.tr('share'),
          onPressed: () {
            final calc = context.read<CalculatorController>();
            var item = calc.lastSaved;
            final v = calc.liveValue;
            final hasOp = !RegExp(r'^[−]?[0-9.]+$').hasMatch(calc.expression);
            if (item == null && v != null && hasOp) {
              item = context.read<HistoryRepository>().add(calc.expression, v);
              calc.lastSaved = item;
            }
            _push(
              context,
              ShareScreen(preselected: item == null ? const [] : [item.id]),
            );
          },
        ),
      ],
    );
  }

  static Future<void> _voice(BuildContext context) async {
    final voice = context.read<VoiceService>();
    if (voice.listening) {
      await voice.stop();
      return;
    }
    final calc = context.read<CalculatorController>();
    final lang = context.read<SettingsController>().language;
    final ok = await voice.listen(lang, (expr) {
      if (expr == null) {
        if (context.mounted) showSnack(context, context.trRead('voiceNoMatch'));
        return;
      }
      calc.setExpression(expr);
    });
    if (!ok && context.mounted) {
      showSnack(context, context.trRead('voiceNotAvailable'));
    }
  }

  static void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _Display extends StatelessWidget {
  const _Display();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final calc = context.watch<CalculatorController>();
    final history = context.watch<HistoryRepository>();
    final live = context.select<SettingsController, bool>((s) => s.liveResult);
    final v = calc.liveValue;
    final isJustNumber = RegExp(r'^[−]?[0-9.]*$').hasMatch(calc.expression);
    final showResult = v != null && !isJustNumber && live;
    final last = history.items.isEmpty ? null : history.items.first;
    final settings = context.watch<SettingsController>();
    final voice = context.watch<VoiceService>();
    final convertLine = v == null ? null : _convertText(settings, v);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Color.lerp(p.bg, p.surface, .45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border.withValues(alpha: .6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (voice.listening)
            Text(
              voice.heard.isEmpty ? context.tr('listening') : voice.heard,
              maxLines: 2,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: p.accent,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (last != null)
            Text(
              last.hasName ? '${last.name} · ${last.line}' : last.line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: p.muted.withValues(alpha: .8),
              ),
            ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                calc.pretty,
                style: TextStyle(
                  fontSize: showResult ? 26 : 48,
                  fontWeight: showResult ? FontWeight.w500 : FontWeight.w700,
                  fontFamily: showResult ? null : context.displayFont,
                  color: showResult ? Color.lerp(p.text, p.muted, .4) : p.text,
                ),
              ),
            ),
          ),
          if (showResult) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '= ${CalcEngine.formatNumber(v)}',
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ),
          ],
          if (convertLine != null) ...[
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => editExchangeRate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          convertLine,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_rounded, size: 14, color: p.muted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "$36,500 ≈ 149,650,000 ៛" or "36,500 ៛ ≈ $8.90" (null when off).
String? _convertText(SettingsController s, double v) {
  final rate = s.khrRate;
  switch (s.convertMode) {
    case 'usd':
      return '\$${CalcEngine.formatNumber(v)} ≈ ${CalcEngine.formatNumber(ToolsMath.usdToKhr(v, rate).roundToDouble())} ៛';
    case 'khr':
      final usd = (ToolsMath.khrToUsd(v, rate) * 100).roundToDouble() / 100;
      return '${CalcEngine.formatNumber(v)} ៛ ≈ \$${CalcEngine.formatNumber(usd)}';
  }
  return null;
}

/// Small round toggle button (voice, convert).
class _RoundToggle extends StatelessWidget {
  const _RoundToggle({
    required this.tooltip,
    required this.onPressed,
    required this.active,
    this.icon,
    this.label,
  });
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? p.onAccent : p.text;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? p.accent : p.surface,
        shape: StadiumBorder(
          side: BorderSide(color: active ? p.accent : p.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 20, color: fg, semanticLabel: tooltip)
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.kind});
  final String label;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isEq = kind == 'eq';
    final isOp = kind == 'op';
    final isFn = kind == 'fn';
    final bg = isEq
        ? p.accent
        : isOp
        ? Color.lerp(p.surface, p.accent, .14)!
        : isFn
        ? Color.lerp(p.surface, p.border, .3)!
        : p.surface;
    final fg = isEq
        ? p.onAccent
        : isOp
        ? p.accent
        : isFn
        ? Color.lerp(p.accent, p.text, .35)!
        : p.text;

    final semantic = switch (label) {
      'back' => context.tr('deleteLast'),
      Ops.mul => 'times',
      Ops.div => 'divided by',
      Ops.sub => 'minus',
      _ => label,
    };

    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: bg,
        elevation: 0,
        shadowColor: p.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isEq
              ? BorderSide.none
              : BorderSide(color: p.border.withValues(alpha: .7)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (context.read<SettingsController>().vibration) {
              HapticFeedback.selectionClick();
            }
            context.read<CalculatorController>().press(label);
          },
          onLongPress: label == 'back'
              ? () => context.read<CalculatorController>().press('AC')
              : null,
          child: Center(
            child: label == 'back'
                ? Icon(Icons.backspace_outlined, color: fg, size: 26)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: isOp || isEq ? 30 : (isFn ? 20 : 26),
                      fontWeight: isEq ? FontWeight.w800 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
