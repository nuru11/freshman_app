import 'package:hive_flutter/hive_flutter.dart';

class HiveDeviceStorage {
  static const String _boxName = 'deviceStorage';
  static const String _deviceIdKey = 'device_id';

  static late Box<String> _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
  }

  Future<String?> getDeviceId() async {
    return _box.get(_deviceIdKey);
  }

  Future<void> setDeviceId(String deviceId) async {
    await _box.put(_deviceIdKey, deviceId);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
