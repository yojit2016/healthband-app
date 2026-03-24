import 'package:dio/dio.dart';

import '../models/emergency_event.dart';
import '../models/health_data.dart';

// ── Result wrapper ────────────────────────────────────────────────────────────

/// Wraps an API response: either [data] on success or [error] on failure.
/// Use [isSuccess] / [isError] to branch, never throws.
class ApiResult<T> {
  const ApiResult._({this.data, this.error});

  const ApiResult.success(T data) : this._(data: data);
  const ApiResult.failure(String error) : this._(error: error);

  final T?      data;
  final String? error;

  bool get isSuccess => data != null;
  bool get isError   => error != null;

  @override
  String toString() =>
      isSuccess ? 'ApiResult.success($data)' : 'ApiResult.failure($error)';
}

// ── API Service ───────────────────────────────────────────────────────────────

class ApiService {
  ApiService() : _dio = _buildDio();

  final Dio _dio;

  static const String _baseUrl =
      'https://health-band-server.vercel.app/api/v1';

  // ── Dio factory ──────────────────────────────────────────────────────────

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Always log errors and request details securely
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => _log(obj.toString()),
      ),
    );

    return dio;
  }

  // ── GET /health-data ─────────────────────────────────────────────────────

  /// Fetches all health readings.
  /// Returns [ApiResult.success] with a typed list on success,
  /// or [ApiResult.failure] with a user-friendly message on error.
  Future<ApiResult<List<HealthData>>> getHealthData() async {
    return _getWithRetry<List<HealthData>>(
      '/health-data',
      (rawList) => rawList
          .whereType<Map<String, dynamic>>()
          .map(HealthData.fromJson)
          .toList(),
    );
  }

  // ── GET /emergency-events ─────────────────────────────────────────────────

  /// Fetches standalone emergency events.
  Future<ApiResult<List<EmergencyEvent>>> getEmergencyEvents() async {
    return _getWithRetry<List<EmergencyEvent>>(
      '/emergency-events',
      (rawList) => rawList
          .whereType<Map<String, dynamic>>()
          .map(EmergencyEvent.fromJson)
          .toList(),
    );
  }

  // ── Core Request Helper with Retry ────────────────────────────────────────

  Future<ApiResult<T>> _getWithRetry<T>(
    String path,
    T Function(List<dynamic> rawList) parser, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(path);

        final body = response.data;
        if (body == null) {
          return const ApiResult.failure('Empty response from server.');
        }

        // Validate envelope
        final success = body['success'] as bool? ?? false;
        if (!success) {
          final msg = body['message'] as String? ?? 'Server returned an error.';
          return ApiResult.failure(msg);
        }

        final rawList = body['data'] as List<dynamic>?;
        if (rawList == null) {
          return const ApiResult.failure('Malformed response: missing data.');
        }

        return ApiResult.success(parser(rawList));
      } on DioException catch (e) {
        attempts++;
        _log('DioError on $path (Attempt $attempts/$maxRetries): ${e.message}');
        if (attempts >= maxRetries) {
          return ApiResult.failure(_handleDioError(e));
        }
        await Future<void>.delayed(Duration(milliseconds: 800 * attempts));
      } catch (e, stack) {
        attempts++;
        _log('Exception on $path (Attempt $attempts/$maxRetries): $e\n$stack');
        if (attempts >= maxRetries) {
          return ApiResult.failure('Unexpected error: $e');
        }
        await Future<void>.delayed(Duration(milliseconds: 800 * attempts));
      }
    }
  }

  // ── Convenience: extract events from health-data ──────────────────────────

  /// Extracts [EmergencyEvent] objects from the embedded `emergencyEvent`
  /// field inside each [HealthData] record.
  ///
  /// Use this as a fallback when [getEmergencyEvents] fails.
  static List<EmergencyEvent> extractEventsFromHealthData(
    List<HealthData> records,
  ) {
    return records
        .where((r) => r.embeddedEvent != null)
        .map(
          (r) => EmergencyEvent(
            eventId:      r.embeddedEvent!.id,
            healthDataId: r.id,
            types:        r.embeddedEvent!.emergencyTypes,
            timestamp:    r.embeddedEvent!.timestamp,
          ),
        )
        .toList();
  }

  // ── Error handling ────────────────────────────────────────────────────────

  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your network.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return 'Server error (HTTP $code).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error: ${e.message}';
    }
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[ApiService] $msg');
  }
}
