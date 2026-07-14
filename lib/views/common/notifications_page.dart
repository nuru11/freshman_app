import 'package:flutter/material.dart' hide Notification;
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';

import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NotificationsController());

    return GetBuilder<NotificationsController>(
      builder: (controller) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => safePop(context: context),
          ),
          actions: [
            if (controller.notifications.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    controller.markAllAsRead();
                  } else if (value == 'clear_all') {
                    _showClearAllDialog(context, controller);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await controller.loadNotifications();
          },
          child: controller.isLoading
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : controller.notifications.isEmpty
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                )
              : _buildNotificationsList(context, controller),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when they arrive',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    NotificationsController controller,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        return _buildNotificationItem(context, notification, controller);
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Notification notification,
    NotificationsController controller,
  ) {
    final isRead = notification.isRead;
    final type = notification.type;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          color: Colors.red[600],
          child: Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) {
          controller.deleteNotification(notification.id);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
              width: 1,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 20,
                ),
              ),

              SizedBox(width: 12),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 4),

                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 8),

                    Text(
                      notification.createdAt.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Action Button
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                onPressed: () =>
                    _showNotificationActions(context, notification, controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'chapter':
        return Colors.blue[600]!;
      case 'quiz':
        return Colors.green[600]!;
      case 'achievement':
        return Colors.orange[600]!;
      case 'system':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chapter':
        return Icons.book;
      case 'quiz':
        return Icons.quiz;
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  void _showNotificationActions(
    BuildContext context,
    Notification notification,
    NotificationsController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.mark_email_read, color: Colors.blue[600]),
              title: Text('Mark as read'),
              onTap: () {
                controller.markAsRead(notification.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[600]),
              title: Text('Delete'),
              onTap: () {
                controller.deleteNotification(notification.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationsController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear All Notifications'),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllNotifications();
              Navigator.pop(dialogContext);
            },
            child: Text('Clear All', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }
}
