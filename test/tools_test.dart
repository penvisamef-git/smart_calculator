import 'package:flutter_test/flutter_test.dart';
import 'package:smart_calculator/core/calc_engine.dart';
import 'package:smart_calculator/core/tools_math.dart';
import 'package:smart_calculator/core/voice_parser.dart';

void main() {
  group('tools math', () {
    test('discount', () {
      final r = ToolsMath.discount(85, 20);
      expect(r.pay, closeTo(68, 1e-9));
      expect(r.save, closeTo(17, 1e-9));
    });
    test('VAT add and remove', () {
      expect(ToolsMath.vat(100, 10, add: true).total, closeTo(110, 1e-9));
      final r = ToolsMath.vat(110, 10, add: false);
      expect(r.before, closeTo(100, 1e-9));
      expect(r.vat, closeTo(10, 1e-9));
    });
    test('tip and split', () {
      final r = ToolsMath.tipSplit(60, 10, 3);
      expect(r.total, closeTo(66, 1e-9));
      expect(r.each, closeTo(22, 1e-9));
      expect(ToolsMath.tipSplit(60, 0, 0).each, 60); // 0 people treated as 1
    });
    test('loan (5000 at 12%/year, 24 months)', () {
      final r = ToolsMath.loan(5000, 12, 24);
      expect(r.monthly, closeTo(235.37, 0.01));
      expect(ToolsMath.loan(1200, 0, 12).monthly, 100);
      expect(ToolsMath.loan(1200, 5, 0).monthly, 0);
    });
    test('margin', () {
      final r = ToolsMath.margin(8, 10);
      expect(r.profit, 2);
      expect(r.margin, closeTo(20, 1e-9));
      expect(r.markup, closeTo(25, 1e-9));
    });
    test('currency', () {
      expect(ToolsMath.usdToKhr(10, 4100), 41000);
      expect(ToolsMath.khrToUsd(41000, 4100), 10);
    });
  });

  group('voice parser', () {
    String? p(String s) => VoiceParser.parse(s);
    test('English', () {
      expect(p('12,500 plus 8000 times 3'), '12500+8000${Ops.mul}3');
      expect(p('100 divided by 4'), '100${Ops.div}4');
      expect(p('85 minus 20 percent'), '85${Ops.sub}20%');
      expect(p('7 x 6'), '7${Ops.mul}6');
    });
    test('other languages', () {
      expect(p('12 បូក 8'), '12+8');
      expect(p('12加8乘3'), '12+8${Ops.mul}3');
      expect(p('12 cộng 8'), '12+8');
      expect(p('10 más 5'), '10+5');
      expect(p('10 fois 5'), '10${Ops.mul}5');
      expect(p('12 더하기 8'), '12+8');
      expect(p('12 足す 8'), '12+8');
    });
    test('nothing usable', () {
      expect(p('hello'), isNull);
      expect(p(''), isNull);
    });
    test('parsed text evaluates', () {
      expect(CalcEngine.evaluate(p('12500 plus 8000 times 3')!), 36500);
    });
  });
}
