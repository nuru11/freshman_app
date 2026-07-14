import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/models/models.dart';
import "package:vector_academy/utils/utils.dart";

class NotificationService {
  final ApiClient apiClient = ApiClient();

  Future<List<Notification>> getNotifications() async {
    final response = await apiClient.get(
      '/app/notifications',
      authenticated: true,
    );
    logger.d(response.data);
    return (response.data as List)
        .map((e) => Notification.fromJson(e))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await apiClient.post(
      '/app/notifications/$id/mark-as-read',
      authenticated: true,
    );
  }
}
