class Workout {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final int durationMinutes;
  final double totalVolumeKg;
  final int totalSets;
  final int totalReps;
  final bool isCompleted;
  final String notes;
  final List<String> exerciseIds;

  Workout({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    this.durationMinutes = 0,
    this.totalVolumeKg = 0.0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.isCompleted = false,
    this.notes = '',
    this.exerciseIds = const [],
  });

  Workout copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? date,
    int? durationMinutes,
    double? totalVolumeKg,
    int? totalSets,
    int? totalReps,
    bool? isCompleted,
    String? notes,
    List<String>? exerciseIds,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_volume_kg': totalVolumeKg,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
      'exercise_ids': exerciseIds.join(','),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
      totalSets: (map['total_sets'] as num?)?.toInt() ?? 0,
      totalReps: (map['total_reps'] as num?)?.toInt() ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      notes: map['notes'] as String? ?? '',
      exerciseIds: (map['exercise_ids'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}
