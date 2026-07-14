import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/base.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveAppHeaderStorage extends BaseObjectStorage<AppHeaderText?> {
  final String _boxName = 'appHeaderStorage';
  static late Box<AppHeaderText?> _box;

  @override
  Future<void> init() async {
    Hive.registerAdapter<AppHeaderText>(AppHeaderTextTypeAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<AppHeaderText?>(_boxName);
    } else {
      _box = Hive.box<AppHeaderText?>(_boxName);
    }
  }

  @override
  Future<void> clear() {
    return _box.clear();
  }

  @override
  void listen(void Function(AppHeaderText?) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<AppHeaderText?> read(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> write(String key, AppHeaderText? value) {
    return _box.put(key, value);
  }

  Future<AppHeaderText?> getCurrentHeaderText() async {
    return _box.get('current_header_text');
  }

  Future<void> setCurrentHeaderText(AppHeaderText? value) async {
    return _box.put('current_header_text', value);
  }
}
