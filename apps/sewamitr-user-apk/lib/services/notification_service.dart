import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  List<AppNotification> _notifications = [];
  RealtimeChannel? _notificationChannel;
  bool _isInitialized = false;
  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔔 Initializing NotificationService local notifications...');
    
    // Request permissions for Android 13+ and iOS
    await _requestPermissions();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2196F3),
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
    debugPrint('🔔 ✅ NotificationService local notifications initialized');
  }

  Future<void> _requestPermissions() async {
    debugPrint('🔔 Requesting notification permissions...');
    
    // Request Android 13+ permissions
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('🔔 Android notification permission granted: $granted');
    }
    
    // Request iOS permissions
    final iosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 iOS notification permission granted: $granted');
    }
  }

  Future<void> loadNotifications(String userId) async {
    try {
      debugPrint('🔔 Loading notifications for user: $userId');
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      
      _notifications = (response as List)
          .map((data) => AppNotification.fromMap(data))
          .toList();
      debugPrint('🔔 Loaded ${_notifications.length} notifications, ${unreadCount} unread');
      notifyListeners();
    } catch (e) {
      debugPrint('🔔 ❌ Error loading notifications: $e');
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
            debugPrint('🔔 ✨ NEW notification received!');
            debugPrint('🔔 Payload: ${payload.newRecord}');
            final newNotification = AppNotification.fromMap(payload.newRecord);
            _notifications.insert(0, newNotification);
            debugPrint('🔔 Notification added. Total: ${_notifications.length}, Unread: $unreadCount');
            
            // Show local notification popup
            _showLocalNotification(newNotification);
            
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
            debugPrint('🔔 📝 UPDATED notification received');
            debugPrint('🔔 Payload: ${payload.newRecord}');
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
    
    debugPrint('🔔 ✅ Subscription established successfully for channel: notifications_$userId');
  }

  void unsubscribeFromNotifications() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    debugPrint('🔔 📱 Attempting to show local notification popup');
    debugPrint('🔔 Title: ${notification.title}');
    debugPrint('🔔 Message: ${notification.message}');
    debugPrint('🔔 Type: ${notification.type}');
    
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFF2196F3),
      ledColor: const Color(0xFF2196F3),
      ledOnMs: 1000,
      ledOffMs: 500,
      showWhen: true,
      when: notification.createdAt.millisecondsSinceEpoch,
      channelShowBadge: true,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        notification.message,
        contentTitle: notification.title,
        summaryText: 'SewaMitr',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view',
          'View',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final notificationId = notification.id.hashCode;
      debugPrint('🔔 Notification ID: $notificationId');
      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.message,
        details,
        payload: notification.issueId,
      );
      debugPrint('🔔 ✅ Local notification shown successfully!');
    } catch (e) {
      debugPrint('🔔 ❌ Error showing local notification: $e');
      debugPrint('🔔 ❌ Stack trace: ${StackTrace.current}');
    }
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
