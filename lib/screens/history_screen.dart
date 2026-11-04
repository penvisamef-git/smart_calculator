import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../models/history_item.dart';
import '../services/history_repository.dart';
import '../services/premium_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/common.dart';
import 'history_detail_sheet.dart';
import 'premium_screen.dart';
import 'summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  String? _tag; // null = all tags

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repo = context.watch<HistoryRepository>();
    final isPremium = context.watch<PremiumService>().isPremium;
    if (_tag != null && !repo.usedTags.contains(_tag)) _tag = null;
    final results = repo.search(_search.text, tag: _tag);
    final pinned = results.where((i) => i.pinned).toList();
    final groups = _group(context, results.where((i) => !i.pinned).toList());
    if (pinned.isNotEmpty) {
      groups.insert(0, _Group(context.tr('pinned'))..items.addAll(pinned));
    }

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
                    ScreenHeader(
                      title: context.tr('history'),
                      actions: [
                        SquareIconButton(
                          icon: Icons.insights_rounded,
                          tooltip: context.tr('summary'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SummaryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (repo.count > 0)
                          SquareIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: context.tr('deleteAll'),
                            color: AppPalette.danger,
                            onPressed: () => confirmDeleteAll(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: p.text, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.tr('searchHint'),
                        hintStyle: TextStyle(color: p.muted),
                        prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                        filled: true,
                        fillColor: p.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
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
                    if (repo.usedTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _TagFilter(
                              label: context.tr('all'),
                              selected: _tag == null,
                              onTap: () => setState(() => _tag = null),
                            ),
                            for (final t in repo.usedTags)
                              _TagFilter(
                                label: context.tr('tag_$t'),
                                icon: tagIcon(t),
                                selected: _tag == t,
                                onTap: () =>
                                    setState(() => _tag = _tag == t ? null : t),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (!isPremium && repo.count > 0) ...[
                      const SizedBox(height: 14),
                      _FreeNotice(
                        days:
                            repo.daysUntilOldestExpires() ??
                            AppConfig.freeHistoryDays,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Expanded(
                      child: groups.isEmpty
                          ? Center(
                              child: Text(
                                repo.count == 0
                                    ? context.tr('noHistory')
                                    : context.tr('noMatch'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: p.muted,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                for (final g in groups) ...[
                                  SectionLabel(g.title),
                                  const SizedBox(height: 8),
                                  for (final item in g.items) ...[
                                    _HistoryRow(item: item),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 8),
                                ],
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

  List<_Group> _group(BuildContext context, List<HistoryItem> items) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <_Group>[];
    for (final item in items) {
      final d = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      final diff = today.difference(d).inDays;
      final title = diff == 0
          ? context.tr('today')
          : diff == 1
          ? context.tr('yesterday')
          : DateFormat('EEE, d MMM y', locale).format(d);
      if (result.isEmpty || result.last.title != title) {
        result.add(_Group(title));
      }
      result.last.items.add(item);
    }
    return result;
  }
}

/// Asks before deleting all history. Used by History and Settings.
Future<void> confirmDeleteAll(BuildContext context) async {
  final repo = context.read<HistoryRepository>();
  final p = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppPalette.danger.withValues(alpha: .12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppPalette.danger,
          size: 30,
        ),
      ),
      title: Text(
        ctx.tr('deleteAllQ'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w700,
          fontSize: 21,
        ),
      ),
      content: Text(
        ctx.tr('deleteAllBody', {'n': repo.count}),
        textAlign: TextAlign.center,
        style: TextStyle(color: p.muted, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: BigButton(
                label: ctx.tr('cancel'),
                outlined: true,
                height: 50,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigButton(
                label: ctx.tr('deleteAllBtn'),
                background: AppPalette.danger,
                foreground: const Color(0xFF2A0805),
                height: 50,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  if (ok == true) {
    await repo.deleteAll();
    if (context.mounted) showSnack(context, context.trRead('historyCleared'));
  }
}

class _Group {
  _Group(this.title);
  final String title;
  final List<HistoryItem> items = [];
}

class _FreeNotice extends StatelessWidget {
  const _FreeNotice({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    const green = AppPalette.success;
    return Panel(
      color: const Color(0xFF0F2E26),
      borderColor: const Color(0xFF245446),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('freeKeeps', {'n': AppConfig.freeHistoryDays}),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDDF5EC),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('oldestDeletes', {'n': days}),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CC9B8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: green,
              foregroundColor: const Color(0xFF06231A),
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
            child: Text(
              context.tr('keepForever'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = DateFormat.Hm().format(item.createdAt);
    return Material(
      color: p.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border.withValues(alpha: .7)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showHistoryDetail(context, item),
        onLongPress: () => context.read<HistoryRepository>().togglePin(item.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.hasName ? item.name : context.tr('untitled'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.hasName
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontStyle: item.hasName
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              color: item.hasName ? p.text : p.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                        if (item.pinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: p.accent,
                          ),
                        ],
                        if (item.tag.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(tagIcon(item.tag), size: 14, color: p.muted),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.prettyExpression,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.prettyResult,
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
      ),
    );
  }
}

/// Icon for each preset tag.
IconData tagIcon(String tag) => switch (tag) {
  'shop' => Icons.storefront_rounded,
  'home' => Icons.home_rounded,
  'rent' => Icons.key_rounded,
  'food' => Icons.restaurant_rounded,
  'work' => Icons.work_rounded,
  'travel' => Icons.flight_rounded,
  _ => Icons.label_outline_rounded,
};

class _TagFilter extends StatelessWidget {
  const _TagFilter({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(icon, size: 16, color: selected ? p.onAccent : p.muted),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? p.onAccent : p.text,
        ),
        backgroundColor: p.surface,
        selectedColor: p.accent,
        side: BorderSide(color: selected ? p.accent : p.border),
        shape: const StadiumBorder(),
      ),
    );
  }
}
