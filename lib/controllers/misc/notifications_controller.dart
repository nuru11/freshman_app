import 'package:get/get.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/notification.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/utils.dart';

class NotificationsController extends GetxController {
  List<Notification> _notifications = [];
  List<Notification> get notifications => _notifications;

  final NotificationStorage _notificationStorage = NotificationStorage();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    update();

    try {
      // Mock notifications data
      _notifications = await _notificationService.getNotifications();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      await _notificationStorage.setNotifications(_notifications);
    } catch (e) {
      logger.e(e);
      Get.snackbar('Error', 'Failed to load notifications');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      _notificationStorage.setAsRead(notificationId);
      update();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
      _notificationStorage.setAsRead(notification.id);
    }
    _unreadCount = 0;
    update();
  }

  void deleteNotification(int notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _notificationStorage.setAsRead(notificationId);
    update();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    update();
  }
}
