import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kinetic/models/muscle_group.dart';
import 'package:kinetic/models/workout.dart';
import 'package:kinetic/models/workout_set.dart';
import 'package:kinetic/services/database_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database telemetry starts at baseline zero and purges completely', () async {
    final db = DatabaseService.instance;

    // First purge to ensure clean state
    await db.purgeAllUserData();

    // Verify initial telemetry is 0
    final volumeBefore = await db.get7DayVolumePerMuscleGroup();
    final totalVolBefore = volumeBefore.values.fold(0.0, (a, b) => a + b);
    expect(totalVolBefore, equals(0.0));

    final fatigueBefore = await db.getRecentMuscleFatigueMap();
    final totalFatigueBefore = fatigueBefore.values.fold(0.0, (a, b) => a + b);
    expect(totalFatigueBefore, equals(0.0));

    final balanceBefore = await db.getBilateralBalanceScores();
    expect(balanceBefore['left'], equals(50));
    expect(balanceBefore['right'], equals(50));

    // Log a completed workout with completed sets
    final workout = Workout(
      id: 'w_dynamic_1',
      title: 'Leg Day Push',
      subtitle: 'Quad Focus',
      date: DateTime.now(),
      durationMinutes: 50,
      totalVolumeKg: 3000.0,
      totalSets: 3,
      totalReps: 30,
      isCompleted: true,
      notes: 'Testing volume calculation',
      exerciseIds: ['barbell_squat'],
    );
    await db.upsertWorkout(workout);

    final set1 = WorkoutSet(
      id: 's_dynamic_1',
      workoutId: 'w_dynamic_1',
      exerciseId: 'barbell_squat',
      setNumber: 1,
      weightKg: 100.0,
      reps: 10,
      isCompleted: true,
    );
    await db.saveSet(set1);

    // Verify volume now reflects the completed set
    final volumeAfter = await db.get7DayVolumePerMuscleGroup();
    expect(volumeAfter['Quadriceps'], isNotNull);
    expect(volumeAfter['Quadriceps']!, greaterThan(0.0));

    final fatigueAfter = await db.getRecentMuscleFatigueMap();
    expect(fatigueAfter[MuscleGroup.quads], greaterThan(0.0));

    // Now purge and verify it returns to zero
    await db.purgeAllUserData();

    final volumePurged = await db.get7DayVolumePerMuscleGroup();
    final totalVolPurged = volumePurged.values.fold(0.0, (a, b) => a + b);
    expect(totalVolPurged, equals(0.0));

    final fatiguePurged = await db.getRecentMuscleFatigueMap();
    final totalFatiguePurged = fatiguePurged.values.fold(0.0, (a, b) => a + b);
    expect(totalFatiguePurged, equals(0.0));

    final workoutsAfterPurge = await db.getWorkouts();
    expect(workoutsAfterPurge.isEmpty, isTrue);
  });

  test('deleteWorkout cascades and removes associated sets from database', () async {
    final db = DatabaseService.instance;
    await db.purgeAllUserData();

    final testWorkout = Workout(
      id: 'w_to_delete_1',
      title: 'Accidental Session',
      subtitle: 'Zero sets test',
      date: DateTime.now(),
      isCompleted: true,
      exerciseIds: ['bench_press'],
    );
    await db.upsertWorkout(testWorkout);

    final set = WorkoutSet(
      id: 'set_to_delete_1',
      workoutId: 'w_to_delete_1',
      exerciseId: 'bench_press',
      setNumber: 1,
      weightKg: 80.0,
      reps: 8,
      isCompleted: true,
    );
    await db.saveSet(set);

    final beforeSets = await db.getSetsForWorkout('w_to_delete_1');
    expect(beforeSets.length, equals(1));

    // Delete workout
    await db.deleteWorkout('w_to_delete_1');

    final afterWorkouts = await db.getWorkouts();
    expect(afterWorkouts.isEmpty, isTrue);

    final afterSets = await db.getSetsForWorkout('w_to_delete_1');
    expect(afterSets.isEmpty, isTrue);

    // Delta should be null when volume is empty
    final delta = await db.getVolumeComparisonDelta();
    expect(delta, isNull);
  });
}
