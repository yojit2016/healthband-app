import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_data.dart';
import '../services/api_service.dart';

// ── Fetch interval ────────────────────────────────────────────────────────────

const _kFetchInterval = Duration(seconds: 5);

// ── Mock data generator ───────────────────────────────────────────────────────

HealthData _generateMockData() {
  final rng = math.Random();
  return HealthData(
    id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
    heartRate: 60 + rng.nextInt(41), // 60–100 BPM
    spo2: 95 + rng.nextInt(6), // 95–100 %
    timestamp: DateTime.now(),
  );
}

// ── Dashboard State ───────────────────────────────────────────────────────────

class DashboardState {
  const DashboardState({
    required this.latest,
    required this.history,
    required this.isLive,
    required this.isMockData,
    required this.isLoading,
    this.errorMessage,
    this.lastUpdated,
    this.isOffline = false,
    this.isServerError = false,
  });

  /// Most recent reading
  final HealthData? latest;

  /// Timestamp of when the latest reading was fetched.
  final DateTime? lastUpdated;

  /// Ring buffer of the last N readings for sparklines
  final List<HealthData> history;

  /// true = last successful fetch came from the real API
  final bool isLive;

  /// Explict mock data flag
  final bool isMockData;

  /// true while the very first fetch is in-flight
  final bool isLoading;

  /// Non-null when the last fetch failed
  final String? errorMessage;
  final bool isOffline;
  final bool isServerError;

  // ── Derived helpers ───────────────────────────────────────────────────────

  int get heartRate => latest?.heartRate ?? 0;
  int get spo2 => latest?.spo2 ?? 0;

  List<double> get heartRateHistory =>
      history.map((d) => d.heartRate.toDouble()).toList();
  List<double> get spo2History =>
      history.map((d) => d.spo2.toDouble()).toList();
}

// ── Notifier ─────────────────────────────────────────────────────────────────

const _kHistoryLen = 20;

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._api)
    : super(
        const DashboardState(
          latest: null,
          history: [],
          isLive: false,
          isMockData: false,
          isLoading: true,
        ),
      ) {
    // Fetch immediately, then on a fixed 5-second interval.
    _fetchOnce();
    _timer = Timer.periodic(_kFetchInterval, (_) => _fetchOnce());
  }

  final ApiService _api;
  Timer? _timer;

  void _logTemp(String message) {
    // ignore: avoid_print
    print('[DEBUG LOG] DashboardNotifier: $message');
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> _fetchOnce() async {
    if (_inflight) return;
    _inflight = true;

    try {
      final result = await _api.getLatestHealthData();

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        final newest = result.data!;
        _logTemp('API Success: Received real data. Resetting all error states.');
        _appendReading(
          newest,
          isMockData: false,
          isOffline: false,
          isServerError: false,
        );
      } else {
        _logTemp('API Failed: Falling back to mock data. Offline: ${result.isOffline}, ServerErr: ${result.isServerError}');
        final mock = _generateMockData();
        _appendReading(
          mock,
          isMockData: true,
          error: result.error,
          isOffline: result.isOffline,
          isServerError: result.isServerError,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _logTemp('API Exception ($e): Falling back to mock data.');
      final mock = _generateMockData();
      _appendReading(
        mock,
        isMockData: true,
        error: 'Unexpected fetch error.',
        isServerError: true,
        isOffline: false,
      );
    } finally {
      _inflight = false;
    }
  }

  bool _inflight = false;

  void _appendReading(
    HealthData reading, {
    required bool isMockData,
    String? error,
    bool isOffline = false,
    bool isServerError = false,
  }) {
    final newHistory = [...state.history, reading];
    final trimmed = newHistory.length > _kHistoryLen
        ? newHistory.sublist(newHistory.length - _kHistoryLen)
        : newHistory;

    _logTemp('Applying NEW State -> isMockData: $isMockData, isOffline: $isOffline, isServerError: $isServerError');

    // DO NOT use copyWith. REplace state completely per instructions.
    state = DashboardState(
      latest: reading,
      history: trimmed,
      isLive: !isMockData,
      isMockData: isMockData,
      isLoading: false,
      errorMessage: error,
      lastUpdated: DateTime.now(),
      isOffline: isOffline,
      isServerError: isServerError,
    );
  }

  /// Force an immediate re-fetch (e.g. pull-to-refresh)
  Future<void> refresh() => _fetchOnce();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Singleton ApiService — one Dio instance for the entire app lifetime.
final apiServiceProvider = Provider<ApiService>((_) => ApiService());

/// Dashboard state: polls every 5 s, falls back to mock on failure.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(ref.watch(apiServiceProvider)),
    );
