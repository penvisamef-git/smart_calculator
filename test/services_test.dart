import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:smart_calculator/models/history_item.dart';
import 'package:smart_calculator/services/history_repository.dart';
import 'package:smart_calculator/services/share_service.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('free plan deletes history older than 30 days, premium keeps it', () async {
    final box = await Hive.openBox<Map>('h');
    final now = DateTime(2026, 10, 29, 12);
    HistoryItem make(String id, int daysAgo) => HistoryItem(
        id: id, expression: '1+1', result: 2, createdAt: now.subtract(Duration(days: daysAgo)));
    for (final i in [make('a', 1), make('b', 29), make('c', 31), make('d', 60)]) {
      await box.put(i.id, i.toMap());
    }

    final premiumRepo = HistoryRepository(box)..purgeExpired(isPremium: true, now: now);
    expect(premiumRepo.count, 4);

    final repo = HistoryRepository(box)..purgeExpired(isPremium: false, now: now);
    expect(repo.items.map((i) => i.id), ['a', 'b']);
    expect(box.length, 2);
    expect(repo.daysUntilOldestExpires(now: now), 1);
  });

  test('rename, delete, undo, search', () async {
    final repo = HistoryRepository(await Hive.openBox<Map>('h2'));
    final a = repo.add('450×4100', 1845000);
    repo.add('4300×12', 51600);
    repo.rename(a.id, ' Rent Oct ');
    expect(repo.byId(a.id)!.name, 'Rent Oct');
    expect(repo.search('rent').length, 1);
    expect(repo.search('1,845').length, 1);
    repo.delete(a.id);
    expect(repo.count, 1);
    repo.restore(a);
    expect(repo.count, 2);
  });

  test('pin, tag, pinned survive 30-day cleanup, monthly summary', () async {
    final box = await Hive.openBox<Map>('h3');
    final now = DateTime(2026, 10, 29, 12);
    final old = HistoryItem(id: 'old', expression: '1+1', result: 2, createdAt: DateTime(2026, 8, 1));
    await box.put(old.id, old.toMap());
    final repo = HistoryRepository(box);
    repo.togglePin('old');
    repo.setTag('old', 'rent');
    repo.purgeExpired(isPremium: false, now: now);
    expect(repo.byId('old'), isNotNull, reason: 'pinned items are kept');
    expect(repo.usedTags, ['rent']);
    expect(repo.search('', tag: 'rent').length, 1);
    expect(repo.search('', tag: 'shop'), isEmpty);
    // Reload from disk keeps tag + pin.
    final again = HistoryRepository(box);
    expect(again.byId('old')!.pinned, isTrue);
    expect(again.byId('old')!.tag, 'rent');

    final s = MonthSummary(DateTime(2026, 8), again.items);
    expect(s.count, 1);
    expect(s.activeDays, 1);
    expect(s.topTag, 'rent');
    expect(s.byTag.first.total, 2);
    expect(s.perDay.length, 31);
    expect(s.perDay[0], 1);
  });

  test('3 free shares per day plus ad bonus, resets next day', () async {
    final box = await Hive.openBox('s');
    final svc = ShareService(box);
    expect(svc.sharesLeft(), 3);
    await box.put('shareDay', ShareService.dayKey(DateTime.now()));
    await box.put('shareUsed', 3);
    expect(svc.sharesLeft(), 0);
    expect(svc.canShare(isPremium: false), isFalse);
    expect(svc.canShare(isPremium: true), isTrue);
    svc.addBonusShare();
    expect(svc.sharesLeft(), 1);
    expect(svc.sharesLeft(now: DateTime.now().add(const Duration(days: 1))), 3);
  });

  test('share text', () {
    final item = HistoryItem(
        id: '1', expression: '12500+8000×3', result: 36500, createdAt: DateTime(2026), name: 'Market');
    final text = ShareService.buildText([item], getAppLabel: 'Get the app');
    expect(text, contains('📌 Market'));
    expect(text, contains('12,500 + 8,000 × 3 = 36,500'));
    expect(text, contains('play.google.com'));
  });
}
