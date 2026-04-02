import 'health_data.dart';

class HealthDataSummary {
  const HealthDataSummary({
    required this.healthData,
    required this.averagePulse,
    required this.averageOxygen,
    required this.message,
    this.statistics,
    this.deviceStatus,
  });

  final List<HealthData> healthData;
  final num averagePulse;
  final num averageOxygen;
  final String message;
  final Map<String, dynamic>? statistics;
  final Map<String, dynamic>? deviceStatus;

  factory HealthDataSummary.fromJson(Map<String, dynamic> json) {
    final rawHealthData = json['healthData'] as List<dynamic>?;
    final healthData = rawHealthData
            ?.whereType<Map<String, dynamic>>()
            .map(HealthData.fromJson)
            .toList() ??
        [];

    final averageData = json['averageData'] as Map<String, dynamic>? ?? {};

    return HealthDataSummary(
      healthData: healthData,
      averagePulse: averageData['pulse'] as num? ?? 0,
      averageOxygen: averageData['oxygen'] as num? ?? 0,
      message: json['message'] as String? ?? '',
      statistics: json['statistics'] as Map<String, dynamic>?,
      deviceStatus: json['deviceStatus'] as Map<String, dynamic>?,
    );
  }
}

class MonthlyHeatmapData {
  const MonthlyHeatmapData({
    required this.date,
    required this.avgPulse,
    required this.avgOxygen,
    required this.count,
  });

  final DateTime date;
  final num avgPulse;
  final num avgOxygen;
  final int count;

  factory MonthlyHeatmapData.fromJson(Map<String, dynamic> json) {
    return MonthlyHeatmapData(
      date: _parseDate(json['date']),
      avgPulse: json['avgPulse'] as num? ?? 0,
      avgOxygen: json['avgOxygen'] as num? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}

DateTime _parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}
