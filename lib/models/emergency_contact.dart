class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.relation,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String relation;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'relation': relation,
      };

  @override
  String toString() => 'EmergencyContact(id: $id, name: $name, phone: $phoneNumber, relation: $relation)';
}
