import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/calc_engine.dart';
import '../core/strings.dart';
import '../core/tools_math.dart';
import '../services/settings_controller.dart';
import '../widgets/ad_banner.dart';
import '../widgets/common.dart';

/// Quick tools: discount, VAT, tip & split, loan, profit margin, USD ⇄ riel.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <(String, IconData, Widget Function())>[
      ('toolDiscount', Icons.local_offer_rounded, () => const _DiscountTool()),
      ('toolVat', Icons.receipt_long_rounded, () => const _VatTool()),
      ('toolTip', Icons.groups_rounded, () => const _TipTool()),
      ('toolLoan', Icons.account_balance_rounded, () => const _LoanTool()),
      ('toolMargin', Icons.trending_up_rounded, () => const _MarginTool()),
      (
        'toolCurrency',
        Icons.currency_exchange_rounded,
        () => const _CurrencyTool(),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScreenHeader(title: context.tr('tools')),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          for (final t in tools)
                            _ToolCard(
                              title: context.tr(t.$1),
                              icon: t.$2,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _ToolPage(titleKey: t.$1, child: t.$3()),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AdBanner(),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color.lerp(p.surface, p.accent, .2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: p.accent),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({required this.titleKey, required this.child});
  final String titleKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: context.tr(titleKey)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- shared building blocks ----------

double _num(TextEditingController c) =>
    double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;
String _fmt(double v, {int decimals = 2}) {
  final f = 1.0 * _pow10(decimals);
  return CalcEngine.formatNumber((v * f).roundToDouble() / f);
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: p.muted),
          suffixText: suffix,
          suffixStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: p.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Result rows; the first one is the main (big) answer. Tap to copy.
class _Results extends StatelessWidget {
  const _Results(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: rows[i].$2));
                showSnack(context, context.trRead('copied'));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        style: TextStyle(
                          fontSize: i == 0 ? 15 : 14,
                          color: i == 0 ? p.text : p.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          rows[i].$2,
                          style: TextStyle(
                            fontFamily: i == 0 ? context.displayFont : null,
                            fontSize: i == 0 ? 28 : 17,
                            fontWeight: FontWeight.w700,
                            color: i == 0 ? p.accent : p.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Base for tools with text fields that recompute on every change.
abstract class _ToolState<T extends StatefulWidget> extends State<T> {
  final Map<String, TextEditingController> _c = {};

  TextEditingController ctl(String key, [String initial = '']) =>
      _c.putIfAbsent(key, () => TextEditingController(text: initial));

  void refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }
}

// ---------- the tools ----------

class _DiscountTool extends StatefulWidget {
  const _DiscountTool();
  @override
  State<_DiscountTool> createState() => _DiscountToolState();
}

class _DiscountToolState extends _ToolState<_DiscountTool> {
  @override
  Widget build(BuildContext context) {
    final r = ToolsMath.discount(
      _num(ctl('price', '100')),
      _num(ctl('pct', '20')),
    );
    return Column(
      children: [
        _Field(
          label: context.tr('price'),
          controller: ctl('price', '100'),
          onChanged: refresh,
        ),
        _Field(
          label: context.tr('discountPct'),
          controller: ctl('pct', '20'),
          onChanged: refresh,
          suffix: '%',
        ),
        _Results([
          (context.tr('youPay'), _fmt(r.pay)),
          (context.tr('youSave'), _fmt(r.save)),
        ]),
      ],
    );
  }
}

class _VatTool extends StatefulWidget {
  const _VatTool();
  @override
  State<_VatTool> createState() => _VatToolState();
}

class _VatToolState extends _ToolState<_VatTool> {
  bool _add = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = ToolsMath.vat(
      _num(ctl('amt', '100')),
      _num(ctl('rate', '10')),
      add: _add,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: p.accent,
            selectedForegroundColor: p.onAccent,
            foregroundColor: p.text,
            side: BorderSide(color: p.border),
          ),
          segments: [
            ButtonSegment(value: true, label: Text(context.tr('addVat'))),
            ButtonSegment(value: false, label: Text(context.tr('removeVat'))),
          ],
          selected: {_add},
          onSelectionChanged: (s) => setState(() => _add = s.first),
        ),
        const SizedBox(height: 14),
        _Field(
          label: context.tr('amount'),
          controller: ctl('amt', '100'),
          onChanged: refresh,
        ),
        _Field(
          label: context.tr('vatRate'),
          controller: ctl('rate', '10'),
          onChanged: refresh,
          suffix: '%',
        ),
        _Results(
          _add
              ? [
                  (context.tr('total'), _fmt(r.total)),
                  (context.tr('vatAmount'), _fmt(r.vat)),
                ]
              : [
                  (context.tr('beforeVat'), _fmt(r.before)),
                  (context.tr('vatAmount'), _fmt(r.vat)),
                ],
        ),
      ],
    );
  }
}

class _TipTool extends StatefulWidget {
  const _TipTool();
  @override
  State<_TipTool> createState() => _TipToolState();
}

class _TipToolState extends _ToolState<_TipTool> {
  @override
  Widget build(BuildContext context) {
    final r = ToolsMath.tipSplit(
      _num(ctl('bill', '60')),
      _num(ctl('tip', '10')),
      _num(ctl('people', '3')).round(),
    );
    return Column(
      children: [
        _Field(
          label: context.tr('bill'),
          controller: ctl('bill', '60'),
          onChanged: refresh,
        ),
        _Field(
          label: context.tr('tipPct'),
          controller: ctl('tip', '10'),
          onChanged: refresh,
          suffix: '%',
        ),
        _Field(
          label: context.tr('people'),
          controller: ctl('people', '3'),
          onChanged: refresh,
        ),
        _Results([
          (context.tr('perPerson'), _fmt(r.each)),
          (context.tr('tipAmount'), _fmt(r.tip)),
          (context.tr('total'), _fmt(r.total)),
        ]),
      ],
    );
  }
}

class _LoanTool extends StatefulWidget {
  const _LoanTool();
  @override
  State<_LoanTool> createState() => _LoanToolState();
}

class _LoanToolState extends _ToolState<_LoanTool> {
  @override
  Widget build(BuildContext context) {
    final r = ToolsMath.loan(
      _num(ctl('amt', '5000')),
      _num(ctl('rate', '12')),
      _num(ctl('months', '24')).round(),
    );
    return Column(
      children: [
        _Field(
          label: context.tr('loanAmount'),
          controller: ctl('amt', '5000'),
          onChanged: refresh,
        ),
        _Field(
          label: context.tr('interestYear'),
          controller: ctl('rate', '12'),
          onChanged: refresh,
          suffix: '%',
        ),
        _Field(
          label: context.tr('months'),
          controller: ctl('months', '24'),
          onChanged: refresh,
        ),
        _Results([
          (context.tr('monthlyPay'), _fmt(r.monthly)),
          (context.tr('totalInterest'), _fmt(r.interest)),
          (context.tr('totalPay'), _fmt(r.total)),
        ]),
      ],
    );
  }
}

class _MarginTool extends StatefulWidget {
  const _MarginTool();
  @override
  State<_MarginTool> createState() => _MarginToolState();
}

class _MarginToolState extends _ToolState<_MarginTool> {
  @override
  Widget build(BuildContext context) {
    final r = ToolsMath.margin(
      _num(ctl('cost', '8')),
      _num(ctl('price', '10')),
    );
    return Column(
      children: [
        _Field(
          label: context.tr('cost'),
          controller: ctl('cost', '8'),
          onChanged: refresh,
        ),
        _Field(
          label: context.tr('sellPrice'),
          controller: ctl('price', '10'),
          onChanged: refresh,
        ),
        _Results([
          (context.tr('profit'), _fmt(r.profit)),
          (context.tr('margin'), '${_fmt(r.margin, decimals: 1)}%'),
          (context.tr('markup'), '${_fmt(r.markup, decimals: 1)}%'),
        ]),
      ],
    );
  }
}

class _CurrencyTool extends StatefulWidget {
  const _CurrencyTool();
  @override
  State<_CurrencyTool> createState() => _CurrencyToolState();
}

class _CurrencyToolState extends _ToolState<_CurrencyTool> {
  bool _usdToKhr = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = context.watch<SettingsController>();
    final rate = settings.khrRate;
    final amount = _num(ctl('amt', '10'));
    final result = _usdToKhr
        ? '${_fmt(ToolsMath.usdToKhr(amount, rate), decimals: 0)} ៛'
        : '\$${_fmt(ToolsMath.khrToUsd(amount, rate))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: p.accent,
            selectedForegroundColor: p.onAccent,
            foregroundColor: p.text,
            side: BorderSide(color: p.border),
          ),
          segments: const [
            ButtonSegment(value: true, label: Text(r'$ → ៛')),
            ButtonSegment(value: false, label: Text(r'៛ → $')),
          ],
          selected: {_usdToKhr},
          onSelectionChanged: (s) => setState(() => _usdToKhr = s.first),
        ),
        const SizedBox(height: 14),
        _Field(
          label: _usdToKhr ? context.tr('usd') : context.tr('khr'),
          controller: ctl('amt', '10'),
          onChanged: refresh,
          suffix: _usdToKhr ? r'$' : '៛',
        ),
        _Results([(_usdToKhr ? context.tr('khr') : context.tr('usd'), result)]),
        const SizedBox(height: 12),
        BigButton(
          label:
              '${context.tr('exchangeRate')}: 1 \$ = ${_fmt(rate, decimals: 0)} ៛',
          icon: Icons.edit_rounded,
          outlined: true,
          onPressed: () => editExchangeRate(context),
        ),
      ],
    );
  }
}

/// Dialog to change the USD → riel rate (used by the calculator and tools).
Future<void> editExchangeRate(BuildContext context) async {
  final settings = context.read<SettingsController>();
  final p = context.palette;
  final c = TextEditingController(text: settings.khrRate.round().toString());
  final value = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        ctx.tr('exchangeRate'),
        style: TextStyle(color: p.text, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
        decoration: InputDecoration(
          prefixText: r'1 $ = ',
          suffixText: '៛',
          helperText: ctx.tr('rateHint'),
          helperStyle: TextStyle(color: p.muted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.tr('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, double.tryParse(c.text)),
          child: Text(
            ctx.tr('save'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  c.dispose();
  if (value != null && value > 0) settings.setKhrRate(value);
}
