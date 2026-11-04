import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/strings.dart';
import '../models/history_item.dart';
import '../services/calculator_controller.dart';
import '../services/history_repository.dart';
import '../widgets/common.dart';
import 'history_screen.dart' show tagIcon;
import 'share_screen.dart';

/// Bottom sheet: rename, copy, share, use again, delete.
Future<void> showHistoryDetail(BuildContext context, HistoryItem item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DetailSheet(item: item, hostContext: context),
  );
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.item, required this.hostContext});
  final HistoryItem item;
  final BuildContext hostContext;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  late final _name = TextEditingController(text: widget.item.name);
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    context.read<HistoryRepository>().rename(widget.item.id, _name.text);
    FocusScope.of(context).unfocus();
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat(
      'EEE, d MMM y · HH:mm',
      locale,
    ).format(item.createdAt);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.read<HistoryRepository>().togglePin(item.id);
                    setState(() {});
                  },
                  icon: Icon(
                    item.pinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 18,
                    color: p.accent,
                  ),
                  label: Text(
                    item.pinned ? context.tr('unpin') : context.tr('pin'),
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.prettyExpression,
              style: TextStyle(
                fontSize: 18,
                color: Color.lerp(p.text, p.muted, .3),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '= ${item.prettyResult}',
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('name'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 40,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    onChanged: (_) => setState(() => _saved = false),
                    style: TextStyle(
                      color: p.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: context.tr('untitled'),
                      hintStyle: TextStyle(color: p.muted),
                      filled: true,
                      fillColor: p.bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
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
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: BigButton(
                    label: _saved ? context.tr('saved') : context.tr('save'),
                    height: 50,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('nameHelp'),
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('tag'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in ['', ...HistoryTags.all])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: item.tag == t,
                        showCheckmark: false,
                        avatar: t.isEmpty
                            ? null
                            : Icon(
                                tagIcon(t),
                                size: 16,
                                color: item.tag == t ? p.onAccent : p.muted,
                              ),
                        label: Text(
                          t.isEmpty
                              ? context.tr('tagNone')
                              : context.tr('tag_$t'),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: item.tag == t ? p.onAccent : p.text,
                        ),
                        backgroundColor: p.surface,
                        selectedColor: p.accent,
                        side: BorderSide(
                          color: item.tag == t ? p.accent : p.border,
                        ),
                        shape: const StadiumBorder(),
                        onSelected: (_) {
                          context.read<HistoryRepository>().setTag(item.id, t);
                          setState(() {});
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Action(
                  icon: Icons.copy_rounded,
                  label: context.tr('copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.line));
                    showSnack(widget.hostContext, context.trRead('copied'));
                  },
                ),
                _Action(
                  icon: Icons.share_outlined,
                  label: context.tr('share'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(widget.hostContext).push(
                      MaterialPageRoute(
                        builder: (_) => ShareScreen(preselected: [item.id]),
                      ),
                    );
                  },
                ),
                _Action(
                  icon: Icons.replay_rounded,
                  label: context.tr('useAgain'),
                  onTap: () {
                    context.read<CalculatorController>().load(item);
                    Navigator.of(widget.hostContext).popUntil((r) => r.isFirst);
                  },
                ),
                _Action(
                  icon: Icons.delete_outline_rounded,
                  label: context.tr('delete'),
                  danger: true,
                  onTap: () {
                    final repo = context.read<HistoryRepository>();
                    repo.delete(item.id);
                    Navigator.pop(context);
                    showSnack(
                      widget.hostContext,
                      widget.hostContext.trRead('deleted'),
                      action: SnackBarAction(
                        label: widget.hostContext.trRead('undo'),
                        onPressed: () => repo.restore(item),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = danger ? const Color(0xFFFF8A80) : p.text;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: danger ? const Color(0xFF2A1416) : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: danger ? const Color(0xFF5A2A2E) : p.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              height: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
