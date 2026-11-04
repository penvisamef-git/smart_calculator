import 'package:flutter/foundation.dart';

import '../core/calc_engine.dart';
import '../models/history_item.dart';
import 'history_repository.dart';
import 'widget_service.dart';

/// State of the calculator screen. Pressing "=" saves to history.
class CalculatorController extends ChangeNotifier {
  CalculatorController(this._history);

  final HistoryRepository _history;

  String _expr = '';

  /// The last item saved with "=" (used by Share on the calculator screen).
  HistoryItem? lastSaved;

  String get expression => _expr;
  String get pretty => _expr.isEmpty ? '0' : CalcEngine.pretty(_expr);
  double? get liveValue => CalcEngine.evaluate(_expr);

  void press(String key) {
    if (key == '=') {
      _equals();
      return;
    }
    _expr = CalcEngine.press(_expr, key);
    lastSaved = null;
    notifyListeners();
  }

  void _equals() {
    final v = CalcEngine.evaluate(_expr);
    if (v == null) return;
    // Do not save a plain number with no operation, e.g. just "5".
    final isJustNumber = RegExp(r'^[−]?[0-9.]+$').hasMatch(_expr);
    if (!isJustNumber) {
      lastSaved = _history.add(_expr, v);
      WidgetService.show(lastSaved);
    }
    _expr = CalcEngine.toExpression(v);
    notifyListeners();
  }

  /// Puts a whole expression on the display (voice input).
  void setExpression(String expr) {
    _expr = expr;
    lastSaved = null;
    notifyListeners();
  }

  /// Loads an old calculation back ("Use again").
  void load(HistoryItem item) {
    _expr = item.expression;
    lastSaved = null;
    notifyListeners();
  }
}
