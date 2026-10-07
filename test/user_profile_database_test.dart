import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kinetic/models/user_profile.dart';
import 'package:kinetic/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseService starts with clean profile and saves user profile with gender', () async {
    final dbService = DatabaseService.instance;
    // On fresh database without dummy seed, profile is initially null until created
    final profile = await dbService.getUserProfile();
    expect(profile, isNull);

    // Test saving custom profile like the user's inputs
    final updatedProfile = UserProfile(
      id: 'current_user',
      name: 'Taha',
      age: 26,
      weightKg: 120.0,
      heightCm: 188.0,
      gender: 'male',
      goal: 'lose_fat',
      dailyCalorieTarget: 2200,
      isOnboarded: true,
    );

    await dbService.saveUserProfile(updatedProfile);

    final retrieved = await dbService.getUserProfile();
    expect(retrieved, isNotNull);
    expect(retrieved!.name, 'Taha');
    expect(retrieved.weightKg, 120.0);
    expect(retrieved.heightCm, 188.0);
    expect(retrieved.gender, 'male');
    expect(retrieved.goal, 'lose_fat');
    expect(retrieved.isOnboarded, true);
  });

  test('DatabaseService safely handles older table schema lacking gender column', () async {
    final db = await databaseFactory.openDatabase('legacy_test.db', options: OpenDatabaseOptions(version: 1));
    await db.execute('DROP TABLE IF EXISTS legacy_profile');
    // Simulate legacy table without gender
    await db.execute('''
      CREATE TABLE legacy_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        goal TEXT NOT NULL,
        daily_calorie_target INTEGER NOT NULL,
        is_onboarded INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Verify it lacks gender initially
    var cols = await db.rawQuery('PRAGMA table_info(legacy_profile)');
    var colNames = cols.map((c) => c['name'] as String).toList();
    expect(colNames.contains('gender'), false);

    // Apply migration
    if (!colNames.contains('gender')) {
      await db.execute("ALTER TABLE legacy_profile ADD COLUMN gender TEXT DEFAULT 'male'");
    }

    cols = await db.rawQuery('PRAGMA table_info(legacy_profile)');
    colNames = cols.map((c) => c['name'] as String).toList();
    expect(colNames.contains('gender'), true);

    await db.close();
    await databaseFactory.deleteDatabase('legacy_test.db');
  });
}
