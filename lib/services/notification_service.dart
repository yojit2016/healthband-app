import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/emergency_event.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initializes flutter_local_notifications and requests Android 13+ permissions.
  static Future<void> init() async {
    if (_initialized) return;

    // Initialization settings for Android/iOS
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

    await _plugin.initialize(initSettings);

    // Request Android 13+ notification permissions
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.requestNotificationsPermission();

    // Explicitly create the high-priority channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Alerts',
      description: 'High priority notifications for critical health events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Triggers a high-priority system alert notification.
  static Future<void> showEmergencyAlert(EmergencyEvent event) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'High priority notifications for critical health events',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      color: Color(0xFFFF1744), // AppColors.error
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

    await _plugin.show(
      // Ensure unique ID based on timestamp so alarms don't overwrite
      event.timestamp.millisecondsSinceEpoch ~/ 1000 % 100000,
      'Emergency Alert',             // Requested strict title
      'Immediate attention required', // Requested strict body
      details,
    );
  }
}
