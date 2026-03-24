/// Represents a single health reading from the band.
///
/// API field mapping (GET /health-data):
///   _id        → id
///   oxygen     → spo2       (SpO₂ %)
///   pulse      → heartRate  (BPM)
///   createdAt  → timestamp
///   type       → alertType  (null | "warning" | "critical")
///   emergencyEvent → embeddedEvent (optional nested object)
///
/// Note: The server currently tracks Heart Rate and SpO2 only.
class HealthData {
  const HealthData({
    required this.id,
    required this.heartRate,
    required this.spo2,
    required this.timestamp,
    this.alertType,
    this.embeddedEvent,
  });

  /// Mongo document ID (`_id`)
  final String id;

  /// Heart rate / pulse in BPM (`pulse`)
  final int heartRate;

  /// Blood oxygen saturation % (`oxygen`)
  final int spo2;


  /// UTC timestamp of the reading (`createdAt`)
  final DateTime timestamp;

  /// Severity level: null = normal, "warning", or "critical"
  final String? alertType;

  /// Optional embedded emergency event when alertType is non-null
  final EmbeddedEmergencyEvent? embeddedEvent;

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get isNormal   => alertType == null;
  bool get isWarning  => alertType == 'warning';
  bool get isCritical => alertType == 'critical';

  // ── Deserialization ───────────────────────────────────────────────────────

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      id:           json['_id'] as String? ?? '',
      heartRate:    (json['pulse'] as num?)?.toInt() ?? 0,
      spo2:         (json['oxygen'] as num?)?.toInt() ?? 0,
      timestamp:    _parseDate(json['createdAt']),
      alertType:    json['type'] as String?,
      embeddedEvent: json['emergencyEvent'] != null
          ? EmbeddedEmergencyEvent.fromJson(
              json['emergencyEvent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id':       id,
        'pulse':     heartRate,
        'oxygen':    spo2,
        'createdAt': timestamp.toIso8601String(),
        if (alertType != null) 'type': alertType,
        if (embeddedEvent != null)
          'emergencyEvent': embeddedEvent!.toJson(),
      };

  @override
  String toString() =>
      'HealthData(id: $id, hr: $heartRate, spo2: $spo2, '
      'ts: $timestamp, alert: $alertType)';
}

/// The emergency sub-document embedded inside a HealthData record.
class EmbeddedEmergencyEvent {
  const EmbeddedEmergencyEvent({
    required this.id,
    required this.healthDataId,
    required this.emergencyTypes,
    required this.timestamp,
  });

  final String       id;
  final String       healthDataId;

  /// e.g. ["LOW_OXYGEN", "HIGH_PULSE"]
  final List<String> emergencyTypes;
  final DateTime     timestamp;

  factory EmbeddedEmergencyEvent.fromJson(Map<String, dynamic> json) {
    final types = (json['emergencyType'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return EmbeddedEmergencyEvent(
      id:             json['_id'] as String? ?? '',
      healthDataId:   json['healthDataId'] as String? ?? '',
      emergencyTypes: types,
      timestamp:      _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id':           id,
        'healthDataId':  healthDataId,
        'emergencyType': emergencyTypes,
        'createdAt':     timestamp.toIso8601String(),
      };
}

DateTime _parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}
