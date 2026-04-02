class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.medicineName,
    required this.amount,
    required this.unit,
    required this.form,
    required this.instructions,
    required this.times,
    required this.startDate,
    this.endDate,
    this.prescribedBy,
    required this.isActive,
  });

  final String id;
  final String medicineName;
  final num amount;
  final String unit;
  final String form;
  final String instructions;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final bool isActive;

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['_id'] as String? ?? '',
      medicineName: json['medicineName'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      unit: json['unit'] as String? ?? '',
      form: json['form'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      times: (json['times'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      startDate: _parseDate(json['startDate']),
      endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
      prescribedBy: json['prescribedBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'medicineName': medicineName,
        'amount': amount,
        'unit': unit,
        'form': form,
        'instructions': instructions,
        'times': times,
        'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (prescribedBy != null) 'prescribedBy': prescribedBy,
        'isActive': isActive,
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
