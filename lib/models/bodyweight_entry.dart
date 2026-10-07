class BodyweightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final String notes;

  BodyweightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'notes': notes,
    };
  }

  factory BodyweightEntry.fromMap(Map<String, dynamic> map) {
    return BodyweightEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      notes: map['notes'] as String? ?? '',
    );
  }
}
