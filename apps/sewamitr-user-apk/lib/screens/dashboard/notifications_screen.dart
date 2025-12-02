import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();
    if (authService.currentUser != null) {
      await notificationService.loadNotifications(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final languageService = context.watch<LanguageService>();
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('notifications')),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final authService = context.read<AuthService>();
                await notificationService.markAllAsRead(authService.currentUser!.id);
              },
              child: Text(
                languageService.translate('mark_all_read'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    languageService.translate('no_notifications'),
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification, notificationService);
              },
            ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationService service) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'progress':
        icon = Icons.trending_up;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            await service.markAsRead(notification.id);
          }
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
