import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  RealtimeChannel? _notificationChannel;
  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      
      _notifications = (response as List)
          .map((data) => AppNotification.fromMap(data))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> subscribeToNotifications(String userId) async {
    debugPrint('🔔 Subscribing to notifications for user: $userId');
    
    // Unsubscribe from previous channel if exists
    if (_notificationChannel != null) {
      await _notificationChannel!.unsubscribe();
      debugPrint('🔔 Unsubscribed from previous channel');
    }
    
    // Subscribe to real-time notifications
    _notificationChannel = _supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔔 NEW notification received: ${payload.newRecord}');
            final newNotification = AppNotification.fromMap(payload.newRecord);
            _notifications.insert(0, newNotification);
            debugPrint('🔔 Notification added. Total: ${_notifications.length}, Unread: $unreadCount');
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔔 UPDATED notification received: ${payload.newRecord}');
            final updatedNotification = AppNotification.fromMap(payload.newRecord);
            final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
            if (index != -1) {
              _notifications[index] = updatedNotification;
              debugPrint('🔔 Notification updated. Unread: $unreadCount');
              notifyListeners();
            }
          },
        )
        .subscribe();
    
    debugPrint('🔔 Subscription established successfully');
  }

  void unsubscribeFromNotifications() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  @override
  void dispose() {
    unsubscribeFromNotifications();
    super.dispose();
  }

  Future<void> createProgressNotification(String userId, String issueId, int progress) async {
    String title = '';
    String message = '';
    
    if (progress == 25) {
      title = 'Issue Acknowledged';
      message = 'Your reported issue has been acknowledged by authorities';
    } else if (progress == 50) {
      title = 'Work in Progress';
      message = 'Work has started on your reported issue';
    } else if (progress == 75) {
      title = 'Almost Done';
      message = 'Your reported issue is almost resolved';
    } else if (progress == 100) {
      title = 'Issue Resolved';
      message = 'Your reported issue has been marked as resolved';
    }
    
    if (title.isNotEmpty) {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'issue_id': issueId,
        'title': title,
        'message': message,
        'type': 'progress',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await loadNotifications(userId);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
    
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> clearAll(String userId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId);
    
    _notifications = [];
    notifyListeners();
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String? issueId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.issueId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'].toString(),
      userId: map['user_id'],
      issueId: map['issue_id']?.toString(),
      title: map['title'],
      message: map['message'],
      type: map['type'] ?? 'info',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      issueId: issueId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
