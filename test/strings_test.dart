import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/strings.dart';

void main() {
  test('every text exists in all 8 languages, with the same {placeholders}', () {
    final en = S.table['en']!;
    expect(S.supported.length, 8);
    for (final lang in S.supported) {
      final t = S.table[lang]!;
      expect(t.keys.toSet().difference(en.keys.toSet()), isEmpty, reason: lang);
      expect(en.keys.toSet().difference(t.keys.toSet()), isEmpty, reason: lang);
      for (final k in en.keys) {
        final want = RegExp(r'\{\w+\}').allMatches(en[k]!).map((m) => m[0]).toSet();
        final got = RegExp(r'\{\w+\}').allMatches(t[k]!).map((m) => m[0]).toSet();
        expect(got, want, reason: '$lang.$k');
      }
      expect(S.nativeNames[lang], isNotNull);
    }
  });

  test('placeholders are filled', () {
    expect(S.of('en', 'sharesLeft', {'n': 2, 'max': 3}), '2 of 3 free shares left today');
  });
}
