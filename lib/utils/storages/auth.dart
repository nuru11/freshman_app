import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/base.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveAuthStorage extends BaseObjectStorage<AuthToken> {
  final String _boxName = 'authTokenStorage';
  static late Box<AuthToken> _box;

  @override
  Future<void> init() async {
    Hive.registerAdapter<Grade>(GradeTypeAdapter());
    Hive.registerAdapter<AuthToken>(AuthTokenTypeAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<AuthToken>(_boxName);
    } else {
      _box = Hive.box<AuthToken>(_boxName);
    }
  }

  @override
  void listen(void Function(AuthToken) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<void> clear() {
    return _box.clear();
  }

  @override
  Future<AuthToken?> read(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> write(String key, AuthToken value) {
    return _box.put(key, value);
  }

  Future<AuthToken?> getAuthToken() async {
    return _box.get('authToken');
  }

  Future<void> setAuthToken(AuthToken authToken) {
    return _box.put('authToken', authToken);
  }
}

class HiveUserStorage extends BaseObjectStorage<User?> {
  final String _boxName = 'userStorage';
  static late Box<User?> _box;
  @override
  Future<void> init() async {
    Hive.registerAdapter<User>(UserTypeAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<User?>(_boxName);
    } else {
      _box = Hive.box<User?>(_boxName);
    }
  }

  @override
  Future<void> clear() {
    return _box.clear();
  }

  @override
  void listen(void Function(User? p1) callback, String key) {
    _box.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<User?> read(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> write(String key, User? value) {
    return _box.put(key, value);
  }

  Future<User?> getUser() async {
    return _box.get('user');
  }

  Future<void> setUser(User user) {
    return _box.put('user', user);
  }
}
