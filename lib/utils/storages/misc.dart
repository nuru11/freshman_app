import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/base.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveSubjectsStorage extends BaseObjectStorage<List<Subject>> {
  final String _boxName = 'subjectsStorage';
  static late Box<List<dynamic>> _box;

  @override
  Future<void> init() async {
    Hive.registerAdapter<Subject>(SubjectTypeAdapter());

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<List<dynamic>>(_boxName);
    } else {
      _box = Hive.box<List<dynamic>>(_boxName);
    }
  }

  @override
  Future<int?> clear() async {
    return _box.clear();
  }

  @override
  void listen(void Function(List<Subject>) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<List<Subject>> read(String key) async {
    final value = _box.get(key) ?? [];
    return value.cast<Subject>();
  }

  @override
  Future<void> write(String key, List<Subject> value) async {
    return _box.put(key, value);
  }
}

class HiveChaptersStorage extends BaseObjectStorage<List<Chapter>> {
  final String _boxName = 'chaptersStorage';

  static late Box<List<dynamic>> _box;

  @override
  Future<void> init() async {
    Hive.registerAdapter<Chapter>(ChapterTypeAdapter());

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<List<dynamic>>(_boxName);
    } else {
      _box = Hive.box<List<dynamic>>(_boxName);
    }
  }

  @override
  Future<void> clear() {
    return _box.clear();
  }

  @override
  void listen(void Function(List<Chapter> p1) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<List<Chapter>> read(String key) async {
    final value = _box.get(key) ?? [];
    return value.cast<Chapter>();
  }

  @override
  Future<void> write(String key, List<Chapter> value) {
    return _box.put(key, value);
  }

  Future<void> setChapters(int subjectId, List<Chapter> chapters) {
    return _box.put('chapters_$subjectId', chapters);
  }
}

class HiveQuizzesStorage extends BaseObjectStorage<List<Exam>> {
  final String _boxName = 'quizzesStorage';
  static late Box<List<dynamic>> _box;

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<List<dynamic>>(_boxName);
    } else {
      _box = Hive.box<List<dynamic>>(_boxName);
    }
  }

  @override
  Future<void> clear() {
    return _box.clear();
  }

  @override
  void listen(void Function(List<Exam> p1) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<List<Exam>> read(String key) async {
    final value = _box.get(key) ?? [];
    return value.cast<Exam>();
  }

  @override
  Future<void> write(String key, List<Exam> value) {
    return _box.put(key, value);
  }
}
