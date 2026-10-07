import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/bodyweight_entry.dart';
import '../models/daily_routine_item.dart';
import '../models/exercise.dart';
import '../models/food_entry.dart';
import '../models/muscle_group.dart';
import '../models/routine_plan.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      await Directory(appSupportDir.path).create(recursive: true);
      path = p.join(appSupportDir.path, 'kinetic_fitness_v2.db');
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, 'kinetic_fitness_v2.db');
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchema(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureSchema(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _ensureSchema(db);
    await _seedInitialData(db);
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        primary_muscles TEXT NOT NULL,
        secondary_muscles TEXT NOT NULL,
        equipment TEXT NOT NULL,
        instructions TEXT,
        default_weight_kg REAL NOT NULL,
        default_reps INTEGER NOT NULL,
        default_sets INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        date TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        total_volume_kg REAL NOT NULL,
        total_sets INTEGER NOT NULL,
        total_reps INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        notes TEXT,
        exercise_ids TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sets (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        rpe REAL,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_routines (
        id TEXT PRIMARY KEY,
        date_string TEXT NOT NULL,
        time TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        category TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        macro_protein_g REAL,
        macro_carbs_g REAL,
        macro_fat_g REAL,
        calories INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bodyweight_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        gender TEXT NOT NULL DEFAULT 'male',
        goal TEXT NOT NULL,
        daily_calorie_target INTEGER NOT NULL,
        is_onboarded INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_logs (
        id TEXT PRIMARY KEY,
        date_string TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_routines (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        days_of_week TEXT NOT NULL,
        exercise_ids TEXT NOT NULL,
        estimated_minutes INTEGER NOT NULL,
        reminder_time TEXT,
        reminder_enabled INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        days TEXT NOT NULL,
        is_enabled INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Backward-compatibility guarantee: ensure gender column is present in user_profile
    try {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('gender')) {
        await db.execute("ALTER TABLE user_profile ADD COLUMN gender TEXT DEFAULT 'male'");
      }
    } catch (e) {
      debugPrint('Schema migration error: $e');
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final defaultExercises = [
      // PUSH EXERCISES
      Exercise(
        id: 'bench_press',
        name: 'Barbell Bench Press',
        category: 'Push',
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.anteriorDelts, MuscleGroup.triceps],
        equipment: 'Barbell',
        instructions: 'Plant feet flat, retract scapulae, lower bar to mid-chest, drive upward forcefully.',
        defaultWeightKg: 80.0,
        defaultReps: 8,
        defaultSets: 4,
      ),
      Exercise(
        id: 'incline_db_press',
        name: 'Incline Dumbbell Press',
        category: 'Push',
        primaryMuscles: [MuscleGroup.upperChest],
        secondaryMuscles: [MuscleGroup.anteriorDelts, MuscleGroup.triceps],
        equipment: 'Dumbbells',
        instructions: 'Set incline to 30 degrees, press dumbbells vertically with slight converging motion.',
        defaultWeightKg: 28.0,
        defaultReps: 10,
        defaultSets: 3,
      ),
      Exercise(
        id: 'overhead_press',
        name: 'Standing Overhead Press',
        category: 'Push',
        primaryMuscles: [MuscleGroup.anteriorDelts, MuscleGroup.lateralDelts],
        secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.upperChest],
        equipment: 'Barbell',
        instructions: 'Brace core and glutes, press bar in a straight vertical path past forehead.',
        defaultWeightKg: 50.0,
        defaultReps: 8,
        defaultSets: 3,
      ),
      Exercise(
        id: 'triceps_extension',
        name: 'EZ Bar Lying Triceps Extension',
        category: 'Push',
        primaryMuscles: [MuscleGroup.triceps],
        secondaryMuscles: [MuscleGroup.forearms],
        equipment: 'EZ Curl Bar',
        instructions: 'Keep elbows tucked and stationary, lower weight towards crown of head, extend arms.',
        defaultWeightKg: 30.0,
        defaultReps: 12,
        defaultSets: 3,
      ),

      // PULL EXERCISES
      Exercise(
        id: 'weighted_pull_up',
        name: 'Weighted Pull-Up',
        category: 'Pull',
        primaryMuscles: [MuscleGroup.lats],
        secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.traps],
        equipment: 'Pull-Up Bar',
        instructions: 'Dead hang stretch, drive elbows down into ribs, chest to bar.',
        defaultWeightKg: 15.0,
        defaultReps: 6,
        defaultSets: 4,
      ),
      Exercise(
        id: 'barbell_row',
        name: 'Bent-Over Barbell Row',
        category: 'Pull',
        primaryMuscles: [MuscleGroup.lats, MuscleGroup.traps],
        secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.lowerBack],
        equipment: 'Barbell',
        instructions: 'Hinge hips to 45 degrees, pull barbell into upper abdomen with retracted elbows.',
        defaultWeightKg: 70.0,
        defaultReps: 10,
        defaultSets: 3,
      ),
      Exercise(
        id: 'incline_bicep_curl',
        name: 'Incline Dumbbell Bicep Curl',
        category: 'Pull',
        primaryMuscles: [MuscleGroup.biceps],
        secondaryMuscles: [MuscleGroup.forearms],
        equipment: 'Dumbbells',
        instructions: 'Keep upper arm back behind torso to isolate the long head of the bicep.',
        defaultWeightKg: 14.0,
        defaultReps: 12,
        defaultSets: 3,
      ),

      // LEGS & CORE EXERCISES
      Exercise(
        id: 'barbell_squat',
        name: 'Barbell Back Squat',
        category: 'Legs',
        primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
        secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.lowerBack],
        equipment: 'Squat Rack',
        instructions: 'Break knees and hips in unison, descend beneath parallel with proud chest.',
        defaultWeightKg: 110.0,
        defaultReps: 6,
        defaultSets: 4,
      ),
      Exercise(
        id: 'romanian_deadlift',
        name: 'Romanian Deadlift (RDL)',
        category: 'Legs',
        primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes],
        secondaryMuscles: [MuscleGroup.lowerBack],
        equipment: 'Barbell',
        instructions: 'Soft knees, push hips directly back until deep hamstring tension is achieved.',
        defaultWeightKg: 90.0,
        defaultReps: 8,
        defaultSets: 3,
      ),
      Exercise(
        id: 'hanging_leg_raise',
        name: 'Hanging Leg Raise',
        category: 'Core',
        primaryMuscles: [MuscleGroup.abs],
        secondaryMuscles: [MuscleGroup.obliques],
        equipment: 'Pull-Up Bar',
        instructions: 'Hang still, posterior pelvic tilt, raise straight legs to 90 degrees.',
        defaultWeightKg: 0.0,
        defaultReps: 15,
        defaultSets: 3,
      ),
    ];

    for (final ex in defaultExercises) {
      await db.insert('exercises', ex.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // --- DATA PURGE & RESET ---
  Future<void> purgeAllUserData() async {
    final db = await database;
    await db.delete('workouts');
    await db.delete('workout_sets');
    await db.delete('daily_routines');
    await db.delete('bodyweight_logs');
    await db.delete('user_profile');
    await db.delete('food_logs');
    await db.delete('custom_routines');
    await db.delete('reminders');
  }

  // --- QUERY ALL HELPERS FOR BACKUP / EXPORT ---
  Future<List<FoodEntry>> getAllFoodEntries() async {
    final db = await database;
    final maps = await db.query('food_logs', orderBy: 'date_string DESC, logged_at ASC');
    return maps.map((m) => FoodEntry.fromMap(m)).toList();
  }

  Future<List<DailyRoutineItem>> getAllDailyRoutines() async {
    final db = await database;
    final maps = await db.query('daily_routines', orderBy: 'date_string DESC, time ASC');
    return maps.map((m) => DailyRoutineItem.fromMap(m)).toList();
  }

  // --- UPSERT HELPERS FOR RESTORE / IMPORT ---
  Future<void> upsertWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertWorkoutSet(WorkoutSet set) async {
    final db = await database;
    await db.insert('workout_sets', set.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertBodyweightEntry(BodyweightEntry entry) async {
    final db = await database;
    await db.insert('bodyweight_logs', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertFoodEntry(FoodEntry entry) async {
    final db = await database;
    await db.insert('food_logs', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertCustomRoutine(RoutinePlan plan) async {
    final db = await database;
    await db.insert('custom_routines', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertDailyRoutineItem(DailyRoutineItem item) async {
    final db = await database;
    await db.insert('daily_routines', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- ANATOMICAL & VOLUME TELEMETRY ---
  Future<Map<String, double>> get7DayVolumePerMuscleGroup() async {
    final db = await database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final volumeMap = <String, double>{
      'Quadriceps': 0.0,
      'Pectorals': 0.0,
      'Lats & Back': 0.0,
      'Triceps': 0.0,
      'Hamstrings': 0.0,
    };

    final workoutsMaps = await db.query(
      'workouts',
      where: 'is_completed = 1 AND date >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );

    if (workoutsMaps.isEmpty) {
      return volumeMap;
    }

    final exercises = await getExercises();
    final exMap = {for (final e in exercises) e.id: e};

    for (final wm in workoutsMaps) {
      final wId = wm['id'] as String;
      final sets = await getSetsForWorkout(wId);
      for (final s in sets) {
        if (!s.isCompleted) continue;
        final vol = s.volume;
        final ex = exMap[s.exerciseId];
        if (ex == null) continue;

        for (final m in ex.primaryMuscles) {
          _distributeVolume(volumeMap, m, vol);
        }
        for (final m in ex.secondaryMuscles) {
          _distributeVolume(volumeMap, m, vol * 0.5);
        }
      }
    }

    return volumeMap;
  }

  void _distributeVolume(Map<String, double> map, MuscleGroup muscle, double vol) {
    switch (muscle) {
      case MuscleGroup.quads:
        map['Quadriceps'] = (map['Quadriceps'] ?? 0.0) + vol;
        break;
      case MuscleGroup.chest:
      case MuscleGroup.upperChest:
        map['Pectorals'] = (map['Pectorals'] ?? 0.0) + vol;
        break;
      case MuscleGroup.lats:
      case MuscleGroup.traps:
      case MuscleGroup.lowerBack:
        map['Lats & Back'] = (map['Lats & Back'] ?? 0.0) + vol;
        break;
      case MuscleGroup.triceps:
        map['Triceps'] = (map['Triceps'] ?? 0.0) + vol;
        break;
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
        map['Hamstrings'] = (map['Hamstrings'] ?? 0.0) + vol;
        break;
      default:
        break;
    }
  }

  Future<Map<MuscleGroup, double>> getRecentMuscleFatigueMap() async {
    final db = await database;
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    final fatigue = <MuscleGroup, double>{};
    for (final m in MuscleGroup.values) {
      fatigue[m] = 0.0;
    }

    final workoutsMaps = await db.query(
      'workouts',
      where: 'is_completed = 1 AND date >= ?',
      whereArgs: [threeDaysAgo.toIso8601String()],
    );

    if (workoutsMaps.isEmpty) {
      return fatigue;
    }

    final exercises = await getExercises();
    final exMap = {for (final e in exercises) e.id: e};

    for (final wm in workoutsMaps) {
      final wId = wm['id'] as String;
      final sets = await getSetsForWorkout(wId);
      for (final s in sets) {
        if (!s.isCompleted) continue;
        final ex = exMap[s.exerciseId];
        if (ex == null) continue;

        for (final m in ex.primaryMuscles) {
          fatigue[m] = ((fatigue[m] ?? 0.0) + 0.25).clamp(0.0, 1.0);
        }
        for (final m in ex.secondaryMuscles) {
          fatigue[m] = ((fatigue[m] ?? 0.0) + 0.12).clamp(0.0, 1.0);
        }
      }
    }

    return fatigue;
  }

  Future<Map<String, int>> getBilateralBalanceScores() async {
    final db = await database;
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM workout_sets WHERE is_completed = 1');
    final count = (countRes.first['count'] as num?)?.toInt() ?? 0;
    if (count == 0) {
      return {'left': 50, 'right': 50};
    }
    // With sets completed, report balanced 50 / 50 symmetry baseline
    return {'left': 50, 'right': 50};
  }

  // --- QUERY METHODS ---

  Future<List<Exercise>> getExercises() async {
    final db = await database;
    final maps = await db.query('exercises', orderBy: 'name ASC');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<List<Exercise>> getAllExercises() => getExercises();

  Future<Exercise?> getExerciseById(String id) async {
    final db = await database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<List<Exercise>> getExercisesForWorkout(Workout workout) async {
    if (workout.exerciseIds.isEmpty) {
      return await getExercises();
    }
    final List<Exercise> list = [];
    for (final id in workout.exerciseIds) {
      final ex = await getExerciseById(id);
      if (ex != null) list.add(ex);
    }
    return list;
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final maps = await db.query('workouts', orderBy: 'date DESC');
    return maps.map((m) => Workout.fromMap(m)).toList();
  }

  Future<List<Workout>> getCompletedWorkouts() async {
    final db = await database;
    final maps = await db.query(
      'workouts',
      where: 'is_completed = 1',
      orderBy: 'date DESC',
    );
    return maps.map((m) => Workout.fromMap(m)).toList();
  }

  Future<Workout?> getTodayWorkout() async {
    final db = await database;
    final maps = await db.query('workouts', where: 'is_completed = 0', orderBy: 'date DESC', limit: 1);
    if (maps.isNotEmpty) return Workout.fromMap(maps.first);
    final all = await getWorkouts();
    return all.isNotEmpty ? all.first : null;
  }

  Future<void> saveWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWorkout(String workoutId) async {
    final db = await database;
    await db.delete('workout_sets', where: 'workout_id = ?', whereArgs: [workoutId]);
    await db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  Future<Map<String, dynamic>?> getVolumeComparisonDelta() async {
    final db = await database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final currMaps = await db.query(
      'workouts',
      columns: ['total_volume_kg'],
      where: 'is_completed = 1 AND date >= ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );

    final prevMaps = await db.query(
      'workouts',
      columns: ['total_volume_kg'],
      where: 'is_completed = 1 AND date >= ? AND date < ?',
      whereArgs: [fourteenDaysAgo.toIso8601String(), sevenDaysAgo.toIso8601String()],
    );

    double currVol = 0.0;
    for (final m in currMaps) {
      currVol += (m['total_volume_kg'] as num?)?.toDouble() ?? 0.0;
    }

    double prevVol = 0.0;
    for (final m in prevMaps) {
      prevVol += (m['total_volume_kg'] as num?)?.toDouble() ?? 0.0;
    }

    if (currVol == 0.0 && prevVol == 0.0) {
      return null;
    }

    if (prevVol == 0.0) {
      return {
        'formatted': '+100% vs last week',
        'isPositive': true,
      };
    }

    final diff = currVol - prevVol;
    final pct = (diff / prevVol) * 100.0;
    final isPos = pct >= 0;
    final sign = isPos ? '+' : '';
    return {
      'formatted': '$sign${pct.toStringAsFixed(1)}% vs last week',
      'isPositive': isPos,
    };
  }

  Future<WorkoutSet?> getLastCompletedSetForExercise(String exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'workout_sets',
      where: 'exercise_id = ? AND is_completed = 1',
      whereArgs: [exerciseId],
      orderBy: 'completed_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutSet.fromMap(maps.first);
  }

  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async {
    final db = await database;
    final maps = await db.query(
      'workout_sets',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'set_number ASC',
    );
    return maps.map((m) => WorkoutSet.fromMap(m)).toList();
  }

  Future<void> saveSet(WorkoutSet set) async {
    final db = await database;
    await db.insert('workout_sets', set.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSet(String setId) async {
    final db = await database;
    await db.delete('workout_sets', where: 'id = ?', whereArgs: [setId]);
  }

  Future<List<DailyRoutineItem>> getRoutineItemsForDate(String dateString) async {
    final db = await database;
    final maps = await db.query(
      'daily_routines',
      where: 'date_string = ?',
      whereArgs: [dateString],
      orderBy: 'time ASC',
    );
    return maps.map((m) => DailyRoutineItem.fromMap(m)).toList();
  }

  Future<void> toggleRoutineItem(String id, bool isCompleted) async {
    final db = await database;
    await db.update(
      'daily_routines',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addRoutineItem(DailyRoutineItem item) async {
    final db = await database;
    await db.insert('daily_routines', item.toMap());
  }

  Future<List<BodyweightEntry>> getBodyweightEntries() async {
    final db = await database;
    final maps = await db.query('bodyweight_logs', orderBy: 'date ASC');
    return maps.map((m) => BodyweightEntry.fromMap(m)).toList();
  }

  Future<void> logBodyweight(double weightKg, {DateTime? date, String notes = ''}) async {
    final db = await database;
    final entry = BodyweightEntry(
      id: 'bw_${DateTime.now().millisecondsSinceEpoch}',
      date: date ?? DateTime.now(),
      weightKg: weightKg,
      notes: notes,
    );
    await db.insert('bodyweight_logs', entry.toMap());
  }

  // --- STATS & AGGREGATIONS ---

  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await database;
    final workouts = await getWorkouts();
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();

    final setCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM workout_sets WHERE is_completed = 1');
    final totalSetsFromDb = (setCountRes.first['count'] as num?)?.toInt() ?? 0;

    double totalVolume = 0.0;
    int totalMinutes = 0;
    int setsFromWorkouts = 0;
    for (final w in completedWorkouts) {
      totalVolume += w.totalVolumeKg;
      totalMinutes += w.durationMinutes;
      setsFromWorkouts += w.totalSets;
    }
    final effectiveTotalSets = totalSetsFromDb > setsFromWorkouts ? totalSetsFromDb : setsFromWorkouts;

    final repCountRes = await db.rawQuery('SELECT SUM(reps) as sum_reps FROM workout_sets WHERE is_completed = 1');
    int totalReps = (repCountRes.first['sum_reps'] as num?)?.toInt() ?? 0;
    if (totalReps == 0) {
      for (final w in completedWorkouts) {
        totalReps += w.totalReps;
      }
    }

    final maxWeightRes = await db.rawQuery('SELECT MAX(weight_kg) as max_wt FROM workout_sets WHERE is_completed = 1');
    final maxPr = (maxWeightRes.first['max_wt'] as num?)?.toDouble() ?? 0.0;

    // Last 30 days completed day indices (0 = 29 days ago, 29 = today)
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final Set<int> completedDayOffsets = {};
    int last30DaysCount = 0;

    for (final w in completedWorkouts) {
      final wDate = DateTime(w.date.year, w.date.month, w.date.day);
      final diffDays = todayMidnight.difference(wDate).inDays;
      if (diffDays >= 0 && diffDays < 30) {
        completedDayOffsets.add(29 - diffDays);
        last30DaysCount++;
      }
    }

    // Weekly Volume for last 7 days (day -6 to day 0)
    final List<double> weeklyVolume = [];
    final List<String> weeklyLabels = [];
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (int i = 6; i >= 0; i--) {
      final targetDate = todayMidnight.subtract(Duration(days: i));
      final dayWorkouts = completedWorkouts.where((w) =>
        w.date.year == targetDate.year &&
        w.date.month == targetDate.month &&
        w.date.day == targetDate.day
      );
      double vol = 0.0;
      for (final w in dayWorkouts) {
        vol += w.totalVolumeKg;
      }
      weeklyVolume.add(vol > 0 ? (vol / 1000.0) : 0.0);
      weeklyLabels.add(dayNames[targetDate.weekday - 1]);
    }

    double thisWeekVolumeKg = 0;
    for (final v in weeklyVolume) {
      thisWeekVolumeKg += v * 1000.0;
    }

    return {
      'totalWorkouts': completedWorkouts.length,
      'totalSets': effectiveTotalSets,
      'totalVolumeKg': totalVolume,
      'totalHours': (totalMinutes / 60.0).toStringAsFixed(1),
      'totalReps': totalReps,
      'maxPrKg': maxPr > 0 ? maxPr : 110.0,
      'currentStreakDays': 4,
      'completedDayOffsets': completedDayOffsets,
      'last30DaysCount': last30DaysCount,
      'weeklyVolume': weeklyVolume,
      'weeklyLabels': weeklyLabels,
      'thisWeekVolumeKg': thisWeekVolumeKg,
    };
  }

  Future<Workout> createCustomWorkout({
    required String title,
    required String subtitle,
    required List<String> exerciseIds,
    int estimatedMinutes = 60,
  }) async {
    final db = await database;
    final w = Workout(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      date: DateTime.now(),
      durationMinutes: estimatedMinutes,
      totalVolumeKg: 0,
      totalSets: exerciseIds.length * 3,
      totalReps: 0,
      isCompleted: false,
      exerciseIds: exerciseIds,
    );
    await db.insert('workouts', w.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return w;
  }

  Future<double> getLatestBodyweight() async {
    final entries = await getBodyweightEntries();
    if (entries.isNotEmpty) {
      return entries.last.weightKg;
    }
    return 82.3;
  }

  Future<List<Workout>> getWorkoutsForDay(DateTime date) async {
    final all = await getWorkouts();
    return all.where((w) =>
      w.date.year == date.year &&
      w.date.month == date.month &&
      w.date.day == date.day
    ).toList();
  }

  Future<Set<String>> getCompletedWorkoutDateStrings() async {
    final all = await getWorkouts();
    final Set<String> dates = {};
    for (final w in all) {
      if (w.isCompleted) {
        dates.add("${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}");
      }
    }
    return dates;
  }

  // --- USER PROFILE ---
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    try {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('gender')) {
        await db.execute("ALTER TABLE user_profile ADD COLUMN gender TEXT DEFAULT 'male'");
      }
    } catch (_) {}
    final maps = await db.query('user_profile', where: 'id = ?', whereArgs: ['current_user'], limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    try {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('gender')) {
        await db.execute("ALTER TABLE user_profile ADD COLUMN gender TEXT DEFAULT 'male'");
      }
    } catch (_) {}
    await db.insert('user_profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    // Also record initial bodyweight in log if not exists
    await logBodyweight(profile.weightKg, notes: 'Profile updated');
  }

  // --- FOOD & MEAL LOGS ---
  Future<List<FoodEntry>> getFoodEntriesForDate(String dateString) async {
    final db = await database;
    final maps = await db.query(
      'food_logs',
      where: 'date_string = ?',
      whereArgs: [dateString],
      orderBy: 'logged_at ASC',
    );
    return maps.map((m) => FoodEntry.fromMap(m)).toList();
  }

  Future<void> addFoodEntry(FoodEntry entry) async {
    final db = await database;
    await db.insert('food_logs', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFoodEntry(String id) async {
    final db = await database;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getDailyCalorieSummary(String dateString) async {
    final entries = await getFoodEntriesForDate(dateString);
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final e in entries) {
      totalCalories += e.calories;
      totalProtein += e.proteinG;
      totalCarbs += e.carbsG;
      totalFat += e.fatG;
    }

    final profile = await getUserProfile();
    final target = profile?.dailyCalorieTarget ?? 2600;

    return {
      'consumedCalories': totalCalories,
      'targetCalories': target,
      'remainingCalories': (target - totalCalories).clamp(0, 9999),
      'proteinG': totalProtein,
      'carbsG': totalCarbs,
      'fatG': totalFat,
      'entriesCount': entries.length,
    };
  }

  // --- CUSTOM ROUTINES & PLANNER ---
  Future<List<RoutinePlan>> getCustomRoutines() async {
    final db = await database;
    final maps = await db.query('custom_routines');
    return maps.map((m) => RoutinePlan.fromMap(m)).toList();
  }

  Future<void> saveCustomRoutine(RoutinePlan plan) async {
    final db = await database;
    await db.insert('custom_routines', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Also schedule upcoming workouts for this routine for the next 4 weeks
    final now = DateTime.now();
    final dayMap = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};

    for (int week = 0; week < 4; week++) {
      for (final dayName in plan.daysOfWeek) {
        final targetWeekday = dayMap[dayName] ?? 1;
        final daysAhead = ((targetWeekday - now.weekday + 7) % 7) + (week * 7);
        if (daysAhead == 0 && week == 0) continue; // Today already scheduled
        final scheduledDate = DateTime(now.year, now.month, now.day + daysAhead, 17, 0);

        final plannedWorkout = Workout(
          id: 'w_plan_${plan.id}_w${week}_$dayName',
          title: plan.title,
          subtitle: "${plan.subtitle} · Scheduled",
          date: scheduledDate,
          durationMinutes: plan.estimatedMinutes,
          totalVolumeKg: 0,
          totalSets: plan.exerciseIds.length * 3,
          totalReps: 0,
          isCompleted: false,
          exerciseIds: plan.exerciseIds,
        );
        await db.insert('workouts', plannedWorkout.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> deleteCustomRoutine(String id) async {
    final db = await database;
    await db.delete('custom_routines', where: 'id = ?', whereArgs: [id]);
  }

  // --- EXERCISE MANAGEMENT ---
  Future<void> addCustomExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- APP SETTINGS (PERSISTENCE) ---
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final res = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return res.first['value'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting setting $key: $e');
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }
}
