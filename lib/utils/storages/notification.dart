import 'package:vector_academy/models/models.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationStorage {
  static const String key = 'notifications';

  static Box<List<dynamic>>? _box;

  static Future<void> init() async {
    Hive.registerAdapter<Notification>(NotificationTypeAdapter());
    if (!Hive.isBoxOpen(key)) {
      _box = await Hive.openBox<List<dynamic>>(key);
    } else {
      _box = Hive.box<List<dynamic>>(key);
    }
  }

  Future<List<Notification>> getNotifications() async {
    final notifications = _box?.get(key) ?? [];
    return notifications.cast<Notification>();
  }

  Future<void> setAsRead(int id) async {
    final notifications = _box?.get(key) ?? [];
    notifications.firstWhere((element) => element.id == id).isRead = true;
    _box?.put(key, notifications);
  }

  Future<void> setNotifications(List<Notification> notifications) async {
    _box?.put(key, notifications);
  }
}
