import '../core/calc_engine.dart';

/// One saved calculation.
class HistoryItem {
  HistoryItem({
    required this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
    this.name = '',
    this.tag = '',
    this.pinned = false,
  });

  final String id;

  /// Raw expression as typed, e.g. `12500+8000×3`.
  final String expression;
  final double result;
  final DateTime createdAt;
  String name;

  /// One of [HistoryTags.all] ids, or '' for no tag.
  String tag;

  /// Pinned items stay at the top of History.
  bool pinned;

  bool get hasName => name.trim().isNotEmpty;
  String get prettyExpression => CalcEngine.pretty(expression);
  String get prettyResult => CalcEngine.formatNumber(result);

  /// `12,500 + 8,000 × 3 = 36,500`
  String get line => '$prettyExpression = $prettyResult';

  Map<String, dynamic> toMap() => {
    'id': id,
    'expression': expression,
    'result': result,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'name': name,
    'tag': tag,
    'pinned': pinned,
  };

  factory HistoryItem.fromMap(Map<dynamic, dynamic> m) => HistoryItem(
    id: m['id'] as String,
    expression: m['expression'] as String,
    result: (m['result'] as num).toDouble(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    name: (m['name'] as String?) ?? '',
    tag: (m['tag'] as String?) ?? '',
    pinned: (m['pinned'] as bool?) ?? false,
  );
}

/// Preset tags (folders) for history. Labels come from strings.dart (`tag_shop`, ...).
class HistoryTags {
  HistoryTags._();
  static const all = ['shop', 'home', 'rent', 'food', 'work', 'travel'];
}
