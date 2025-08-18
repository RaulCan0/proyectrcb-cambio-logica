import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _boxName = 'app_data';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  Future<void> saveData(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    await box.put(key, value);
  }

  dynamic getData(String key) {
    final box = Hive.box(_boxName);
    return box.get(key);
  }

  Future<void> deleteData(String key) async {
    final box = Hive.box(_boxName);
    await box.delete(key);
  }

  Future<void> clearAll() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
