/// Represents a standalone emergency event.
///
/// API field mapping (GET /emergency-events):
///   _id             → eventId
///   healthDataId    → healthDataId
///   emergencyType   → types   (list of strings)
///   createdAt       → timestamp
///
/// Note: The /emergency-events endpoint was unreachable during development.
/// The same data is also embedded in HealthData.embeddedEvent, so this model
/// mirrors that shape and is used for both sources.
class EmergencyEvent {
  const EmergencyEvent({
    required this.eventId,
    required this.healthDataId,
    required this.types,
    required this.timestamp,
  });

  /// Mongo document ID (`_id`)
  final String eventId;

  /// ID of the associated health-data record
  final String healthDataId;

  /// List of emergency type strings, e.g.:
  ///   "LOW_OXYGEN", "HIGH_PULSE", "CRITICALLY_LOW_OXYGEN",
  ///   "LOW_PULSE", "CRITICALLY_LOW_PULSE", "HIGH_PULSE"
  final List<String> types;

  /// UTC timestamp when the event was created
  final DateTime timestamp;

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get hasLowOxygen       => types.any((t) => t.contains('LOW_OXYGEN'));
  bool get hasCriticalOxygen  => types.contains('CRITICALLY_LOW_OXYGEN');
  bool get hasHighPulse       => types.contains('HIGH_PULSE');
  bool get hasLowPulse        => types.any((t) => t.contains('LOW_PULSE'));

  /// Human-readable summary of all types
  String get summary => types.map(_formatType).join(', ');

  // ── Deserialization ───────────────────────────────────────────────────────

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) {
    final types = (json['emergencyType'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return EmergencyEvent(
      eventId:      json['_id'] as String? ?? '',
      healthDataId: json['healthDataId'] as String? ?? '',
      types:        types,
      timestamp:    _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id':           eventId,
        'healthDataId':  healthDataId,
        'emergencyType': types,
        'createdAt':     timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'EmergencyEvent(id: $eventId, types: $types, ts: $timestamp)';
}

// ── Helpers ───────────────────────────────────────────────────────────────

DateTime _parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}

String _formatType(String raw) {
  return raw
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
