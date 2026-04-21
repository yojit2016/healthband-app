import 'package:dio/dio.dart';

import '../models/index.dart';

// ── Result wrapper ────────────────────────────────────────────────────────────

/// Wraps an API response: either [data] on success or [error] on failure.
class ApiResult<T> {
  const ApiResult._({
    this.data,
    this.error,
    this.isOffline = false,
    this.isServerError = false,
  });

  const ApiResult.success(T data) : this._(data: data);
  const ApiResult.failure(
    String error, {
    bool isOffline = false,
    bool isServerError = false,
  }) : this._(
          error: error,
          isOffline: isOffline,
          isServerError: isServerError,
        );

  final T? data;
  final String? error;
  final bool isOffline;
  final bool isServerError;

  bool get isSuccess => data != null;
  bool get isError => error != null;

  @override
  String toString() => isSuccess
      ? 'ApiResult.success($data)'
      : 'ApiResult.failure($error, offline: $isOffline, serverErr: $isServerError)';
}

// ── API Service ───────────────────────────────────────────────────────────────

class ApiService {
  ApiService() : _dio = _buildDio();

  final Dio _dio;
  static const String _baseUrl = 'https://health-band-server.vercel.app/api/v1';

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

  // ── Health Data ─────────────────────────────────────────────────────────────

  Future<ApiResult<HealthData>> getLatestHealthData() async {
    return _requestWithRetry<HealthData>(
      method: 'GET',
      path: '/health-data',
      // The endpoint returns { success: true, data: [ ...array of readings... ] }
      // We want the most recent reading, which is the first element.
      parser: (data) {
        if (data is List && data.isNotEmpty) {
          return HealthData.fromJson(data.first as Map<String, dynamic>);
        }
        if (data is Map<String, dynamic>) {
          return HealthData.fromJson(data);
        }
        throw FormatException('Unexpected health-data shape: ${data.runtimeType}');
      },
    );
  }

  Future<ApiResult<HealthDataSummary>> getHealthDataSummary() async {
    return _requestWithRetry<HealthDataSummary>(
      method: 'GET',
      path: '/health-data/summary',
      parser: (data) => HealthDataSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<MonthlyHeatmapData>>> getHealthDataHeatmap({int? month, int? year}) async {
    return _requestWithRetry<List<MonthlyHeatmapData>>(
      method: 'GET',
      path: '/health-data/heatmap/monthly',
      queryParameters: {
        'month': month,
        'year': year,
      }..removeWhere((k, v) => v == null),
      parser: (data) => (data as Map<String, dynamic>)['heatmap'] != null
          ? ((data)['heatmap'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(MonthlyHeatmapData.fromJson)
              .toList()
          : [],
      extractFromDataRaw: true,
    );
  }

  // ── Emergency Events ────────────────────────────────────────────────────────

  Future<ApiResult<List<EmergencyEvent>>> getEmergencyEvents({
    String? type,
    String? from,
    String? to,
  }) async {
    return _requestWithRetry<List<EmergencyEvent>>(
      method: 'GET',
      path: '/emergency-events',
      queryParameters: {
        'emergencyType': type,
        'from': from,
        'to': to,
      }..removeWhere((k, v) => v == null),
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(EmergencyEvent.fromJson)
          .toList(),
    );
  }

  // ── Emergency Contacts ──────────────────────────────────────────────────────

  Future<ApiResult<List<EmergencyContact>>> getEmergencyContacts() async {
    return _requestWithRetry<List<EmergencyContact>>(
      method: 'GET',
      path: '/emergency-contacts',
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .toList(),
    );
  }

  Future<ApiResult<EmergencyContact>> createEmergencyContact(Map<String, dynamic> body) async {
    return _requestWithRetry<EmergencyContact>(
      method: 'POST',
      path: '/emergency-contacts',
      data: body,
      parser: (data) => EmergencyContact.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<EmergencyContact>> updateEmergencyContact(String id, Map<String, dynamic> body) async {
    return _requestWithRetry<EmergencyContact>(
      method: 'PATCH',
      path: '/emergency-contacts/$id',
      data: body,
      parser: (data) => EmergencyContact.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<bool>> deleteEmergencyContact(String id) async {
    return _requestWithRetry<bool>(
      method: 'DELETE',
      path: '/emergency-contacts/$id',
      parser: (_) => true,
    );
  }

  // ── Medications ─────────────────────────────────────────────────────────────

  Future<ApiResult<List<MedicationSchedule>>> getMedications() async {
    return _requestWithRetry<List<MedicationSchedule>>(
      method: 'GET',
      path: '/medications',
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(MedicationSchedule.fromJson)
          .toList(),
    );
  }

  Future<ApiResult<MedicationSchedule>> createMedication(Map<String, dynamic> body) async {
    return _requestWithRetry<MedicationSchedule>(
      method: 'POST',
      path: '/medications',
      data: body,
      parser: (data) => MedicationSchedule.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<MedicationSchedule>> updateMedication(String id, Map<String, dynamic> body) async {
    return _requestWithRetry<MedicationSchedule>(
      method: 'PATCH',
      path: '/medications/$id',
      data: body,
      parser: (data) => MedicationSchedule.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<bool>> deleteMedication(String id) async {
    return _requestWithRetry<bool>(
      method: 'DELETE',
      path: '/medications/$id',
      parser: (_) => true,
    );
  }

  Future<ApiResult<bool>> markMedicationTaken(String id) async {
    return _requestWithRetry<bool>(
      method: 'PATCH',
      path: '/medications/reminder/$id/taken',
      parser: (_) => true,
    );
  }

  // ── Notifications ───────────────────────────────────────────────────────────

  Future<ApiResult<List<Notification>>> getNotifications() async {
    return _requestWithRetry<List<Notification>>(
      method: 'GET',
      path: '/notifications',
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Notification.fromJson)
          .toList(),
      dataField: 'message', // notifications often use 'message' instead of 'data' based on schema
    );
  }

  Future<ApiResult<List<Notification>>> getNotificationsForEmergency(String id) async {
    return _requestWithRetry<List<Notification>>(
      method: 'GET',
      path: '/notifications/emergency/$id',
      parser: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Notification.fromJson)
          .toList(),
      dataField: 'message',
    );
  }

  // ── Core Request Helper ─────────────────────────────────────────────────────

  Future<ApiResult<T>> _requestWithRetry<T>({
    required String method,
    required String path,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    String dataField = 'data',
    bool extractFromDataRaw = false,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.request<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(method: method),
        );

        if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
          _log('API Success (200 OK) -> statusCode: ${response.statusCode}, isOffline: false, isServerError: false, isMockData: false');
        }

        final body = response.data;
        if (body == null) {
          return const ApiResult.failure('Server Error', isServerError: true);
        }

        if (body is List) {
          _log('Success: $method $path');
          return ApiResult.success(parser(body));
        } else if (body is Map<String, dynamic>) {
          final success = body['success'] as bool? ?? true;
          
          if (!success && response.statusCode != 200 && response.statusCode != 201) {
            return const ApiResult.failure('Server Error', isServerError: true);
          }

          if (extractFromDataRaw) {
              _log('Success: $method $path');
              return ApiResult.success(parser(body));
          }

          dynamic responseData = body[dataField];
          if (responseData == null) {
              _log('Success: $method $path');
              return ApiResult.success(parser(body));
          }

          _log('Success: $method $path');
          return ApiResult.success(parser(responseData));
        } else {
          _log('Success: $method $path');
          return ApiResult.success(parser(body));
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          bool isOffline = false;
          bool isServerError = false;

          if (e.toString().contains('SocketException')) {
            isOffline = true;
            isServerError = false;
          } else if (e is DioException) {
            if (e.response != null) {
              isServerError = true;
              isOffline = false;
            } else {
              isOffline = true;
              isServerError = false;
            }
          } else {
            isServerError = true;
            isOffline = false;
          }

          _log('API Failed -> statusCode: ${e is DioException ? e.response?.statusCode : null}, isOffline: $isOffline, isServerError: $isServerError, isMockData: true');

          return ApiResult.failure('Failed',
              isOffline: isOffline, isServerError: isServerError);
        }
        await Future<void>.delayed(Duration(milliseconds: 800 * attempts));
      }
    }
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[ApiService] $msg');
  }
}
