import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/history_item.dart';

/// Keeps the Android home screen widget showing the last calculation.
/// (An iOS widget needs an extra Xcode target; see README.)
class WidgetService {
  WidgetService._();

  static const _android =
      'com.cybertechsystem.smart_calculator.CalcWidgetProvider';

  static Future<void> show(HistoryItem? item) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'title',
        item?.hasName == true ? item!.name : 'Calculator',
      );
      await HomeWidget.saveWidgetData<String>(
        'expr',
        item?.prettyExpression ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'result',
        item?.prettyResult ?? '0',
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _android);
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
