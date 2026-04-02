import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_event.dart';
import '../storage/index.dart';
import 'health_data_provider.dart'; // To reuse apiServiceProvider
import '../services/api_service.dart';
import '../services/notification_service.dart';

// ── Constants ────────────────────────────────────────────────────────────────
const _kPollInterval = Duration(seconds: 5);

// ── State ────────────────────────────────────────────────────────────────────
class EmergencyState {
  const EmergencyState({
    this.latestEvent,
    this.isTriggered = false,
    this.history = const [],
    this.reason,
  });

  /// The most recent emergency event received from the server.
  final EmergencyEvent? latestEvent;

  /// Human-readable reason for the current emergency.
  final String? reason;

  /// Becomes true ONLY when a brand new event is detected.
  /// Must be manually dismissed via the provider.
  final bool isTriggered;

  /// The most recent 10 emergency events loaded from persistent storage.
  final List<EmergencyEvent> history;

  EmergencyState copyWith({
    EmergencyEvent? latestEvent,
    String? reason,
    bool? isTriggered,
    List<EmergencyEvent>? history,
  }) {
    return EmergencyState(
      latestEvent: latestEvent ?? this.latestEvent,
      reason: reason ?? this.reason,
      isTriggered: isTriggered ?? this.isTriggered,
      history: history ?? this.history,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class EmergencyNotifier extends StateNotifier<EmergencyState> {
  EmergencyNotifier(this._api) : super(const EmergencyState()) {
    _initPersistence();
    _startPolling();
  }

  final ApiService _api;
  Timer? _timer;
  String? _lastKnownEventId;
  bool _isPolling = false;

  /// Load the last seen event ID from Hive so we don't trigger on reboot.
  void _initPersistence() {
    _lastKnownEventId = HiveService.getLastEventId();
    state = state.copyWith(
      history: HiveService.getAlerts(),
      isTriggered: HiveService.getEmergencyActive(),
      latestEvent: HiveService.getAlerts().isNotEmpty
          ? HiveService.getAlerts().first
          : null,
    );
  }

  /// Start the 5-second polling loop.
  void _startPolling() {
    _pollOnce(); // Fire immediately
    _timer = Timer.periodic(_kPollInterval, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_isPolling) return;
    _isPolling = true;

    // Hot-sync history from Hive (in case background isolate appended an alert)
    final isActive = HiveService.getEmergencyActive();
    final history = HiveService.getAlerts();

    state = state.copyWith(
      history: history,
      isTriggered: state.isTriggered || isActive,
      latestEvent:
          state.latestEvent ?? (history.isNotEmpty ? history.first : null),
    );

    try {
      final result = await _api.getEmergencyEvents();

      if (!mounted) return;

      if (result.isSuccess && result.data!.isNotEmpty) {
        // Assume the API might not sort perfectly, so find the newest locally
        final newestEvent = result.data!.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );

        // Check if this event is new and hasn't been triggered before
        if (newestEvent.eventId != _lastKnownEventId) {
          _triggerEmergencyAlarm(newestEvent);
        }
      }
    } catch (_) {
      // Fail silently for background polling to avoid spamming the user
    } finally {
      _isPolling = false;
    }
  }

  /// Trigger the UI state and persist the ID to avoid duplicate alerts.
  void _triggerEmergencyAlarm(EmergencyEvent event) {
    if (!mounted) return;

    // 1. Persist the ID immediately
    _lastKnownEventId = event.eventId;
    HiveService.saveLastEventId(event.eventId);
    HiveService.saveAlert(event);
    HiveService.saveEmergencyActive(true);

    // Ensure Notification is exclusively triggered from Service/Provider natively (UI relies on State)
    NotificationService.showEmergencyAlert(event);

    debugPrint('[EmergencyProvider] State changed -> isTriggered set to TRUE!');

    // 2. Update state to trigger UI
    state = state.copyWith(
      latestEvent: event,
      reason: event.summary,
      isTriggered: true,
      history: HiveService.getAlerts(),
    );
  }

  /// Called by the UI (e.g. a dialog button) to clear the trigger state.
  void dismissAlarm() {
    HiveService.saveEmergencyActive(false);
    state = state.copyWith(isTriggered: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>((ref) {
      return EmergencyNotifier(ref.watch(apiServiceProvider));
    });
