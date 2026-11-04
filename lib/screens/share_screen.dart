import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../models/history_item.dart';
import '../services/history_repository.dart';
import '../services/premium_service.dart';
import '../services/share_service.dart';
import '../widgets/common.dart';
import 'premium_screen.dart';
import 'share_limit_sheet.dart';

/// Pick calculations, preview the message, then share or copy it.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, this.preselected = const []});
  final List<String> preselected;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final Set<String> _selected = {...widget.preselected};

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repo = context.watch<HistoryRepository>();
    final shares = context.watch<ShareService>();
    final isPremium = context.watch<PremiumService>().isPremium;

    // Preselected items first, then the most recent ones.
    final pre = widget.preselected
        .map(repo.byId)
        .whereType<HistoryItem>()
        .toList();
    final recent = repo.items
        .where((i) => !widget.preselected.contains(i.id))
        .take(20);
    final list = [...pre, ...recent];
    final chosen = list.where((i) => _selected.contains(i.id)).toList();
    final text = chosen.isEmpty
        ? context.tr('pickOne')
        : ShareService.buildText(chosen, getAppLabel: context.tr('getApp'));
    final left = shares.sharesLeft();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(title: context.tr('share'), close: true),
              const SizedBox(height: 16),
              _LimitBar(left: left, isPremium: isPremium),
              const SizedBox(height: 16),
              SectionLabel(context.tr('chooseToSend')),
              const SizedBox(height: 8),
              Expanded(
                flex: 5,
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('noHistory'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted, height: 1.5),
                        ),
                      )
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = list[i];
                          final sel = _selected.contains(item.id);
                          return _PickRow(
                            item: item,
                            selected: sel,
                            onTap: () => setState(
                              () => sel
                                  ? _selected.remove(item.id)
                                  : _selected.add(item.id),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 14),
              SectionLabel(context.tr('messagePreview')),
              const SizedBox(height: 8),
              Expanded(
                flex: 4,
                child: Panel(
                  color: Color.lerp(p.bg, p.surface, .4),
                  child: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BigButton(
                      label: context.tr('copyText'),
                      icon: Icons.copy_rounded,
                      outlined: true,
                      onPressed: chosen.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: text));
                              showSnack(context, context.trRead('copied'));
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: BigButton(
                      label: chosen.isEmpty
                          ? context.tr('share')
                          : context.tr('shareN', {'n': chosen.length}),
                      icon: Icons.share_outlined,
                      onPressed: chosen.isEmpty
                          ? null
                          : () => _share(text, isPremium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('copyFreeNote'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(String text, bool isPremium) async {
    final shares = context.read<ShareService>();
    if (!shares.canShare(isPremium: isPremium)) {
      final got = await showShareLimitSheet(context, text);
      if (!got || !mounted) return;
    }
    await shares.share(text, isPremium: isPremium);
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({required this.left, required this.isPremium});
  final int left;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (isPremium) {
      return Panel(
        child: Row(
          children: [
            const Icon(Icons.all_inclusive_rounded, color: AppPalette.gold),
            const SizedBox(width: 12),
            Text(
              context.tr('unlimitedSharing'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    const max = AppConfig.freeSharesPerDay;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          for (var i = 0; i < max; i++)
            Container(
              width: 22,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: i < left ? p.accent : p.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.tr('sharesLeft', {'n': left, 'max': max}),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
            icon: const Icon(
              Icons.workspace_premium_rounded,
              size: 18,
              color: AppPalette.gold,
            ),
            label: Text(
              context.tr('unlimited'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final HistoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: selected,
      child: Material(
        color: p.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? p.accent.withValues(alpha: .6)
                : p.border.withValues(alpha: .7),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? p.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: selected
                        ? null
                        : Border.all(color: p.border, width: 2),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 18, color: p.onAccent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.hasName ? item.name : context.tr('untitled'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontStyle: item.hasName
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: item.hasName ? p.text : p.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
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
