class UserProfile {
  final String id;
  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final String gender; // 'male' or 'female'
  final String goal; // 'gain_muscle', 'lose_fat', 'maintain'
  final int dailyCalorieTarget;
  final bool isOnboarded;
  final DateTime createdAt;

  UserProfile({
    this.id = 'current_user',
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    this.gender = 'male',
    this.goal = 'gain_muscle',
    int? dailyCalorieTarget,
    this.isOnboarded = true,
    DateTime? createdAt,
  })  : dailyCalorieTarget = dailyCalorieTarget ?? calculateDefaultCalories(weightKg, heightCm, age, goal, gender: gender),
        createdAt = createdAt ?? DateTime.now();

  static int calculateDefaultCalories(double weight, double height, int age, String goal, {String gender = 'male'}) {
    // Mifflin-St Jeor Equation with moderate physical activity factor (1.45)
    // Men: +5, Women: -161
    final double genderOffset = (gender.toLowerCase() == 'female') ? -161.0 : 5.0;
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + genderOffset;
    final tdee = (bmr * 1.45).round();

    switch (goal) {
      case 'gain_muscle':
        return tdee + 350; // Lean surplus
      case 'lose_fat':
        return (tdee - 450).clamp(1200, 4000); // Sustainable deficit
      case 'maintain':
      default:
        return tdee;
    }
  }

  double get bmi => weightKg / ((heightCm / 100.0) * (heightCm / 100.0));

  String get goalLabel {
    switch (goal) {
      case 'gain_muscle':
        return 'HYPERTROPHY & MASS';
      case 'lose_fat':
        return 'FAT LOSS & DEFICIT';
      case 'maintain':
      default:
        return 'MAINTENANCE & POWER';
    }
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    String? goal,
    int? dailyCalorieTarget,
    bool? isOnboarded,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'gender': gender,
      'goal': goal,
      'daily_calorie_target': dailyCalorieTarget,
      'is_onboarded': isOnboarded ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? 'current_user',
      name: map['name'] as String? ?? 'Lifter',
      age: (map['age'] as num?)?.toInt() ?? 25,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 80.0,
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 178.0,
      gender: map['gender'] as String? ?? 'male',
      goal: map['goal'] as String? ?? 'gain_muscle',
      dailyCalorieTarget: (map['daily_calorie_target'] as num?)?.toInt() ?? 2600,
      isOnboarded: (map['is_onboarded'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}
