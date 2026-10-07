import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kinetic/services/database_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createCustomWorkout and quickLogCompletedWorkout respect target date and sync with calendar', () async {
    final db = DatabaseService.instance;
    await db.purgeAllUserData();

    // Target a specific date in the past
    final targetDate = DateTime(2026, 10, 4, 14, 30);
    final targetDateStr = '2026-10-04';

    // 1. Quick log completed workout for targetDate
    final loggedWorkout = await db.quickLogCompletedWorkout(
      title: 'Chest + tricep',
      subtitle: 'Push Hypertrophy',
      exerciseIds: ['bench_press', 'incline_db_press'],
      durationMinutes: 50,
      date: targetDate,
    );

    expect(loggedWorkout.isCompleted, isTrue);
    expect(loggedWorkout.date.year, equals(2026));
    expect(loggedWorkout.date.month, equals(10));
    expect(loggedWorkout.date.day, equals(4));
    expect(loggedWorkout.totalVolumeKg, greaterThan(0));
    expect(loggedWorkout.totalSets, greaterThan(0));

    // 2. Verify getWorkoutsForDay retrieves it
    final dayWorkouts = await db.getWorkoutsForDay(targetDate);
    expect(dayWorkouts.length, equals(1));
    expect(dayWorkouts.first.title, equals('Chest + tricep'));

    // 3. Verify calendar completed date strings include target date
    final completedDates = await db.getCompletedWorkoutDateStrings();
    expect(completedDates.contains(targetDateStr), isTrue);

    // 4. Test createCustomWorkout with explicit date
    final customDate = DateTime(2026, 10, 2);
    final customWorkout = await db.createCustomWorkout(
      title: 'Back + bicep',
      subtitle: 'Pull Strength',
      exerciseIds: ['weighted_pull_up'],
      estimatedMinutes: 45,
      date: customDate,
    );

    expect(customWorkout.date.year, equals(2026));
    expect(customWorkout.date.month, equals(10));
    expect(customWorkout.date.day, equals(2));
    final customDayWorkouts = await db.getWorkoutsForDay(customDate);
    expect(customDayWorkouts.length, equals(1));
    expect(customDayWorkouts.first.id, equals(customWorkout.id));
  });
}
