import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kinetic/models/workout.dart';
import 'package:kinetic/models/workout_set.dart';
import 'package:kinetic/services/database_service.dart';
import 'package:kinetic/services/excel_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database seeds default exercises and starts clean without dummy workouts', () async {
    final exercises = await DatabaseService.instance.getExercises();
    expect(exercises.isNotEmpty, isTrue);

    // Initial workouts start empty
    final initialWorkouts = await DatabaseService.instance.getWorkouts();
    expect(initialWorkouts.isEmpty, isTrue);
  });

  test('Logging workouts and sets allows accurate export and import round-trip', () async {
    final db = DatabaseService.instance;

    // Log a sample test session
    final testWorkout = Workout(
      id: 'w_test_1',
      title: 'Strength Test',
      subtitle: 'Chest & Arms',
      date: DateTime.now(),
      durationMinutes: 45,
      totalVolumeKg: 1200.0,
      totalSets: 3,
      totalReps: 24,
      isCompleted: true,
      notes: 'Clean test session',
      exerciseIds: ['bench_press'],
    );
    await db.upsertWorkout(testWorkout);

    final testSet = WorkoutSet(
      id: 's_test_1',
      workoutId: 'w_test_1',
      exerciseId: 'bench_press',
      setNumber: 1,
      weightKg: 80.0,
      reps: 8,
      isCompleted: true,
    );
    await db.upsertWorkoutSet(testSet);

    // Verify stats and performance
    final prev = await db.getLastCompletedSetForExercise('bench_press');
    expect(prev, isNotNull);
    expect(prev!.weightKg, equals(80.0));

    // Export to spreadsheet
    final exportResult = await ExcelService.instance.exportUserDataToSpreadsheet();
    expect(exportResult.success, isTrue);
    expect(exportResult.filePath.isNotEmpty, isTrue);
    expect(exportResult.filePath.endsWith('.csv'), isTrue);

    // Purge data
    await db.purgeAllUserData();
    final afterPurgeWorkouts = await db.getWorkouts();
    expect(afterPurgeWorkouts.isEmpty, isTrue);

    // Exercises are preserved even after purge
    final exercises = await db.getExercises();
    expect(exercises.isNotEmpty, isTrue);

    // Test Import from CSV content
    const sampleCsv = '''# === KINETIC FITNESS ARCHIVE ===
--- WORKOUT SESSIONS ---
ID,Date,Title,Subtitle,Duration(min),TotalVolume(kg),TotalSets,TotalReps,Completed,Notes,ExerciseIds
"w_imported_1","2026-10-06T12:00:00.000","Imported Power","Chest + Legs",50,1500.0,4,30,YES,"Imported notes","bench_press;barbell_squat"

--- WORKOUT SETS DETAIL ---
SetID,WorkoutID,ExerciseID,SetNumber,Weight(kg),Reps,Completed,RPE,CompletedAt
"set_imp_1","w_imported_1","bench_press",1,85.0,8,YES,8.5,"2026-10-06T12:15:00.000"

--- BODYWEIGHT PROGRESSION ---
ID,Date,Weight(kg),Notes
"bw_imp_1","2026-10-06T08:00:00.000",83.5,"Morning weigh-in"
''';

    final importResult = await ExcelService.instance.importUserDataFromSpreadsheet(sampleCsv);
    expect(importResult.success, isTrue);
    expect(importResult.workoutsImported, equals(1));
    expect(importResult.setsImported, equals(1));
    expect(importResult.bodyweightImported, equals(1));

    final restoredWorkouts = await db.getWorkouts();
    expect(restoredWorkouts.length, equals(1));
    expect(restoredWorkouts.first.title, equals('Imported Power'));

    final restoredBw = await db.getBodyweightEntries();
    expect(restoredBw.length, equals(1));
    expect(restoredBw.first.weightKg, equals(83.5));
  });
}
