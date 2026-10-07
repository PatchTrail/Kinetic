import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../services/database_service.dart';
import '../services/quote_service.dart';
import '../theme/app_theme.dart';
import '../widgets/anatomical_body_map.dart';
import '../widgets/breathing_progress_bar.dart';
import '../widgets/floating_music_capsule.dart';
import '../services/media_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;

  const ActiveWorkoutScreen({Key? key, required this.workout}) : super(key: key);

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  List<Exercise> _exercises = [];
  int _currentExerciseIndex = 0;
  List<WorkoutSet> _loggedSets = [];
  WorkoutSet? _previousBestSet;
  bool _isLoading = true;

  // Motivational Quotes
  QuoteItem? _preWorkoutQuote;
  QuoteItem? _postWorkoutQuote;
  bool _showPreWorkoutManifesto = true;

  // Session Stopwatch
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _isSessionRunning = true;

  // Rest Countdown Timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkoutSession();
    _startSessionTimer();
    _loadPreWorkoutQuote();
    MediaService.instance.startListening();
    KineticTheme.themeModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _loadPreWorkoutQuote() async {
    final quote = await QuoteService.instance.fetchLiveOrFallbackQuote(isPostWorkout: false);
    if (mounted) {
      setState(() => _preWorkoutQuote = quote);
    }
  }

  @override
  void dispose() {
    KineticTheme.themeModeNotifier.removeListener(_onThemeChanged);
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    MediaService.instance.stopListening();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isSessionRunning) {
        setState(() => _sessionSeconds++);
      }
    });
  }

  void _toggleSessionTimer() {
    setState(() => _isSessionRunning = !_isSessionRunning);
  }

  void _triggerRestTimer(int durationSeconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = durationSeconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = 0);
  }

  Future<void> _loadWorkoutSession() async {
    final exercises = await DatabaseService.instance.getExercisesForWorkout(widget.workout);
    final sets = await DatabaseService.instance.getSetsForWorkout(widget.workout.id);

    _exercises = exercises;
    _loggedSets = sets;

    await _prepareSetsForCurrentExercise();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _prepareSetsForCurrentExercise() async {
    final ex = _currentExercise;
    if (ex == null) return;

    final prev = await DatabaseService.instance.getLastCompletedSetForExercise(ex.id);
    final existingSets = _loggedSets.where((s) => s.exerciseId == ex.id).toList();

    // If no sets exist yet for this exercise in this workout, scaffold default sets
    if (existingSets.isEmpty) {
      final List<WorkoutSet> seeded = [];
      for (int i = 1; i <= ex.defaultSets; i++) {
        final s = WorkoutSet(
          id: 'set_${widget.workout.id}_${ex.id}_$i',
          workoutId: widget.workout.id,
          exerciseId: ex.id,
          setNumber: i,
          weightKg: prev?.weightKg ?? ex.defaultWeightKg,
          reps: prev?.reps ?? ex.defaultReps,
          isCompleted: false,
        );
        seeded.add(s);
        await DatabaseService.instance.saveSet(s);
      }
      _previousBestSet = prev;
      _loggedSets.addAll(seeded);
    } else {
      _previousBestSet = prev;
    }
  }

  Exercise? get _currentExercise {
    if (_exercises.isEmpty || _currentExerciseIndex >= _exercises.length) return null;
    return _exercises[_currentExerciseIndex];
  }

  Map<MuscleGroup, double> _getLiveMuscleActivation() {
    final map = <MuscleGroup, double>{};
    final ex = _currentExercise;
    if (ex != null) {
      for (final m in ex.primaryMuscles) {
        map[m] = 1.0;
      }
      for (final m in ex.secondaryMuscles) {
        map[m] = 0.55;
      }
    }
    return map;
  }

  Future<void> _toggleSetCompletion(WorkoutSet s) async {
    final updated = s.copyWith(
      isCompleted: !s.isCompleted,
      completedAt: !s.isCompleted ? DateTime.now() : null,
    );
    await DatabaseService.instance.saveSet(updated);

    setState(() {
      final idx = _loggedSets.indexWhere((item) => item.id == s.id);
      if (idx != -1) {
        _loggedSets[idx] = updated;
      }
    });

    if (updated.isCompleted) {
      // Trigger 90s rest countdown automatically
      _triggerRestTimer(90);
    }
  }

  Future<void> _updateSetValues(WorkoutSet s, double weight, int reps) async {
    final updated = s.copyWith(weightKg: weight, reps: reps);
    await DatabaseService.instance.saveSet(updated);
    setState(() {
      final idx = _loggedSets.indexWhere((item) => item.id == s.id);
      if (idx != -1) {
        _loggedSets[idx] = updated;
      }
    });
  }

  Future<void> _addSetToCurrentExercise() async {
    final ex = _currentExercise;
    if (ex == null) return;

    final currentSets = _loggedSets.where((s) => s.exerciseId == ex.id).toList();
    final nextNum = currentSets.length + 1;
    final lastWeight = currentSets.isNotEmpty ? currentSets.last.weightKg : ex.defaultWeightKg;
    final lastReps = currentSets.isNotEmpty ? currentSets.last.reps : ex.defaultReps;

    final newSet = WorkoutSet(
      id: 'set_${widget.workout.id}_${ex.id}_$nextNum',
      workoutId: widget.workout.id,
      exerciseId: ex.id,
      setNumber: nextNum,
      weightKg: lastWeight,
      reps: lastReps,
      isCompleted: false,
    );
    await DatabaseService.instance.saveSet(newSet);
    setState(() => _loggedSets.add(newSet));
  }

  void _nextExercise() async {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
      await _prepareSetsForCurrentExercise();
      if (mounted) setState(() {});
    }
  }

  void _prevExercise() async {
    if (_currentExerciseIndex > 0) {
      setState(() => _currentExerciseIndex--);
      await _prepareSetsForCurrentExercise();
      if (mounted) setState(() {});
    }
  }

  void _finishWorkout() async {
    // Freeze timers immediately so the clock doesn't tick behind completion dialog
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _isSessionRunning = false;
    _restTimer?.cancel();
    _restTimer = null;
    _restSecondsRemaining = 0;
    if (mounted) setState(() {});

    final completedSets = _loggedSets.where((s) => s.isCompleted).toList();
    final double totalVolume = completedSets.fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));
    final int totalReps = completedSets.fold(0, (sum, s) => sum + s.reps);

    final finishedWorkout = widget.workout.copyWith(
      durationMinutes: (_sessionSeconds / 60).ceil(),
      totalVolumeKg: totalVolume,
      totalSets: completedSets.length,
      totalReps: totalReps,
      isCompleted: true,
    );
    await DatabaseService.instance.saveWorkout(finishedWorkout);

    final victoryQuote = await QuoteService.instance.fetchLiveOrFallbackQuote(isPostWorkout: true);
    _postWorkoutQuote = victoryQuote;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCelebrationSheet(finishedWorkout, _postWorkoutQuote),
    );
  }

  void _showEditWeightModal(WorkoutSet set) {
    double tempWeight = set.weightKg;
    final controller = TextEditingController(text: tempWeight.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: KineticTheme.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'SET ${set.setNumber} · WEIGHT (KG)',
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Direct Number Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final p = double.tryParse(val);
                          if (p != null) tempWeight = p;
                        },
                        onSubmitted: (val) {
                          final p = double.tryParse(val) ?? tempWeight;
                          Navigator.pop(ctx);
                          _updateSetValues(set, p.clamp(0.0, 500.0), set.reps);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kg',
                      style: TextStyle(
                        color: KineticTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Micro Adjustments Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ADJUST', style: TextStyle(color: KineticTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [-5.0, -2.5, 2.5, 5.0, 10.0].map((delta) {
                  final label = delta > 0 ? '+$delta' : '$delta';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempWeight = (tempWeight + delta).clamp(0.0, 500.0);
                          controller.text = tempWeight.toStringAsFixed(1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KineticTheme.borderMedium),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: KineticTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Quick Preset Weights
              Align(
                alignment: Alignment.centerLeft,
                child: Text('PRESETS', style: TextStyle(color: KineticTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [20.0, 40.0, 60.0, 80.0, 100.0].map((wt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempWeight = wt;
                          controller.text = tempWeight.toStringAsFixed(1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KineticTheme.borderFaint),
                        ),
                        child: Text(
                          '${wt.toInt()}k',
                          style: TextStyle(
                            color: KineticTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: TextStyle(color: KineticTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KineticTheme.accentFlame,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final p = double.tryParse(controller.text) ?? tempWeight;
                Navigator.pop(ctx);
                _updateSetValues(set, p.clamp(0.0, 500.0), set.reps);
              },
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRepsModal(WorkoutSet set) {
    int tempReps = set.reps;
    final controller = TextEditingController(text: '$tempReps');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: KineticTheme.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'SET ${set.setNumber} · REPS',
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Direct Number Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final p = int.tryParse(val);
                          if (p != null) tempReps = p;
                        },
                        onSubmitted: (val) {
                          final p = int.tryParse(val) ?? tempReps;
                          Navigator.pop(ctx);
                          _updateSetValues(set, set.weightKg, p.clamp(1, 100));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'reps',
                      style: TextStyle(
                        color: KineticTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Micro Adjustments Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text('ADJUST', style: TextStyle(color: KineticTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [-2, -1, 1, 2, 5].map((delta) {
                  final label = delta > 0 ? '+$delta' : '$delta';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempReps = (tempReps + delta).clamp(1, 100);
                          controller.text = '$tempReps';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KineticTheme.borderMedium),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: KineticTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Quick Preset Reps
              Align(
                alignment: Alignment.centerLeft,
                child: Text('PRESETS', style: TextStyle(color: KineticTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [5, 6, 8, 10, 12, 15].map((reps) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempReps = reps;
                          controller.text = '$tempReps';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KineticTheme.borderFaint),
                        ),
                        child: Text(
                          '$reps',
                          style: TextStyle(
                            color: KineticTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: TextStyle(color: KineticTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KineticTheme.accentFlame,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final p = int.tryParse(controller.text) ?? tempReps;
                Navigator.pop(ctx);
                _updateSetValues(set, set.weightKg, p.clamp(1, 100));
              },
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimer(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentExercise == null) {
      return Scaffold(
        backgroundColor: KineticTheme.bgCanvas,
        body: Center(child: CircularProgressIndicator(color: KineticTheme.accentFlame)),
      );
    }

    final ex = _currentExercise!;
    final activationMap = _getLiveMuscleActivation();
    final currentExerciseSets = _loggedSets.where((s) => s.exerciseId == ex.id).toList();

    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: KineticTheme.bgCanvas,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: KineticTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.workout.title.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: KineticTheme.accentFlame,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'FINISH',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextExercise,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevExercise,
          const SingleActivator(LogicalKeyboardKey.space): _toggleSessionTimer,
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SafeArea(
            child: Column(
              children: [
                // Top Session Progress Bar
                BreathingProgressBar(
                  value: _exercises.isEmpty ? 0.0 : (_currentExerciseIndex + 1) / _exercises.length,
                  height: 3,
                  color: KineticTheme.accentFlame,
                  backgroundColor: KineticTheme.bgSurfaceElevated,
                  showStripes: true,
                  showLeadingBeacon: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // Pre-Workout Motivational Manifesto Banner
                        if (_showPreWorkoutManifesto && _preWorkoutQuote != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: KineticTheme.bgSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: KineticTheme.borderFaint),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: KineticTheme.accentFlame,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'PRE-SESSION MANIFESTO',
                                          style: TextStyle(
                                            color: KineticTheme.accentFlame,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _showPreWorkoutManifesto = false),
                                      child: Icon(Icons.close_rounded, size: 16, color: KineticTheme.textTertiary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '"${_preWorkoutQuote!.quote}"',
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '— ${_preWorkoutQuote!.author}${_preWorkoutQuote!.book != null ? ' (${_preWorkoutQuote!.book})' : ''}',
                                    style: TextStyle(
                                      color: KineticTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Exercise Header & Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EXERCISE ${_currentExerciseIndex + 1} OF ${_exercises.length}',
                                  style: TextStyle(
                                    color: KineticTheme.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ex.name,
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Workout Timer Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: KineticTheme.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: KineticTheme.borderMedium),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: KineticTheme.accentAmber),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimer(_sessionSeconds),
                                    style: TextStyle(
                                      color: KineticTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Anatomical Muscle Target Visualizer (Vector)
                        AnatomicalBodyMap(
                          activationLevels: activationMap,
                          showBothViews: true,
                          height: 180,
                        ),
                        const SizedBox(height: 10),

                        // Muscle tags banner
                        Wrap(
                          spacing: 6,
                          children: [
                            ...ex.primaryMuscles.map((m) => _buildMuscleTag(m.displayName, isPrimary: true)),
                            ...ex.secondaryMuscles.map((m) => _buildMuscleTag(m.displayName, isPrimary: false)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Previous Best Reference (References/Cards UI-UX.jpg)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: KineticTheme.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 14, color: KineticTheme.accentAmber),
                                  SizedBox(width: 6),
                                  Text(
                                    'PREVIOUS PERFORMANCE',
                                    style: TextStyle(
                                      color: KineticTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _previousBestSet != null
                                    ? '${_previousBestSet!.weightKg} kg × ${_previousBestSet!.reps} reps'
                                    : '${ex.defaultWeightKg} kg × ${ex.defaultReps} reps (Target)',
                                style: TextStyle(
                                  color: KineticTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Rest Timer Banner (if active)
                        if (_restSecondsRemaining > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: KineticTheme.accentAmber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KineticTheme.accentAmber.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bedtime_outlined, size: 16, color: KineticTheme.accentAmber),
                                    const SizedBox(width: 8),
                                    Text(
                                      'REST: ${_formatTimer(_restSecondsRemaining)}',
                                      style: const TextStyle(
                                        color: KineticTheme.accentAmber,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _restSecondsRemaining += 30),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: KineticTheme.bgSurfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('+30s', style: TextStyle(color: KineticTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _cancelRestTimer,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: KineticTheme.bgSurfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('SKIP', style: TextStyle(color: KineticTheme.accentFlame, fontSize: 11, fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // Real Interactive Sets Table (References/Exercise Screen with timer and exercise.jpg)
                        _buildSetsTable(currentExerciseSets),
                        const SizedBox(height: 12),

                        // + Add Set Button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton(
                            onPressed: _addSetToCurrentExercise,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: KineticTheme.borderMedium),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 16, color: KineticTheme.textSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'ADD SET',
                                  style: TextStyle(
                                    color: KineticTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Bottom Floating Exercise Player Bar (References/Exercise Screen with timer and exercise.jpg)
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 16, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: KineticTheme.bgSurface.withValues(alpha: 0.96),
                    border: Border(top: BorderSide(color: KineticTheme.borderFaint)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Floating Music Capsule (Only renders if active audio is playing)
                      FloatingMusicCapsule(key: ValueKey('capsule_workout_${KineticTheme.isDarkMode ? "dark" : "light"}')),

                      // 2. Active Rest Countdown Banner
                      if (_restSecondsRemaining > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: KineticTheme.accentAmber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: KineticTheme.accentAmber.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bedtime_outlined, color: KineticTheme.accentAmber, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'REST: ${_formatTimer(_restSecondsRemaining)}',
                                    style: const TextStyle(
                                      color: KineticTheme.accentAmber,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _restSecondsRemaining += 30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: KineticTheme.accentAmber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '+30s',
                                        style: TextStyle(color: KineticTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _cancelRestTimer,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: KineticTheme.bgSurfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: KineticTheme.borderMedium),
                                      ),
                                      child: Text(
                                        'SKIP',
                                        style: TextStyle(color: KineticTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // 3. Clean Exercise Navigation Stepper
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: KineticTheme.borderMedium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Exercise Button
                            TextButton.icon(
                              onPressed: _currentExerciseIndex > 0 ? _prevExercise : null,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 12,
                                color: _currentExerciseIndex > 0 ? KineticTheme.textPrimary : KineticTheme.textTertiary,
                              ),
                              label: Text(
                                'PREV',
                                style: TextStyle(
                                  color: _currentExerciseIndex > 0 ? KineticTheme.textPrimary : KineticTheme.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Exercise indicator
                            Text(
                              'EXERCISE ${_currentExerciseIndex + 1} OF ${_exercises.length}',
                              style: TextStyle(
                                color: KineticTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 0.8,
                              ),
                            ),

                            // Next Exercise Button
                            TextButton(
                              onPressed: _currentExerciseIndex < _exercises.length - 1 ? _nextExercise : null,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'NEXT',
                                    style: TextStyle(
                                      color: _currentExerciseIndex < _exercises.length - 1 ? KineticTheme.textPrimary : KineticTheme.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: _currentExerciseIndex < _exercises.length - 1 ? KineticTheme.textPrimary : KineticTheme.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Form Matters. Reps Count.',
                        style: TextStyle(
                          color: KineticTheme.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildSetsTable(List<WorkoutSet> sets) {
    return Container(
      decoration: BoxDecoration(
        color: KineticTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KineticTheme.borderMedium, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: KineticTheme.bgSurfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: KineticTheme.borderFaint)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    'SET',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'KG',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Center(
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        color: KineticTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows for each set
          ...sets.map((s) {
            final isDone = s.isCompleted;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? KineticTheme.accentJade.withValues(alpha: 0.08) : Colors.transparent,
                border: Border(bottom: BorderSide(color: KineticTheme.borderFaint)),
              ),
              child: Row(
                children: [
                  // Set Number
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${s.setNumber}',
                      style: TextStyle(
                        color: isDone ? KineticTheme.accentJade : KineticTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  // Weight Stepper & Direct Numeric Tap
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickStepperBtn(Icons.remove, () {
                          _updateSetValues(s, (s.weightKg - 2.5).clamp(0, 500), s.reps);
                        }),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showEditWeightModal(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: KineticTheme.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.weightKg.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.edit_outlined, size: 10, color: KineticTheme.accentFlame),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildQuickStepperBtn(Icons.add, () {
                          _updateSetValues(s, (s.weightKg + 2.5).clamp(0, 500), s.reps);
                        }),
                      ],
                    ),
                  ),

                  // Reps Stepper & Direct Numeric Tap
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickStepperBtn(Icons.remove, () {
                          _updateSetValues(s, s.weightKg, (s.reps - 1).clamp(1, 100));
                        }),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showEditRepsModal(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: KineticTheme.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${s.reps}',
                                  style: TextStyle(
                                    color: KineticTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.edit_outlined, size: 10, color: KineticTheme.accentFlame),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildQuickStepperBtn(Icons.add, () {
                          _updateSetValues(s, s.weightKg, (s.reps + 1).clamp(1, 100));
                        }),
                      ],
                    ),
                  ),

                  // Completion Checkbox Button (Fitts's Law Target)
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _toggleSetCompletion(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDone ? KineticTheme.accentJade : KineticTheme.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDone ? KineticTheme.accentJade : KineticTheme.borderMedium,
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: isDone ? Colors.white : KineticTheme.textTertiary,
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
      ),
    );
  }

  Widget _buildQuickStepperBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: KineticTheme.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: KineticTheme.borderMedium, width: 0.8),
        ),
        child: Icon(icon, size: 12, color: KineticTheme.textPrimary),
      ),
    );
  }

  Widget _buildMuscleTag(String name, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isPrimary ? KineticTheme.accentFlame.withValues(alpha: 0.12) : KineticTheme.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? KineticTheme.accentFlame.withValues(alpha: 0.4) : KineticTheme.borderMedium,
          width: 0.8,
        ),
      ),
      child: Text(
        name.toUpperCase(),
        style: TextStyle(
          color: isPrimary ? KineticTheme.accentFlame : KineticTheme.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildCelebrationSheet(Workout w, [QuoteItem? quote]) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KineticTheme.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: KineticTheme.borderFaint),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KineticTheme.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: KineticTheme.accentFlame.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 28, color: KineticTheme.accentFlame),
          ),
          const SizedBox(height: 12),
          Text(
            'PROTOCOL COMPLETE',
            style: TextStyle(
              color: KineticTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${w.durationMinutes} mins · ${w.totalSets} completed sets',
            style: TextStyle(color: KineticTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatPill('TOTAL TONNAGE', '${w.totalVolumeKg.toInt()} kg'),
              _buildStatPill('TOTAL REPS', '${w.totalReps}'),
              _buildStatPill('EST. 1RM', '102 kg'),
            ],
          ),
          if (quote != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KineticTheme.bgSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 16, color: KineticTheme.accentFlame),
                      SizedBox(width: 6),
                      Text(
                        'VICTORY MANIFESTO',
                        style: TextStyle(
                          color: KineticTheme.accentFlame,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${quote.quote}"',
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${quote.author}${quote.book != null ? ' (${quote.book})' : ''}',
                      style: TextStyle(
                        color: KineticTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KineticTheme.accentFlame,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('RETURN TO COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: KineticTheme.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: KineticTheme.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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
  }
}
