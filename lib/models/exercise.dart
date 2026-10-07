import 'muscle_group.dart';

class Exercise {
  final String id;
  final String name;
  final String category; // 'Push', 'Pull', 'Legs', 'Core', 'Cardio'
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final String equipment;
  final String instructions;
  final double defaultWeightKg;
  final int defaultReps;
  final int defaultSets;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    this.instructions = '',
    this.defaultWeightKg = 60.0,
    this.defaultReps = 10,
    this.defaultSets = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'primary_muscles': primaryMuscles.map((m) => m.name).join(','),
      'secondary_muscles': secondaryMuscles.map((m) => m.name).join(','),
      'equipment': equipment,
      'instructions': instructions,
      'default_weight_kg': defaultWeightKg,
      'default_reps': defaultReps,
      'default_sets': defaultSets,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      primaryMuscles: (map['primary_muscles'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => MuscleGroup.values.firstWhere(
                (m) => m.name == s,
                orElse: () => MuscleGroup.chest,
              ))
          .toList(),
      secondaryMuscles: (map['secondary_muscles'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => MuscleGroup.values.firstWhere(
                (m) => m.name == s,
                orElse: () => MuscleGroup.triceps,
              ))
          .toList(),
      equipment: map['equipment'] as String? ?? 'Barbell',
      instructions: map['instructions'] as String? ?? '',
      defaultWeightKg: (map['default_weight_kg'] as num?)?.toDouble() ?? 60.0,
      defaultReps: (map['default_reps'] as num?)?.toInt() ?? 10,
      defaultSets: (map['default_sets'] as num?)?.toInt() ?? 3,
    );
  }
}
