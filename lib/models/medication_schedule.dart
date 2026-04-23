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
    this.isTaken = false,
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
  final bool isTaken;

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      medicineName: (json['medicineName'] ?? json['name'] ?? 'Medication').toString(),
      amount: json['amount'] as num? ?? 0,
      unit: json['unit'] as String? ?? '',
      form: json['form'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      times:
          (json['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startDate: _parseDate(json['startDate']),
      endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
      prescribedBy: json['prescribedBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isTaken: json['isTaken'] as bool? ?? false,
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
    'isTaken': isTaken,
  };

  MedicationSchedule copyWith({
    String? id,
    String? medicineName,
    num? amount,
    String? unit,
    String? form,
    String? instructions,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    bool? isActive,
    bool? isTaken,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      form: form ?? this.form,
      instructions: instructions ?? this.instructions,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      isActive: isActive ?? this.isActive,
      isTaken: isTaken ?? this.isTaken,
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
