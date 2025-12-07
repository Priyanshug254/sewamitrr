import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔥 Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    debugPrint('🔥 Initializing FCM Service...');

    try {
      // On Web, requestPermission might hang if not triggered by user interaction
      // We'll proceed but log if it takes too long
      if (kIsWeb) {
        debugPrint('🔥 Web detected: ensure this is called or triggered appropriately.');
      }

      // Request POST_NOTIFICATIONS permission for Android 13+ (API 33+)
      if (!kIsWeb) {
        try {
          final permission = await Permission.notification.request();
          debugPrint('🔥 POST_NOTIFICATIONS permission status: $permission');
          
          if (permission.isDenied || permission.isPermanentlyDenied) {
            debugPrint('🔥 ⚠️ Notification permission denied by user');
            return;
          }
        } catch (e) {
          debugPrint('🔥 Error requesting notification permission: $e');
        }
      }

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔥 Firebase authorization status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔥 ✅ User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('🔥 ⚠️ User granted provisional permission');
      } else {
        debugPrint('🔥 ❌ User declined or has not accepted permission');
        return;
      }

      // Initialize local notifications
      // On web we might rely on service worker, but let's init anyway
      if (!kIsWeb) {
        await _initializeLocalNotifications();
        debugPrint('🔥 ✅ Local notifications initialized');
      }

      // Get FCM token
      // For web, you might need a vapidKey if not using default
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('🔥 ✅ FCM Token obtained: $_fcmToken');
      } catch (e) {
        debugPrint('🔥 ❌ Error getting FCM token: $e');
        if (kIsWeb) {
          debugPrint('🔥 Hint: For Web, you might need to generate a Web Push Certificate (VAPID Key) in Firebase Console -> Cloud Messaging.');
        }
      }

      // Save token to Supabase
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

      // Check if app was opened from a terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔥 App opened from terminated state');
        _handleMessageClick(initialMessage);
      }

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      debugPrint('🔥 ✅✅✅ FCM Service initialized successfully ✅✅✅');
    } catch (e) {
      debugPrint('🔥 ❌ Error initializing FCM Service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
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
      onDidReceiveNotificationResponse: _handleLocalNotificationClick,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('🔥 No user logged in, skipping token save');
        return;
      }

      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('🔥 FCM token saved to Supabase');
    } catch (e) {
      debugPrint('🔥 Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔥 ========================================');
    debugPrint('🔥 Foreground message received!');
    debugPrint('🔥 Title: ${message.notification?.title}');
    debugPrint('🔥 Body: ${message.notification?.body}');
    debugPrint('🔥 Data: ${message.data}');
    debugPrint('🔥 ========================================');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(message);
    } else {
      debugPrint('🔥 ⚠️ No notification payload, only data');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    debugPrint('🔥 Showing local notification...');
    
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
        payload: message.data['issue_id'],
      );
      debugPrint('🔥 ✅ Local notification shown successfully');
    } catch (e) {
      debugPrint('🔥 ❌ Error showing local notification: $e');
    }
  }

  void _handleMessageClick(RemoteMessage message) {
    debugPrint('🔥 Notification clicked: ${message.data}');
    
    // Navigate to issue detail screen
    final issueId = message.data['issue_id'];
    if (issueId != null) {
      // TODO: Navigate to issue detail screen
      debugPrint('🔥 Navigate to issue: $issueId');
    }
  }

  void _handleLocalNotificationClick(NotificationResponse response) {
    debugPrint('🔥 Local notification clicked: ${response.payload}');
    
    if (response.payload != null) {
      // TODO: Navigate to issue detail screen
      debugPrint('🔥 Navigate to issue: ${response.payload}');
    }
  }

  Future<void> clearToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('users')
            .update({'fcm_token': null})
            .eq('id', userId);
      }
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('🔥 FCM token cleared');
    } catch (e) {
      debugPrint('🔥 Error clearing FCM token: $e');
    }
  }
}
