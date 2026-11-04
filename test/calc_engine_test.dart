import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/calc_engine.dart';

void main() {
  double? ev(String s) => CalcEngine.evaluate(s);

  group('evaluate', () {
    test('order of operations', () {
      expect(ev('12500+8000×3'), 36500);
      expect(ev('(18+22.5+15)÷4'), 13.875);
      expect(ev('2×(3+4)'), 14);
      expect(ev('10−2−3'), 5);
      expect(ev('−5+2'), -3);
    });
    test('smart percent', () {
      expect(ev('85−20%'), closeTo(68, 1e-9));
      expect(ev('200+10%'), closeTo(220, 1e-9));
      expect(ev('85−85×20%'), closeTo(68, 1e-9));
      expect(ev('200×10%'), closeTo(20, 1e-9));
      expect(ev('50%'), closeTo(.5, 1e-9));
    });
    test('live result while typing', () {
      expect(ev('12+'), 12);
      expect(ev('(2+3'), 5);
      expect(ev(''), isNull);
    });
    test('invalid / divide by zero', () {
      expect(ev('5÷0'), isNull);
      expect(ev('1..2'), isNull);
    });
  });

  group('format', () {
    test('numbers', () {
      expect(CalcEngine.formatNumber(1845000), '1,845,000');
      expect(CalcEngine.formatNumber(13.875), '13.875');
      expect(CalcEngine.formatNumber(0.1 + 0.2), '0.3');
      expect(CalcEngine.formatNumber(-1234.5), '-1,234.5');
    });
    test('pretty expression', () {
      expect(CalcEngine.pretty('12500+8000×3'), '12,500 + 8,000 × 3');
      expect(CalcEngine.pretty('(18+22.5)÷4'), '(18 + 22.5) ÷ 4');
    });
  });

  group('press', () {
    String typed(List<String> keys) => keys.fold('', CalcEngine.press);
    test('replaces operator', () => expect(typed(['5', '+', '×']), '5×'));
    test('one decimal point per number', () => expect(typed(['1', '.', '.', '5']), '1.5'));
    test('leading dot gets zero', () => expect(typed(['.', '5']), '0.5'));
    test('no leading zeros', () => expect(typed(['0', '0', '7']), '7'));
    test('smart brackets', () => expect(typed(['2', '( )', '3', '+', '1', '( )']), '2×(3+1)'));
    test('back and AC', () {
      expect(typed(['1', '2', 'back']), '1');
      expect(typed(['1', '2', 'AC']), '');
    });
  });
}
