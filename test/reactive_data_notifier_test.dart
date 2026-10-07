import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kinetic/services/database_service.dart';
import 'package:kinetic/models/food_entry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  group('Reactive Data Notifier and Nutrition Sync Tests', () {
    test('dataChangeNotifier triggers on food logging, deleting, and purging', () async {
      final db = DatabaseService.instance;
      int notificationCount = 0;

      void listener() {
        notificationCount++;
      }

      DatabaseService.dataChangeNotifier.addListener(listener);

      // 1. Initial count
      final startCount = DatabaseService.dataChangeNotifier.value;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // 2. Add food entry
      final entry = FoodEntry(
        id: 'test_food_1',
        dateString: todayStr,
        mealType: 'Snack',
        foodName: 'Whey Protein',
        calories: 140,
        proteinG: 24,
        carbsG: 3,
        fatG: 2,
      );
      await db.addFoodEntry(entry);

      expect(DatabaseService.dataChangeNotifier.value, greaterThan(startCount));
      expect(notificationCount, greaterThanOrEqualTo(1));

      // Check daily calories is 140
      var summary = await db.getDailyCalorieSummary(todayStr);
      expect(summary['consumedCalories'], 140);
      expect(summary['proteinG'], 24.0);
      expect(summary['entriesCount'], 1);

      // 3. Delete food entry
      final countBeforeDelete = notificationCount;
      await db.deleteFoodEntry('test_food_1');

      expect(notificationCount, greaterThan(countBeforeDelete));

      // Check daily calories drops back to 0
      summary = await db.getDailyCalorieSummary(todayStr);
      expect(summary['consumedCalories'], 0);
      expect(summary['proteinG'], 0.0);
      expect(summary['entriesCount'], 0);

      // 4. Purge all user data
      final countBeforePurge = notificationCount;
      await db.purgeAllUserData();

      expect(notificationCount, greaterThan(countBeforePurge));

      DatabaseService.dataChangeNotifier.removeListener(listener);
    });
  });
}
