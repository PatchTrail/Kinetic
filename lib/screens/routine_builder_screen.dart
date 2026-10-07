import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/routine_plan.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class RoutineBuilderScreen extends StatefulWidget {
  final RoutinePlan? existingPlan;

  const RoutineBuilderScreen({Key? key, this.existingPlan}) : super(key: key);

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final List<String> _selectedDays = [];
  final List<Exercise> _selectedExercises = [];
  List<Exercise> _allExercises = [];
  bool _reminderEnabled = true;
  String _reminderTime = '07:30';
  int _estimatedMinutes = 60;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    KineticTheme.themeModeNotifier.addListener(_onThemeChanged);
    _loadInitialData();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    KineticTheme.themeModeNotifier.removeListener(_onThemeChanged);
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final exercises = await DatabaseService.instance.getAllExercises();
    if (!mounted) return;

    if (widget.existingPlan != null) {
      final p = widget.existingPlan!;
      _titleController.text = p.title;
      _subtitleController.text = p.subtitle;
      _selectedDays.addAll(p.daysOfWeek);
      _reminderEnabled = p.reminderEnabled;
      _reminderTime = p.reminderTime;
      _estimatedMinutes = p.estimatedMinutes;

      for (final id in p.exerciseIds) {
        final match = exercises.where((e) => e.id == id).toList();
        if (match.isNotEmpty) {
          _selectedExercises.add(match.first);
        }
      }
    } else {
      _titleController.text = 'Hypertrophy Protocol';
      _subtitleController.text = 'Progressive Overload & Density';
      _selectedDays.addAll(['Mon', 'Wed', 'Fri']);
      if (exercises.isNotEmpty) {
        _selectedExercises.addAll(exercises.take(3));
      }
    }

    setState(() {
      _allExercises = exercises;
      _isLoading = false;
    });
  }

  void _openExercisePicker() {
    String searchQuery = '';
    String selectedCategory = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final filtered = _allExercises.where((e) {
              final matchesQuery = e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  e.equipment.toLowerCase().contains(searchQuery.toLowerCase());
              final matchesCat = selectedCategory == 'All' || e.category.toLowerCase() == selectedCategory.toLowerCase();
              return matchesQuery && matchesCat;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SELECT EXERCISE FOR PROTOCOL',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  TextField(
                    onChanged: (v) => setPickerState(() => searchQuery = v),
                    style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'SEARCH EXERCISES...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Push', 'Pull', 'Legs', 'Core'].map((c) {
                        final isSel = selectedCategory == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: isSel,
                            selectedColor: AppTheme.accentOrange,
                            backgroundColor: AppTheme.cardBackground,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : KineticTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                            ),
                            onSelected: (_) => setPickerState(() => selectedCategory = c),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final ex = filtered[i];
                        final isAlreadyAdded = _selectedExercises.any((e) => e.id == ex.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAlreadyAdded ? AppTheme.accentOrange.withValues(alpha: 0.5) : AppTheme.cardBorder,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              ex.name,
                              style: TextStyle(color: KineticTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${ex.category} · ${ex.equipment} · ${ex.defaultSets} sets x ${ex.defaultReps} reps',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                            trailing: isAlreadyAdded
                                ? const Icon(Icons.check_circle, color: AppTheme.accentOrange, size: 20)
                                : Icon(Icons.add_circle_outline, color: AppTheme.textMuted, size: 20),
                            onTap: () {
                              if (!isAlreadyAdded) {
                                setState(() => _selectedExercises.add(ex));
                                setPickerState(() {});
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 7;
    final initialMin = int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentOrange,
              surface: AppTheme.surfaceDark,
              onSurface: KineticTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        _reminderTime = '$h:$m';
      });
    }
  }

  Future<void> _saveRoutine() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine title')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day of the week')),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise to the plan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final plan = RoutinePlan(
      id: widget.existingPlan?.id ?? 'routine_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty ? 'Custom Protocol' : _subtitleController.text.trim(),
      daysOfWeek: _selectedDays,
      exerciseIds: _selectedExercises.map((e) => e.id).toList(),
      estimatedMinutes: _estimatedMinutes,
      reminderTime: _reminderTime,
      reminderEnabled: _reminderEnabled,
    );

    await DatabaseService.instance.saveCustomRoutine(plan);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.accentGreen,
        content: Text(
          'ROUTINE "${plan.title.toUpperCase()}" SAVED & SCHEDULED ON CALENDAR',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
        ),
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'ROUTINE BUILDER // SCHEDULE',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            fontFamily: 'monospace',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.divider, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Header badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.tune, color: AppTheme.accentOrange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'CUSTOM PROTOCOL ARCHITECT',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Title Input
                _buildSectionHeader('PROTOCOL TITLE', '01'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: KineticTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'e.g. Hypertrophy Push Day',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.accentOrange)),
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle Input
                _buildSectionHeader('OBJECTIVE / SUBTITLE', '02'),
                const SizedBox(height: 8),
                TextField(
                  controller: _subtitleController,
                  style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'e.g. Chest & Triceps Specialization',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.accentOrange)),
                  ),
                ),

                const SizedBox(height: 24),

                // Days of week selector
                _buildSectionHeader('SCHEDULE DAYS (CALENDAR SYNC)', '03'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdays.map((day) {
                    final isSel = _selectedDays.contains(day);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSel) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        width: 42,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.accentOrange : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSel ? AppTheme.accentOrange : AppTheme.cardBorder,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day.toUpperCase(),
                          style: TextStyle(
                            color: isSel ? Colors.black : KineticTheme.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Notification Reminder & Duration Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active_outlined, color: AppTheme.accentOrange, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'PUSH NOTIFICATION ALARM',
                                style: TextStyle(
                                  color: KineticTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _reminderEnabled,
                            activeColor: AppTheme.accentOrange,
                            onChanged: (val) => setState(() => _reminderEnabled = val),
                          ),
                        ],
                      ),
                      if (_reminderEnabled) ...[
                        Divider(color: AppTheme.cardBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'REMINDER TRIGGER TIME',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                            InkWell(
                              onTap: _pickReminderTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.accentOrange),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: AppTheme.accentOrange, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _reminderTime,
                                      style: const TextStyle(
                                        color: AppTheme.accentOrange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Selected Exercises Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('EXERCISES IN PROTOCOL', '04'),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentOrange,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _openExercisePicker,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        '+ ADD EXERCISE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_selectedExercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No exercises added yet. Tap "+ ADD EXERCISE" above.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  )
                else
                  ..._selectedExercises.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ex = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '[0${idx + 1}]',
                              style: const TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: TextStyle(color: KineticTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ex.category} · ${ex.equipment} · ${ex.defaultSets} sets x ${ex.defaultReps} reps',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              setState(() => _selectedExercises.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 32),

                // Save Routine Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              'SAVE PROTOCOL & SYNC TO CALENDAR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, String index) {
    return Row(
      children: [
        Text(
          '[$index] ',
          style: const TextStyle(
            color: AppTheme.accentOrange,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
