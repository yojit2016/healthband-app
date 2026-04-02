class Notification {
  const Notification({
    required this.id,
    required this.targetUser,
    required this.message,
    required this.status,
    required this.timestamp,
    this.emergencyEventId,
  });

  final String id;
  final String targetUser;
  final String message;
  final String status;
  final DateTime timestamp;
  final String? emergencyEventId;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      targetUser: json['targetUser'] as String? ?? json['recipient'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: _parseDate(json['timestamp'] ?? json['createdAt']),
      emergencyEventId: json['emergencyEventId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'targetUser': targetUser,
        'message': message,
        'status': status,
        'createdAt': timestamp.toIso8601String(),
        if (emergencyEventId != null) 'emergencyEventId': emergencyEventId,
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
