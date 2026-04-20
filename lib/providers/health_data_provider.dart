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
    required this.isLoading,
    this.errorMessage,
    this.lastUpdated,
    this.isOffline = false,
    this.isServerError = false,
  });

  /// Most recent reading (always non-null after first fetch)
  final HealthData? latest;

  /// Timestamp of when the latest reading was fetched.
  final DateTime? lastUpdated;

  /// Ring buffer of the last [_kHistoryLen] readings for sparklines
  final List<HealthData> history;

  /// true = last successful fetch came from the real API
  final bool isLive;

  /// true while the very first fetch is in-flight
  final bool isLoading;

  /// Non-null when the last fetch failed; cleared on next success
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

  // ── copyWith ──────────────────────────────────────────────────────────────

  DashboardState copyWith({
    HealthData? latest,
    List<HealthData>? history,
    bool? isLive,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
    bool? isOffline,
    bool? isServerError,
  }) {
    return DashboardState(
      latest: latest ?? this.latest,
      history: history ?? this.history,
      isLive: isLive ?? this.isLive,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOffline: clearError ? false : (isOffline ?? this.isOffline),
      isServerError: clearError ? false : (isServerError ?? this.isServerError),
    );
  }
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
          isLoading: true,
        ),
      ) {
    // Fetch immediately, then on a fixed 5-second interval.
    _fetchOnce();
    _timer = Timer.periodic(_kFetchInterval, (_) => _fetchOnce());
  }

  final ApiService _api;
  Timer? _timer;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> _fetchOnce() async {
    // Guard: don't stack concurrent requests if the previous is still
    // in-flight (slow network). Cancel the current cycle instead.
    if (_inflight) return;
    _inflight = true;

    try {
      final result = await _api.getLatestHealthData();

      if (!mounted) return; // widget tree may have been disposed

      if (result.isSuccess && result.data != null) {
        final newest = result.data!;
        _appendReading(newest, isLive: true);
      } else {
        // API returned success=false or empty list → fall back to mock
        final mock = _generateMockData();
        _appendReading(mock,
            isLive: false,
            error: result.error,
            isOffline: (result as ApiResult).isOffline,
            isServerError: (result as ApiResult).isServerError);
      }
    } catch (_) {
      // Unexpected error — generate mock so UI never freezes
      if (!mounted) return;
      final mock = _generateMockData();
      _appendReading(mock, isLive: false, error: 'Unexpected fetch error.', isServerError: true);
    } finally {
      _inflight = false;
    }
  }

  bool _inflight = false;

  void _appendReading(
    HealthData reading, {
    required bool isLive,
    String? error,
    bool isOffline = false,
    bool isServerError = false,
  }) {
    final newHistory = [...state.history, reading];
    // Keep only the last N entries to avoid unbounded memory growth
    final trimmed = newHistory.length > _kHistoryLen
        ? newHistory.sublist(newHistory.length - _kHistoryLen)
        : newHistory;

    state = state.copyWith(
      latest: reading,
      history: trimmed,
      isLive: isLive,
      isLoading: false,
      errorMessage: error,
      lastUpdated: DateTime.now(),
      clearError: error == null,
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
