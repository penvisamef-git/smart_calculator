import 'calc_engine.dart';

/// Turns spoken text into a calculator expression.
/// Speech engines usually return digits ("12500 plus 8000 times 3"), so we
/// mainly translate the operator words, in all 8 app languages.
class VoiceParser {
  VoiceParser._();

  // Longest phrases first so "divided by" wins over "by".
  static const _words = <String, String>{
    // English
    'multiplied by': Ops.mul,
    'divided by': Ops.div,
    'percent': '%',
    'per cent': '%',
    'plus': Ops.add,
    'add': Ops.add,
    'and': Ops.add,
    'minus': Ops.sub,
    'subtract': Ops.sub,
    'less': Ops.sub,
    'times': Ops.mul,
    'x': Ops.mul,
    'into': Ops.mul,
    'over': Ops.div,
    'point': '.', 'open bracket': '(', 'close bracket': ')',
    // French
    'divisé par': Ops.div,
    'multiplié par': Ops.mul,
    'pour cent': '%',
    'moins': Ops.sub,
    'fois': Ops.mul, 'virgule': '.',
    // Spanish
    'dividido entre': Ops.div,
    'dividido por': Ops.div,
    'multiplicado por': Ops.mul,
    'por ciento': '%',
    'más': Ops.add,
    'mas': Ops.add,
    'menos': Ops.sub,
    'por': Ops.mul,
    'coma': '.',
    // Vietnamese
    'phần trăm': '%',
    'cộng': Ops.add,
    'trừ': Ops.sub,
    'nhân': Ops.mul,
    'chia': Ops.div,
    'phẩy': '.',
    // Khmer
    'ភាគរយ': '%',
    'បូក': Ops.add,
    'ដក': Ops.sub,
    'គុណ': Ops.mul,
    'ចែក': Ops.div,
    'ក្បៀស': '.',
    // Chinese
    '百分之': '%', '除以': Ops.div, '乘以': Ops.mul, '加上': Ops.add, '减去': Ops.sub,
    '加': Ops.add, '减': Ops.sub, '乘': Ops.mul, '除': Ops.div, '点': '.',
    // Japanese
    'パーセント': '%', '足す': Ops.add, 'たす': Ops.add, 'プラス': Ops.add, '引く': Ops.sub,
    'ひく': Ops.sub,
    'マイナス': Ops.sub,
    '掛ける': Ops.mul,
    'かける': Ops.mul,
    '割る': Ops.div,
    'わる': Ops.div,
    // Korean
    '퍼센트': '%', '더하기': Ops.add, '빼기': Ops.sub, '곱하기': Ops.mul, '나누기': Ops.div,
    // Symbols some engines return
    '*': Ops.mul, '/': Ops.div, '-': Ops.sub, '×': Ops.mul, '÷': Ops.div,
  };

  /// Returns null when nothing usable was heard.
  static String? parse(String spoken) {
    var s = ' ${spoken.toLowerCase()} ';
    // "12,500" → "12500" and "1 000" style separators.
    s = s.replaceAllMapped(RegExp(r'(\d)[,\s](?=\d{3}\b)'), (m) => m[1]!);
    // Chinese "百分之20" means 20%.
    s = s.replaceAllMapped(RegExp(r'百分之\s*(\d+(?:\.\d+)?)'), (m) => '${m[1]}%');
    final keys = _words.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      final isLatin = RegExp(r'^[a-zà-ỹ ]+$').hasMatch(k);
      if (isLatin) {
        s = s.replaceAll(
          RegExp('(?<=[\\s\\d])${RegExp.escape(k)}(?=[\\s\\d])'),
          ' ${_words[k]} ',
        );
      } else {
        s = s.replaceAll(k, ' ${_words[k]} ');
      }
    }
    // Keep only what the calculator understands.
    final allowed = RegExp('[0-9.%()${RegExp.escape(Ops.all.join())}]');
    final out = s.split('').where(allowed.hasMatch).join();
    // Remove leading operators except minus, and doubled operators.
    var expr = out.replaceAll(
      RegExp('^[${RegExp.escape('${Ops.add}${Ops.mul}${Ops.div}')}%]+'),
      '',
    );
    expr = expr.replaceAllMapped(
      RegExp(
        '([${RegExp.escape(Ops.all.join())}])[${RegExp.escape(Ops.all.join())}]+',
      ),
      (m) => m[1]!,
    );
    if (!RegExp(r'\d').hasMatch(expr)) return null;
    return expr;
  }

  /// Speech recognition locale for each app language.
  static const localeFor = {
    'en': 'en_US',
    'km': 'km_KH',
    'zh': 'zh_CN',
    'fr': 'fr_FR',
    'ko': 'ko_KR',
    'vi': 'vi_VN',
    'ja': 'ja_JP',
    'es': 'es_ES',
  };
}
