import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/emergency_event.dart';
import '../models/medication_schedule.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _medDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'med_channel',
      'Medication Reminders',
      channelDescription: 'Daily medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Color(0xFF00B0FF),
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    ),
  );

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      print('[NS] Timezone: ${tzInfo.identifier}'); // ignore: avoid_print
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        print('[NS] Timezone fallback → Asia/Kolkata'); // ignore: avoid_print
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'emergency_channel', 'Emergency Alerts',
        description: 'Critical health alerts',
        importance: Importance.max, playSound: true, enableVibration: true,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'med_channel', 'Medication Reminders',
        description: 'Daily medication reminders',
        importance: Importance.max, playSound: true, enableVibration: true,
      ));
    }

    _initialized = true;
    print('[NS] Initialized.'); // ignore: avoid_print
  }

  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final p = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (p == null) return true;
    try {
      return await p.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true; // assume granted on error
    }
  }

  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      const ch = MethodChannel('com.healthband.notifications/settings');
      await ch.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      print('[NS] openExactAlarmSettings: $e'); // ignore: avoid_print
    }
  }

  // ── Instant test ──────────────────────────────────────────────────────────
  static Future<void> showTestNotification() async {
    if (!_initialized) await init();
    await _plugin.show(999, '🔔 Test Notification',
        'Notifications are working! Channel: med_channel', _medDetails);
  }

  // ── Emergency ─────────────────────────────────────────────────────────────
  static Future<void> showEmergencyAlert(EmergencyEvent event) async {
    if (!_initialized) await init();
    await _plugin.show(
      event.timestamp.millisecondsSinceEpoch ~/ 1000 % 100000,
      'Emergency Alert', 'Immediate attention required',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel', 'Emergency Alerts',
          channelDescription: 'Critical health alerts',
          importance: Importance.max, priority: Priority.high,
          fullScreenIntent: true, enableVibration: true, playSound: true,
          color: Color(0xFFFF1744),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }

  // ── Schedule reminder ─────────────────────────────────────────────────────
  static Future<void> scheduleMedicationReminder(MedicationSchedule medication) async {
    if (!_initialized) await init();

    if (medication.medicineName.isEmpty) return;

    print('[NS] scheduleMedicationReminder: ${medication.medicineName}'); // ignore: avoid_print

    for (final timeStr in medication.times) {
      try {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final now = tz.TZDateTime.now(tz.local);
        var scheduledTime = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute, 0,
        );

        // Always schedule at least 1 min in future to avoid immediate firing
        if (scheduledTime.isBefore(now.add(const Duration(minutes: 1)))) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Robust ID: combination of med ID/name hash and time string hash
        final idSource = medication.id.isNotEmpty ? medication.id : medication.medicineName;
        final notificationId = (idSource.hashCode ^ timeStr.hashCode).abs() % 100000;

        print('[NS] Registering "${medication.medicineName}" (ID: $notificationId) for $scheduledTime'); // ignore: avoid_print

        // Cancel previous alarm to avoid duplicates
        await _plugin.cancel(notificationId);

        // Schedule with exactAllowWhileIdle for maximum reliability in background
        await _plugin.zonedSchedule(
          notificationId,
          'Medication Reminder: ${medication.medicineName} 💊',
          'It is time to take your medication: ${medication.medicineName}.',
          scheduledTime,
          _medDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        print('[NS] ✅ SUCCESS: Alarm set for $scheduledTime'); // ignore: avoid_print
      } catch (e, st) {
        print('[NS] ❌ ERROR scheduling: $e'); // ignore: avoid_print
        
        // Show error notification so user isn't left wondering
        await _plugin.show(777, '❌ Scheduling Error', e.toString(), _medDetails);
      }
    }
  }

  static Future<void> cancelMedicationReminders(MedicationSchedule medication) async {
    for (final timeStr in medication.times) {
      final idSource = medication.id.isNotEmpty ? medication.id : medication.medicineName;
      final notificationId = (idSource.hashCode ^ timeStr.hashCode).abs() % 100000;
      await _plugin.cancel(notificationId);
    }
  }

  static Future<void> cancelAllMedicationReminders() async {
    await _plugin.cancelAll();
  }
}
