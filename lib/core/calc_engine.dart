import 'package:intl/intl.dart';

/// Symbols shown on the keypad and stored in expressions.
class Ops {
  static const add = '+';
  static const sub = '−';
  static const mul = '×';
  static const div = '÷';
  static const all = [add, sub, mul, div];
}

/// Pure calculator logic: parsing, evaluating and formatting.
/// No Flutter imports, so it is easy to unit test.
class CalcEngine {
  CalcEngine._();

  static final NumberFormat _intFormat = NumberFormat('#,##0', 'en_US');

  /// Evaluates an expression such as `12500+8000×3` or `85−85×20%`.
  /// Returns null when the expression is empty or invalid.
  /// Trailing operators are ignored and open brackets are closed, so this can
  /// be used for the live result while the user is still typing.
  static double? evaluate(String input) {
    var s = input
        .replaceAll(Ops.mul, '*')
        .replaceAll(Ops.div, '/')
        .replaceAll(Ops.sub, '-')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    s = s.replaceAll(RegExp(r'[+\-*/.(]+$'), '');
    if (s.isEmpty) return null;
    final open = '('.allMatches(s).length - ')'.allMatches(s).length;
    if (open < 0) return null;
    s += ')' * open;
    try {
      final parser = _Parser(s);
      final v = parser.parseExpression();
      if (!parser.isDone) return null;
      if (v.isNaN || v.isInfinite) return null;
      return v;
    } catch (_) {
      return null;
    }
  }

  /// Formats a number like `1845000` → `1,845,000` and `13.875` → `13.875`.
  static String formatNumber(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15) {
      return _intFormat.format(v);
    }
    // Round away floating point noise (0.1 + 0.2).
    var str = double.parse(v.toStringAsPrecision(12)).toString();
    if (str.contains('e')) return str;
    final parts = str.split('.');
    final intPart = _intFormat.format(int.parse(parts[0].replaceAll('-', '')));
    final sign = v < 0 ? '-' : '';
    if (parts.length == 1) return '$sign$intPart';
    final frac = parts[1].replaceAll(RegExp(r'0+$'), '');
    return frac.isEmpty ? '$sign$intPart' : '$sign$intPart.$frac';
  }

  /// Turns the raw expression into a readable one: `12500+8000×3`
  /// → `12,500 + 8,000 × 3`.
  static String pretty(String expr) {
    final withCommas = expr.replaceAllMapped(RegExp(r'\d+(\.\d*)?'), (m) {
      final raw = m.group(0)!;
      final parts = raw.split('.');
      final i = _intFormat.format(int.tryParse(parts[0]) ?? 0);
      return parts.length > 1 ? '$i.${parts[1]}' : i;
    });
    return withCommas
        .replaceAllMapped(
          RegExp('([${RegExp.escape(Ops.all.join())}])'),
          (m) => ' ${m.group(1)} ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('( ', '(')
        .trim();
  }

  /// Converts a result back to an expression the user can keep typing on.
  static String toExpression(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15) {
      return v.toInt().toString().replaceAll('-', Ops.sub);
    }
    return double.parse(v.toStringAsPrecision(12))
        .toString()
        .replaceAll('-', Ops.sub);
  }

  /// Applies a key press to an expression and returns the new expression.
  static String press(String expr, String key) {
    final last = expr.isEmpty ? '' : expr[expr.length - 1];
    switch (key) {
      case 'AC':
        return '';
      case 'back':
        return expr.isEmpty ? expr : expr.substring(0, expr.length - 1);
      case '( )':
        final open = '('.allMatches(expr).length - ')'.allMatches(expr).length;
        final afterValue = RegExp(r'[0-9)%]').hasMatch(last);
        if (open > 0 && afterValue) return '$expr)';
        return afterValue ? '$expr${Ops.mul}(' : '$expr(';
      case '%':
        if (!RegExp(r'[0-9)]').hasMatch(last)) return expr;
        return '$expr%';
      case '.':
        final m = RegExp(r'[0-9.]*$').stringMatch(expr) ?? '';
        if (m.contains('.')) return expr;
        return m.isEmpty ? '${expr}0.' : '$expr.';
    }
    if (Ops.all.contains(key)) {
      if (expr.isEmpty) return key == Ops.sub ? key : expr;
      if (last == '(' && key != Ops.sub) return expr;
      if (Ops.all.contains(last)) {
        if (expr.length == 1) return key == Ops.sub ? key : '';
        return expr.substring(0, expr.length - 1) + key;
      }
      return expr + key;
    }
    // Digit: avoid leading zeros like 007.
    final m = RegExp(r'[0-9.]*$').stringMatch(expr) ?? '';
    if (m == '0') return expr.substring(0, expr.length - 1) + key;
    if (last == ')' || last == '%') return '$expr${Ops.mul}$key';
    return expr + key;
  }
}

class _Parser {
  _Parser(this.s);
  final String s;
  int pos = 0;

  bool get isDone => pos >= s.length;
  String? get _peek => pos < s.length ? s[pos] : null;

  /// True when the last term was a single percentage like `20%`.
  bool _termWasPercent = false;
  bool _factorWasPercent = false;

  double parseExpression() {
    var v = _term();
    while (_peek == '+' || _peek == '-') {
      final op = s[pos++];
      var r = _term();
      // Smart percent: 200 + 10% = 220, 85 − 20% = 68 (like shop calculators).
      if (_termWasPercent) r = v * r;
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _factor();
    var single = true;
    while (_peek == '*' || _peek == '/') {
      single = false;
      final op = s[pos++];
      final r = _factor();
      v = op == '*' ? v * r : v / r;
    }
    _termWasPercent = single && _factorWasPercent;
    return v;
  }

  double _factor() {
    _factorWasPercent = false;
    if (_peek == '-') {
      pos++;
      return -_factor();
    }
    if (_peek == '+') {
      pos++;
      return _factor();
    }
    double v;
    if (_peek == '(') {
      pos++;
      v = parseExpression();
      if (_peek != ')') throw const FormatException('missing )');
      pos++;
    } else {
      final start = pos;
      while (pos < s.length && RegExp(r'[0-9.]').hasMatch(s[pos])) {
        pos++;
      }
      if (start == pos) throw const FormatException('number expected');
      v = double.parse(s.substring(start, pos));
    }
    var hadPercent = false;
    while (_peek == '%') {
      pos++;
      v = v / 100;
      hadPercent = true;
    }
    _factorWasPercent = hadPercent;
    return v;
  }
}
