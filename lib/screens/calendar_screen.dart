import 'dart:math';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'active_workout_screen.dart';
import 'routine_builder_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Set<String> _completedDateStrings = {};
  List<Workout> _selectedDayWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    DatabaseService.dataChangeNotifier.addListener(_loadCalendarData);
    _loadCalendarData();
  }

  @override
  void dispose() {
    DatabaseService.dataChangeNotifier.removeListener(_loadCalendarData);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    final completed = await DatabaseService.instance.getCompletedWorkoutDateStrings();
    final dayWorkouts = await DatabaseService.instance.getWorkoutsForDay(_selectedDate);

    setState(() {
      _completedDateStrings = completed;
      _selectedDayWorkouts = dayWorkouts;
      _isLoading = false;
    });
  }

  void _onDateTapped(DateTime date) async {
    final dayWorkouts = await DatabaseService.instance.getWorkoutsForDay(date);
    setState(() {
      _selectedDate = date;
      _selectedDayWorkouts = dayWorkouts;
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _formatMonthYear(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return "${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: KineticTheme.accentFlame))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // Month Selector & Matrix Calendar Card (References/Habit Tracker.jpg)
                    _buildCalendarMatrixCard(),
                    const SizedBox(height: 16),

                    // Day Details Inspection Card
                    _buildDayInspectionCard(),
                    const SizedBox(height: 18),

                    // Best Streaks Section (References/Habit Tracker.jpg)
                    _buildBestStreaksSection(),
                    const SizedBox(height: 18),

                    // Frequency Breakdown (References/Habit Tracker.jpg)
                    _buildFrequencySection(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONSISTENCY PROTOCOL',
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Calendar & Streaks',
          style: TextStyle(
            color: KineticTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarMatrixCard() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderMedium),
      ),
      child: Column(
        children: [
          // Month Switcher Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMonthYear(_currentMonth),
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: KineticTheme.textSecondary),
                    onPressed: _prevMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: KineticTheme.textSecondary),
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: KineticTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((firstWeekday - 1 + daysInMonth + 6) ~/ 7) * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return Container(); // Empty slot outside month
              }

              final dayNum = dayOffset + 1;
              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final dateStr = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";

              final isCompleted = _completedDateStrings.contains(dateStr);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final now = DateTime.now();
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;

              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final double anim = _pulseController.value;
                  final double pulse = 0.5 + 0.5 * sin(anim * 2 * pi);

                  return GestureDetector(
                    onTap: () => _onDateTapped(cellDate),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? KineticTheme.accentFlame
                            : (isCompleted ? KineticTheme.bgSurfaceHighlight : KineticTheme.bgSurfaceElevated),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: KineticTheme.accentFlame.withValues(alpha: 0.5 + 0.5 * pulse),
                                width: 2.0,
                              )
                            : (isCompleted && !isSelected
                                ? Border.all(
                                    color: KineticTheme.accentJade.withValues(alpha: 0.4 + 0.3 * pulse),
                                    width: 1.2,
                                  )
                                : null),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: KineticTheme.accentFlame.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : (isToday
                                ? [
                                    BoxShadow(
                                      color: KineticTheme.accentFlame.withValues(alpha: 0.25 * pulse),
                                      blurRadius: 8,
                                      spreadRadius: 1.5,
                                    ),
                                  ]
                                : null),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isCompleted ? KineticTheme.textPrimary : KineticTheme.textSecondary),
                              fontSize: 12,
                              fontWeight: isSelected || isCompleted ? FontWeight.w900 : FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (isCompleted && !isSelected)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4.5,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: KineticTheme.accentJade,
                                  boxShadow: [
                                    BoxShadow(
                                      color: KineticTheme.accentJade.withValues(alpha: 0.5 + 0.5 * pulse),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayInspectionCard() {
    final hasWorkouts = _selectedDayWorkouts.isNotEmpty;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateDisplay = "${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note_rounded, size: 16, color: KineticTheme.accentFlame),
                  const SizedBox(width: 8),
                  Text(
                    dateDisplay.toUpperCase(),
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasWorkouts ? KineticTheme.accentJade.withValues(alpha: 0.15) : KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasWorkouts ? 'LOGGED' : 'REST DAY',
                  style: TextStyle(
                    color: hasWorkouts ? KineticTheme.accentJade : KineticTheme.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasWorkouts) ...[
            ..._selectedDayWorkouts.map((w) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.title,
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${w.subtitle} · ${w.durationMinutes} min',
                            style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${w.totalVolumeKg.toInt()} kg',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: () => _showLogWorkoutSheet(_selectedDate),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: KineticTheme.borderFaint),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  '+ LOG ANOTHER WORKOUT',
                  style: TextStyle(color: KineticTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ] else ...[
            Text(
              'No training logged for this day. Scheduled recovery.',
              style: TextStyle(color: KineticTheme.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _showLogWorkoutSheet(_selectedDate),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: KineticTheme.borderMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  '+ LOG WORKOUT FOR THIS DATE',
                  style: TextStyle(color: KineticTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogWorkoutSheet(DateTime targetDate) async {
    final customRoutines = await DatabaseService.instance.getCustomRoutines();
    if (!mounted) return;

    final templates = [
      {
        'title': 'Chest + tricep',
        'subtitle': 'Push Hypertrophy',
        'exercises': ['bench_press', 'incline_db_press', 'overhead_press', 'triceps_extension'],
        'minutes': 65,
      },
      {
        'title': 'Back + bicep + legs',
        'subtitle': 'Pull Strength & Squats',
        'exercises': ['weighted_pull_up', 'barbell_row', 'incline_bicep_curl', 'barbell_squat'],
        'minutes': 65,
      },
      {
        'title': 'Lower Body Strength',
        'subtitle': 'Quads + Hamstrings + Core',
        'exercises': ['barbell_squat', 'romanian_deadlift', 'hanging_leg_raise'],
        'minutes': 70,
      },
      {
        'title': 'Upper Body Power',
        'subtitle': 'Bench + Pull-Up + OHP',
        'exercises': ['bench_press', 'weighted_pull_up', 'overhead_press'],
        'minutes': 55,
      },
      {
        'title': 'Quick Session',
        'subtitle': 'Ad-hoc workout session',
        'exercises': ['bench_press', 'weighted_pull_up'],
        'minutes': 45,
      },
    ];

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[targetDate.month - 1]} ${targetDate.day}, ${targetDate.year}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KineticTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: KineticTheme.accentFlame.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available_rounded, color: KineticTheme.accentFlame, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOG WORKOUT',
                                style: TextStyle(
                                  color: KineticTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                dateStr.toUpperCase(),
                                style: TextStyle(
                                  color: KineticTheme.accentFlame,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: KineticTheme.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (customRoutines.isNotEmpty) ...[
                            Text(
                              'CUSTOM ROUTINES',
                              style: TextStyle(
                                color: KineticTheme.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...customRoutines.map((plan) {
                              return _buildRoutineOptionTile(
                                ctx: ctx,
                                title: plan.title,
                                subtitle: plan.subtitle,
                                exercises: plan.exerciseIds,
                                minutes: plan.estimatedMinutes,
                                targetDate: targetDate,
                              );
                            }),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            'TEMPLATE ROUTINES',
                            style: TextStyle(
                              color: KineticTheme.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...templates.map((t) {
                            return _buildRoutineOptionTile(
                              ctx: ctx,
                              title: t['title'] as String,
                              subtitle: t['subtitle'] as String,
                              exercises: t['exercises'] as List<String>,
                              minutes: t['minutes'] as int,
                              targetDate: targetDate,
                            );
                          }),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
                              ).then((_) => _loadCalendarData());
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'CREATE NEW ROUTINE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KineticTheme.accentFlame,
                              side: BorderSide(color: KineticTheme.accentFlame.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutineOptionTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required List<String> exercises,
    required int minutes,
    required DateTime targetDate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: KineticTheme.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            Navigator.pop(ctx);
            final newWorkout = await DatabaseService.instance.createCustomWorkout(
              title: title,
              subtitle: subtitle,
              exerciseIds: exercises,
              estimatedMinutes: minutes,
              date: targetDate,
            );
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveWorkoutScreen(workout: newWorkout),
                ),
              ).then((_) => _loadCalendarData());
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: KineticTheme.accentFlame.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: KineticTheme.accentFlame, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subtitle · ~$minutes min',
                        style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Mark directly as completed',
                  child: IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                    color: KineticTheme.accentJade,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await DatabaseService.instance.quickLogCompletedWorkout(
                        title: title,
                        subtitle: subtitle,
                        exerciseIds: exercises,
                        durationMinutes: minutes,
                        date: targetDate,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged "$title" for ${targetDate.day}/${targetDate.month}/${targetDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: KineticTheme.accentJade,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _loadCalendarData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, color: KineticTheme.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBestStreaksSection() {
    final streaks = _calculateStreaks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BEST STREAKS',
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (streaks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            alignment: Alignment.center,
            decoration: KineticTheme.cardDecoration(backgroundColor: KineticTheme.bgSurface),
            child: Column(
              children: [
                Icon(Icons.bolt_outlined, color: KineticTheme.textTertiary, size: 28),
                SizedBox(height: 6),
                Text(
                  'NO STREAKS LOGGED YET',
                  style: TextStyle(
                    color: KineticTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete workouts on consecutive days to build consistency streaks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ...streaks.map((s) {
            final isCurrent = s['isCurrent'] as bool;
            final int days = s['days'] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: KineticTheme.cardDecoration(backgroundColor: KineticTheme.bgSurface),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      s['range'] as String,
                      style: TextStyle(color: KineticTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCurrent ? KineticTheme.accentFlame : KineticTheme.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$days DAYS',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : KineticTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  List<Map<String, dynamic>> _calculateStreaks() {
    if (_completedDateStrings.isEmpty) return [];

    final sortedDates = _completedDateStrings
        .map((s) {
          try {
            return DateTime.parse(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return [];

    final List<List<DateTime>> runs = [];
    List<DateTime> currentRun = [sortedDates.first];

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = currentRun.last;
      final curr = sortedDates[i];
      if (prev.difference(curr).inDays == 1) {
        currentRun.add(curr);
      } else {
        runs.add(currentRun);
        currentRun = [curr];
      }
    }
    runs.add(currentRun);

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatDate(DateTime d) => '${monthNames[d.month - 1]} ${d.day}';

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    runs.sort((a, b) => b.length.compareTo(a.length));

    return runs.take(3).map((r) {
      final isCurrent = r.first == today || r.first == yesterday;
      final range = r.length == 1
          ? formatDate(r.first)
          : '${formatDate(r.last)} - ${formatDate(r.first)}';
      return {
        'range': range,
        'days': r.length,
        'isCurrent': isCurrent,
      };
    }).toList();
  }

  Widget _buildFrequencySection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final active = List.generate(7, (i) {
      final dayDate = monday.add(Duration(days: i));
      final dateStr =
          "${dayDate.year.toString().padLeft(4, '0')}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}";
      return _completedDateStrings.contains(dateStr);
    });

    final completedThisWeek = active.where((a) => a).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(backgroundColor: KineticTheme.bgSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY FREQUENCY TARGET',
                style: TextStyle(
                  color: KineticTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '$completedThisWeek / 7 COMPLETED',
                style: const TextStyle(
                  color: KineticTheme.accentFlame,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isDone = active[i];
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? KineticTheme.accentFlame : KineticTheme.bgSurfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(color: KineticTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
