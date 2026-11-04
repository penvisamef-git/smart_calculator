import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../core/constants.dart';
import '../models/history_item.dart';

/// Saved calculations. Newest first.
class HistoryRepository extends ChangeNotifier {
  HistoryRepository(this._box) {
    _items = _box.values.map(HistoryItem.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  final Box<Map> _box;
  late List<HistoryItem> _items;
  final _rand = Random();

  List<HistoryItem> get items => List.unmodifiable(_items);
  int get count => _items.length;

  HistoryItem? byId(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  HistoryItem add(String expression, double result) {
    final item = HistoryItem(
      id: '${DateTime.now().microsecondsSinceEpoch}${_rand.nextInt(999)}',
      expression: expression,
      result: result,
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    _box.put(item.id, item.toMap());
    notifyListeners();
    return item;
  }

  void rename(String id, String name) {
    final item = byId(id);
    if (item == null) return;
    item.name = name.trim();
    _box.put(id, item.toMap());
    notifyListeners();
  }

  void setTag(String id, String tag) {
    final item = byId(id);
    if (item == null) return;
    item.tag = tag;
    _box.put(id, item.toMap());
    notifyListeners();
  }

  void togglePin(String id) {
    final item = byId(id);
    if (item == null) return;
    item.pinned = !item.pinned;
    _box.put(id, item.toMap());
    notifyListeners();
  }

  /// Tags that are used by at least one item, in preset order.
  List<String> get usedTags => [
    for (final t in HistoryTags.all)
      if (_items.any((i) => i.tag == t)) t,
  ];

  void delete(String id) {
    _items.removeWhere((i) => i.id == id);
    _box.delete(id);
    notifyListeners();
  }

  /// Puts a deleted item back (for "Undo").
  void restore(HistoryItem item) {
    _items
      ..add(item)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _box.put(item.id, item.toMap());
    notifyListeners();
  }

  Future<void> deleteAll() async {
    _items.clear();
    await _box.clear();
    notifyListeners();
  }

  /// Free plan: remove items older than 30 days. Called at start-up.
  /// Pinned items are kept.
  void purgeExpired({required bool isPremium, DateTime? now}) {
    if (isPremium) return;
    final cutoff = (now ?? DateTime.now()).subtract(
      const Duration(days: AppConfig.freeHistoryDays),
    );
    final old = _items
        .where((i) => !i.pinned && i.createdAt.isBefore(cutoff))
        .toList();
    if (old.isEmpty) return;
    for (final i in old) {
      _box.delete(i.id);
    }
    _items.removeWhere(old.contains);
    notifyListeners();
  }

  /// Days until the oldest item is removed on the free plan (null if empty).
  int? daysUntilOldestExpires({DateTime? now}) {
    final unpinned = _items.where((i) => !i.pinned);
    if (unpinned.isEmpty) return null;
    final oldest = unpinned.last.createdAt;
    final expires = oldest.add(const Duration(days: AppConfig.freeHistoryDays));
    final d = expires.difference(now ?? DateTime.now()).inHours / 24;
    return max(0, d.ceil());
  }

  /// Search by name or number, optionally only one tag.
  List<HistoryItem> search(String query, {String? tag}) {
    final q = query.trim().toLowerCase();
    final digits = q.replaceAll(',', '');
    return _items.where((i) {
      if (tag != null && i.tag != tag) return false;
      if (q.isEmpty) return true;
      return i.name.toLowerCase().contains(q) ||
          i.expression.contains(digits) ||
          i.prettyResult.replaceAll(',', '').contains(digits);
    }).toList();
  }
}

/// Numbers for the monthly summary screen.
class MonthSummary {
  MonthSummary(this.month, List<HistoryItem> all)
    : items = all
          .where(
            (i) =>
                i.createdAt.year == month.year &&
                i.createdAt.month == month.month,
          )
          .toList();

  final DateTime month;
  final List<HistoryItem> items;

  int get count => items.length;
  int get activeDays => items.map((i) => i.createdAt.day).toSet().length;

  /// tag id ('' = no tag) → (count, sum of results), biggest count first.
  List<({String tag, int count, double total})> get byTag {
    final map = <String, ({int count, double total})>{};
    for (final i in items) {
      final cur = map[i.tag] ?? (count: 0, total: 0.0);
      map[i.tag] = (count: cur.count + 1, total: cur.total + i.result);
    }
    final list = [
      for (final e in map.entries)
        (tag: e.key, count: e.value.count, total: e.value.total),
    ];
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  String? get topTag {
    for (final t in byTag) {
      if (t.tag.isNotEmpty) return t.tag;
    }
    return null;
  }

  /// Calculations per day of the month (index 0 = day 1).
  List<int> get perDay {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final out = List.filled(days, 0);
    for (final i in items) {
      out[i.createdAt.day - 1]++;
    }
    return out;
  }
}
