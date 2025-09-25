import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized ?? false) {
        await _requestPermissions();
        _initialized = true;
        print('Notification service initialized successfully');
      } else {
        print('Failed to initialize notification service');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      _initialized = false;
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Handle notification tap navigation
  }

  static Future<void> showReportStatusUpdate({
    required String title,
    required String message,
    required String reportId,
  }) async {
    if (!_initialized) {
      print('Notification service not initialized');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'report_updates',
        'Report Status Updates',
        channelDescription: 'Notifications for civic report status changes',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        reportId.hashCode, // Use report ID hash as notification ID
        title,
        message,
        details,
        payload: reportId,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> showUploadProgress({
    required String title,
    required String message,
    required int progress,
    required String reportId,
  }) async {
    if (!_initialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'upload_progress',
        'Upload Progress',
        channelDescription: 'Progress notifications for file uploads',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        ongoing: progress < 100,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        'upload_${reportId}'.hashCode,
        title,
        message,
        details,
        payload: reportId,
      );
    } catch (e) {
      print('Error showing upload progress: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }
}
