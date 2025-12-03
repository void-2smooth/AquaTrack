import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for managing local notifications
/// 
/// Handles scheduling and canceling water reminder notifications.
/// Uses flutter_local_notifications package.
/// Note: Notifications are not supported on web platform.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static const int _reminderNotificationId = 1;
  static const String _channelId = 'aquatrack_reminders';
  static const String _channelName = 'Water Reminders';
  static const String _channelDescription = 'Notifications to remind you to drink water';

  /// Initialize the notification service
  /// 
  /// Call this in main.dart before using notifications.
  /// Does nothing on web platform.
  Future<void> init() async {
    if (kIsWeb) return; // Notifications not supported on web
    
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize with platform-specific settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to home screen or handle deep linking
    // This callback is triggered when user taps on the notification
  }

  /// Request notification permissions
  /// 
  /// Returns true if permissions were granted.
  /// Returns false on web (not supported).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    // Request iOS permissions
    final iOS = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Request Android permissions (Android 13+)
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // Assume granted for older Android versions
  }

  /// Schedule periodic water reminders
  /// 
  /// [intervalMinutes] - Time between reminders in minutes
  /// [startHour] - Hour to start sending reminders (0-23)
  /// [endHour] - Hour to stop sending reminders (0-23)
  /// 
  /// TODO: Implement more sophisticated scheduling:
  /// - Only send during waking hours
  /// - Skip if goal already reached
  /// - Adjust frequency based on remaining intake needed
  Future<void> scheduleReminders({
    required int intervalMinutes,
    int startHour = 8,
    int endHour = 22,
  }) async {
    if (kIsWeb) return; // Not supported on web
    
    // Cancel existing reminders first
    await cancelAllReminders();

    // Schedule repeating notification
    await _notifications.periodicallyShow(
      _reminderNotificationId,
      '💧 Time to Hydrate!',
      'Don\'t forget to drink water and stay healthy!',
      RepeatInterval.hourly, // Note: Custom intervals require zonedSchedule
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule a single reminder at a specific time
  Future<void> scheduleReminderAt(DateTime scheduledTime) async {
    await _notifications.zonedSchedule(
      _reminderNotificationId,
      '💧 Time to Hydrate!',
      'Don\'t forget to drink water and stay healthy!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Get notification details
  NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // TODO: Add custom notification sound
        // sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await _notifications.show(
      0,
      '💧 AquaTrack',
      'Notifications are working! Stay hydrated!',
      _notificationDetails,
    );
  }

  /// Check if notifications are enabled
  /// 
  /// Returns false on web (not supported).
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    // For now, return true. Implement actual check based on platform.
    return true;
  }
}

