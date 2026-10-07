class FoodEntry {
  final String id;
  final String dateString; // YYYY-MM-DD
  final String mealType;   // 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Pre-Workout', 'Post-Workout'
  final String foodName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime loggedAt;

  FoodEntry({
    required this.id,
    required this.dateString,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_string': dateString,
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as String,
      dateString: map['date_string'] as String,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      calories: (map['calories'] as num).toInt(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      loggedAt: map['logged_at'] != null
          ? DateTime.parse(map['logged_at'] as String)
          : DateTime.now(),
    );
  }
}
