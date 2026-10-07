class RoutinePlan {
  final String id;
  final String title;
  final String subtitle;
  final List<String> daysOfWeek; // ['Mon', 'Wed', 'Fri']
  final List<String> exerciseIds;
  final int estimatedMinutes;
  final String reminderTime;     // '07:00'
  final bool reminderEnabled;

  RoutinePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.daysOfWeek,
    required this.exerciseIds,
    this.estimatedMinutes = 60,
    this.reminderTime = '07:00',
    this.reminderEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'days_of_week': daysOfWeek.join(','),
      'exercise_ids': exerciseIds.join(','),
      'estimated_minutes': estimatedMinutes,
      'reminder_time': reminderTime,
      'reminder_enabled': reminderEnabled ? 1 : 0,
    };
  }

  factory RoutinePlan.fromMap(Map<String, dynamic> map) {
    return RoutinePlan(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      daysOfWeek: (map['days_of_week'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      exerciseIds: (map['exercise_ids'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt() ?? 60,
      reminderTime: map['reminder_time'] as String? ?? '07:00',
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
    );
  }
}
