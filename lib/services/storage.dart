import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// All data is stored only on the phone with Hive. Nothing goes to a server.
class Storage {
  Storage._();

  static const historyBox = 'history';
  static const settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(historyBox);
    await Hive.openBox(settingsBox);
  }

  static Box<Map> get history => Hive.box<Map>(historyBox);
  static Box get settings => Hive.box(settingsBox);
}
