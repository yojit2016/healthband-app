import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import 'api_service.dart';
import 'notification_service.dart';
import '../storage/index.dart';
import '../models/index.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(EmergencyTaskHandler());
}

class EmergencyTaskHandler extends TaskHandler {
  final ApiService _api = ApiService();
  String? _lastKnownEventId;
  bool _isFetching = false;
  int _medRefreshCounter = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize Hive and notifications inside the background isolate
    await HiveService.init();
    await NotificationService.init();
    _lastKnownEventId = HiveService.getLastEventId();

    // ON START: Re-schedule all medications from local cache
    // This ensures that even if the app was killed, starting the service
    // restores all medication alarms.
    await _rescheduleFromCache();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      // 1. EMERGENCY CHECK (Every 5 seconds)
      final res = await _api.getEmergencyEvents();
      if (res.isSuccess && res.data!.isNotEmpty) {
        final newest = res.data!.reduce((a, b) => 
            a.timestamp.isAfter(b.timestamp) ? a : b);

        if (_lastKnownEventId != null && newest.eventId != _lastKnownEventId) {
          await HiveService.saveLastEventId(newest.eventId);
          await HiveService.saveAlert(newest);
          await HiveService.saveEmergencyActive(true);
          
          if (HiveService.getAudioEnabled()) {
             FlutterRingtonePlayer().play(
               android: AndroidSounds.alarm,
               ios: IosSounds.alarm,
               looping: true,
               volume: 1.0,
               asAlarm: true,
             );
          }
          await NotificationService.showEmergencyAlert(newest);
        }
        _lastKnownEventId = newest.eventId;
      }

      // 2. MEDICATION REFRESH (Every 15 minutes)
      // 5s interval * 180 repeats = 900s = 15 minutes
      _medRefreshCounter++;
      if (_medRefreshCounter >= 180) {
        _medRefreshCounter = 0;
        final medRes = await _api.getMedications();
        if (medRes.isSuccess) {
          await HiveService.saveMedications(medRes.data!);
          for (final med in medRes.data!) {
            if (med.isActive) {
              await NotificationService.scheduleMedicationReminder(med);
            }
          }
        } else {
          // If network refresh fails, re-schedule from local cache anyway
          await _rescheduleFromCache();
        }
      }

    } catch (_) {
      // Safely ignore networking errors in background
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _rescheduleFromCache() async {
    try {
      final rawMeds = HiveService.getMedications();
      if (rawMeds.isNotEmpty) {
        final meds = rawMeds.map((e) => MedicationSchedule.fromJson(e)).toList();
        for (final med in meds) {
          if (med.isActive) {
            await NotificationService.scheduleMedicationReminder(med);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class ForegroundService {
  ForegroundService._();

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'health_band_foreground',
        channelName: 'Health Monitoring Active',
        channelDescription: 'Keeps emergency detection and medication reminders active.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 5s interval
        autoRunOnBoot: true, // AUTO RUN ON BOOT IS CRITICAL
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    final notifStatus = await FlutterForegroundTask.checkNotificationPermission();
    if (notifStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final isIgnoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!isIgnoringBattery) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'Health Monitoring Active',
      notificationText: 'Monitoring vitals and medication schedules...',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
