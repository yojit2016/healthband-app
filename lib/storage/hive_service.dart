import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/emergency_event.dart';

/// Centralized service for local persistence using Hive.
class HiveService {
  HiveService._(); // Private constructor to prevent instantiation

  static const String _settingsBox = 'settings';
  static const String _healthBox = 'health_records';
  static const String _alertBox = 'alert_history';

  // ── Storage Keys ──
  static const String _kIsLoggedIn = 'isLoggedIn';
  static const String _kLastEventId = 'lastEmergencyId';
  static const String _kAudioEnabled = 'audioEnabled';
  static const String _kHistoryKey   = 'history';
  static const String _kEmergencyActive = 'isEmergencyActive';

  /// Initializes Hive and opens required boxes. Must be called before runApp.
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register type adapters here if needed in the future
    
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_healthBox);
    await Hive.openBox(_alertBox);
  }

  // Helper to access boxes
  static Box get _settings => Hive.box(_settingsBox);
  static Box get _alerts => Hive.box(_alertBox);

  // ── Login State ───────────────────────────────────────────────────────────

  /// Saves the user's logged-in status.
  static Future<void> saveLoginState(bool isLoggedIn) async {
    await _settings.put(_kIsLoggedIn, isLoggedIn);
  }

  /// Synchronously reads the login status. Defaults to false.
  static bool getLoginState() {
    return _settings.get(_kIsLoggedIn, defaultValue: false) as bool;
  }

  // ── Last Event ID ─────────────────────────────────────────────────────────

  /// Saves the most recently detected emergency event ID to avoid duplicate alerts.
  static Future<void> saveLastEventId(String eventId) async {
    await _settings.put(_kLastEventId, eventId);
  }

  /// Synchronously reads the last known event ID. Returns null if never saved.
  static String? getLastEventId() {
    return _settings.get(_kLastEventId) as String?;
  }

  // ── Audio Settings ────────────────────────────────────────────────────────

  /// Saves the user's preference for audio notifications.
  static Future<void> saveAudioEnabled(bool isEnabled) async {
    await _settings.put(_kAudioEnabled, isEnabled);
  }

  /// Synchronously reads the audio preference. Defaults to false.
  static bool getAudioEnabled() {
    return _settings.get(_kAudioEnabled, defaultValue: false) as bool;
  }

  // ── Emergency Active State ────────────────────────────────────────────────

  /// Saves whether there is currently an unacknowledged emergency.
  static Future<void> saveEmergencyActive(bool isActive) async {
    await _settings.put(_kEmergencyActive, isActive);
  }

  /// Synchronously reads the unacknowledged emergency state.
  static bool getEmergencyActive() {
    return _settings.get(_kEmergencyActive, defaultValue: false) as bool;
  }

  // ── Alert History ─────────────────────────────────────────────────────────

  /// Saves a new emergency event to history, keeping only the last 10 entries.
  /// Prevents appending duplicates securely.
  static Future<void> saveAlert(EmergencyEvent event) async {
    final alerts = getAlerts().toList(); // read mutable copy
    
    // Safety check: Avoid duplicate
    if (alerts.any((e) => e.eventId == event.eventId)) return;

    // Prep newest first
    alerts.insert(0, event);

    // Limit to 10 latest entries
    if (alerts.length > 10) {
      alerts.removeLast();
    }

    final rawJsonList = alerts.map((e) => jsonEncode(e.toJson())).toList();
    await _alerts.put(_kHistoryKey, rawJsonList);
  }

  /// Synchronously loads the 10 most recent emergency events.
  static List<EmergencyEvent> getAlerts() {
    final rawList = _alerts.get(_kHistoryKey) as List<dynamic>?;
    if (rawList == null) return [];

    try {
      return rawList.map((e) {
        final decoded = jsonDecode(e.toString()) as Map<String, dynamic>;
        return EmergencyEvent.fromJson(decoded);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
