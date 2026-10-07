class WorkoutSet {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isCompleted;
  final double rpe; // Rate of Perceived Exertion (1 - 10)
  final DateTime? completedAt;

  WorkoutSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isCompleted = false,
    this.rpe = 8.0,
    this.completedAt,
  });

  double get volume => weightKg * reps;

  WorkoutSet copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    bool? isCompleted,
    double? rpe,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      rpe: rpe ?? this.rpe,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'is_completed': isCompleted ? 1 : 0,
      'rpe': rpe,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as String,
      workoutId: map['workout_id'] as String,
      exerciseId: map['exercise_id'] as String,
      setNumber: (map['set_number'] as num).toInt(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      reps: (map['reps'] as num).toInt(),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      rpe: (map['rpe'] as num?)?.toDouble() ?? 8.0,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );
  }
}
