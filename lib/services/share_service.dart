import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../models/history_item.dart';

/// Daily share limit for the free plan (3 per day + bonus shares from
/// rewarded ads). Premium users can share without limit.
///
/// The counter is stored on the phone, so it resets at local midnight.
class ShareService extends ChangeNotifier {
  ShareService(this._box);

  final Box _box;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _used(DateTime now) => _box.get('shareDay') == dayKey(now)
      ? (_box.get('shareUsed', defaultValue: 0) as int)
      : 0;

  int _bonus(DateTime now) => _box.get('shareDay') == dayKey(now)
      ? (_box.get('shareBonus', defaultValue: 0) as int)
      : 0;

  /// Free shares left today (including bonus shares from ads).
  int sharesLeft({DateTime? now}) {
    final n = now ?? DateTime.now();
    final left = AppConfig.freeSharesPerDay + _bonus(n) - _used(n);
    return left < 0 ? 0 : left;
  }

  bool canShare({required bool isPremium}) => isPremium || sharesLeft() > 0;

  void _ensureToday(DateTime now) {
    if (_box.get('shareDay') != dayKey(now)) {
      _box.put('shareDay', dayKey(now));
      _box.put('shareUsed', 0);
      _box.put('shareBonus', 0);
    }
  }

  /// Called after the user watched a rewarded ad.
  void addBonusShare() {
    final now = DateTime.now();
    _ensureToday(now);
    _box.put('shareBonus', _bonus(now) + 1);
    notifyListeners();
  }

  /// Time left until the free shares reset (local midnight).
  Duration timeUntilReset({DateTime? now}) {
    final n = now ?? DateTime.now();
    final midnight = DateTime(n.year, n.month, n.day + 1);
    return midnight.difference(n);
  }

  /// Builds the text that is sent to friends.
  static String buildText(
    List<HistoryItem> items, {
    required String getAppLabel,
  }) {
    final b = StringBuffer('🧮 ${AppConfig.appName}\n');
    for (final i in items) {
      b.write('\n');
      if (i.hasName) b.write('📌 ${i.name}\n');
      b.write('${i.line}\n');
    }
    b.write('\n$getAppLabel: ${AppConfig.storeUrl}');
    return b.toString();
  }

  /// Opens the phone's share menu. Uses one share on the free plan.
  /// Returns false if the limit is reached.
  Future<bool> share(String text, {required bool isPremium}) async {
    if (!canShare(isPremium: isPremium)) return false;
    final result = await SharePlus.instance.share(ShareParams(text: text));
    // Only count it when the user did not cancel the share menu.
    if (!isPremium && result.status != ShareResultStatus.dismissed) {
      final now = DateTime.now();
      _ensureToday(now);
      _box.put('shareUsed', _used(now) + 1);
      notifyListeners();
    }
    return true;
  }
}
