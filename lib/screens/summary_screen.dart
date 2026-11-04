import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/calc_engine.dart';
import '../core/strings.dart';
import '../services/history_repository.dart';
import '../services/premium_service.dart';
import '../widgets/common.dart';
import 'history_screen.dart' show tagIcon;
import 'premium_screen.dart';

/// Monthly summary: how many calculations, active days, totals per tag.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrent {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repo = context.watch<HistoryRepository>();
    final isPremium = context.watch<PremiumService>().isPremium;
    final s = MonthSummary(_month, repo.items);
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat.yMMMM(locale).format(_month);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: context.tr('summary')),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .previousMonthTooltip,
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    icon: Icon(Icons.chevron_left_rounded, color: p.text),
                  ),
                  Expanded(
                    child: Text(
                      monthName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                    onPressed: _isCurrent
                        ? null
                        : () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month + 1,
                            ),
                          ),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _isCurrent ? p.border : p.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Row(
                      children: [
                        _Stat(
                          label: context.tr('calcCount'),
                          value: '${s.count}',
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          label: context.tr('activeDays'),
                          value: '${s.activeDays}',
                        ),
                        const SizedBox(width: 10),
                        _Stat(
                          label: context.tr('topTag'),
                          value: s.topTag == null
                              ? '—'
                              : context.tr('tag_${s.topTag}'),
                          small: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Panel(child: _DayBars(perDay: s.perDay)),
                    const SizedBox(height: 18),
                    if (s.count == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          context.tr('noDataMonth'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted),
                        ),
                      )
                    else ...[
                      SectionLabel(context.tr('byTag')),
                      const SizedBox(height: 8),
                      for (final t in s.byTag) ...[
                        Panel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                t.tag.isEmpty
                                    ? Icons.label_off_outlined
                                    : tagIcon(t.tag),
                                color: p.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.tag.isEmpty
                                          ? context.tr('tagNone')
                                          : context.tr('tag_${t.tag}'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: p.text,
                                      ),
                                    ),
                                    Text(
                                      '${context.tr('calcCount')}: ${t.count}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: p.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    CalcEngine.formatNumber(t.total),
                                    style: TextStyle(
                                      fontFamily: context.displayFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: p.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    if (!isPremium) ...[
                      const SizedBox(height: 8),
                      Panel(
                        color: const Color(0xFF2A230E),
                        borderColor: const Color(0xFF6B5A22),
                        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('summaryFreeNote'),
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
                                context.tr('keepForever'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.small = false});
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Panel(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: small ? null : context.displayFont,
                    fontSize: small ? 18 : 26,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple bar per day of the month.
class _DayBars extends StatelessWidget {
  const _DayBars({required this.perDay});
  final List<int> perDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = max(1, perDay.fold<int>(0, max));
    return Semantics(
      label: 'Calculations per day',
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < perDay.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: perDay[i] == 0 ? 3 : 8 + 70 * perDay[i] / top,
                        decoration: BoxDecoration(
                          color: perDay[i] == 0 ? p.border : p.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 12,
                        child: (i == 0 || (i + 1) % 5 == 0)
                            ? FittedBox(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(fontSize: 9, color: p.muted),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
