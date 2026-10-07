class DailyRoutineItem {
  final String id;
  final String dateString; // YYYY-MM-DD
  final String time; // e.g. "08:30"
  final String title;
  final String subtitle;
  final String category; // 'sleep', 'wake', 'walk', 'workout', 'sauna', 'coldShower', 'nutrition', 'habit'
  final String iconKey;
  final int colorValue;
  final bool isCompleted;
  final double? macroProteinG;
  final double? macroCarbsG;
  final double? macroFatG;
  final int? calories;

  DailyRoutineItem({
    required this.id,
    required this.dateString,
    required this.time,
    required this.title,
    this.subtitle = '',
    required this.category,
    this.iconKey = 'check',
    this.colorValue = 0xFF00E676,
    this.isCompleted = false,
    this.macroProteinG,
    this.macroCarbsG,
    this.macroFatG,
    this.calories,
  });

  DailyRoutineItem copyWith({
    String? id,
    String? dateString,
    String? time,
    String? title,
    String? subtitle,
    String? category,
    String? iconKey,
    int? colorValue,
    bool? isCompleted,
    double? macroProteinG,
    double? macroCarbsG,
    double? macroFatG,
    int? calories,
  }) {
    return DailyRoutineItem(
      id: id ?? this.id,
      dateString: dateString ?? this.dateString,
      time: time ?? this.time,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
      macroProteinG: macroProteinG ?? this.macroProteinG,
      macroCarbsG: macroCarbsG ?? this.macroCarbsG,
      macroFatG: macroFatG ?? this.macroFatG,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_string': dateString,
      'time': time,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_completed': isCompleted ? 1 : 0,
      'macro_protein_g': macroProteinG,
      'macro_carbs_g': macroCarbsG,
      'macro_fat_g': macroFatG,
      'calories': calories,
    };
  }

  factory DailyRoutineItem.fromMap(Map<String, dynamic> map) {
    return DailyRoutineItem(
      id: map['id'] as String,
      dateString: map['date_string'] as String,
      time: map['time'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      category: map['category'] as String,
      iconKey: map['icon_key'] as String? ?? 'check',
      colorValue: (map['color_value'] as num?)?.toInt() ?? 0xFF00E676,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      macroProteinG: (map['macro_protein_g'] as num?)?.toDouble(),
      macroCarbsG: (map['macro_carbs_g'] as num?)?.toDouble(),
      macroFatG: (map['macro_fat_g'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toInt(),
    );
  }
}
