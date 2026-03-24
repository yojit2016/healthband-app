
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import 'api_service.dart';
import 'notification_service.dart';
import '../storage/index.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(EmergencyTaskHandler());
}

class EmergencyTaskHandler extends TaskHandler {
  final ApiService _api = ApiService();
  String? _lastKnownEventId;
  bool _isFetching = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize Hive and notifications inside the background isolate
    await HiveService.init();
    await NotificationService.init();
    _lastKnownEventId = HiveService.getLastEventId();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final res = await _api.getEmergencyEvents();
      if (res.isSuccess && res.data!.isNotEmpty) {
        final newest = res.data!.reduce((a, b) => 
            a.timestamp.isAfter(b.timestamp) ? a : b);

        if (_lastKnownEventId != null && newest.eventId != _lastKnownEventId) {
          // ignore: avoid_print
          print('[Background] EMERGENCY EVENT DETECTED: ${newest.eventId}');
          // ignore: avoid_print
          print('[Background] Alert trigger function called for: ${newest.summary}');

          // Brand new event detected while in background!
          // 1. Secure state natively before foreground UI wakes
          await HiveService.saveLastEventId(newest.eventId);
          await HiveService.saveAlert(newest);
          await HiveService.saveEmergencyActive(true);
          
          // 2. Audio Alert defensively initialized in background isolate
          if (HiveService.getAudioEnabled()) {
             FlutterRingtonePlayer().play(
               android: AndroidSounds.alarm,
               ios: IosSounds.alarm,
               looping: true,
               volume: 1.0,
               asAlarm: true,
             );
          }

          // 3. Show the high priority local notification natively
          await NotificationService.showEmergencyAlert(newest);
        }
        _lastKnownEventId = newest.eventId;
      }
    } catch (_) {
      // Safely ignore networking errors in background to conserve battery
    } finally {
      _isFetching = false;
    }
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
        channelDescription: 'Keeps emergency detection active in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 5s interval
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    // 1. Notification Permission for Android 13+
    final notifStatus = await FlutterForegroundTask.checkNotificationPermission();
    if (notifStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // 2. Battery optimization exception
    final isIgnoringBattery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!isIgnoringBattery) {
      // ignore: avoid_print
      print('[ForegroundService] WARNING: App may be killed. Disable Battery Optimization in settings.');
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'Health Monitoring Active',
      notificationText: 'Scanning for emergency vital triggers...',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
