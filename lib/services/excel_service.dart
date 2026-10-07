import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../models/user_profile.dart';
import '../models/food_entry.dart';
import '../models/daily_routine_item.dart';
import '../models/routine_plan.dart';
import '../models/bodyweight_entry.dart';

class ExcelExportResult {
  final bool success;
  final String filePath;
  final String message;

  ExcelExportResult({
    required this.success,
    required this.filePath,
    required this.message,
  });
}

class ExcelImportResult {
  final bool success;
  final int workoutsImported;
  final int setsImported;
  final int bodyweightImported;
  final int foodsImported;
  final int routinesImported;
  final int timelineImported;
  final bool profileUpdated;
  final String message;

  ExcelImportResult({
    required this.success,
    this.workoutsImported = 0,
    this.setsImported = 0,
    this.bodyweightImported = 0,
    this.foodsImported = 0,
    this.routinesImported = 0,
    this.timelineImported = 0,
    this.profileUpdated = false,
    required this.message,
  });

  int get totalRecords =>
      workoutsImported +
      setsImported +
      bodyweightImported +
      foodsImported +
      routinesImported +
      timelineImported +
      (profileUpdated ? 1 : 0);
}

class ExcelService {
  static final ExcelService instance = ExcelService._internal();
  ExcelService._internal();

  /// Exports all workout, set, routine, nutrition, timeline, and bodyweight data to standard CSV
  /// spreadsheets formatted for easy backup, cross-device transfer, or import into Excel / Google Sheets.
  Future<ExcelExportResult> exportUserDataToSpreadsheet() async {
    try {
      final db = DatabaseService.instance;
      final profile = await db.getUserProfile();
      final workouts = await db.getWorkouts();
      final bodyweight = await db.getBodyweightEntries();
      final foods = await db.getAllFoodEntries();
      final customRoutines = await db.getCustomRoutines();
      final dailyRoutines = await db.getAllDailyRoutines();

      // Find user Documents or Downloads directory
      Directory? targetDir;
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        targetDir = Directory.systemTemp;
      } else {
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Kinetic_Fitness_Data_$timestamp.csv';
      final file = File(p.join(targetDir.path, fileName));

      final buffer = StringBuffer();

      // File Header
      buffer.writeln('# === KINETIC FITNESS ARCHIVE ===');
      buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
      buffer.writeln('# Format: Standard CSV compatible with Kinetic Import / Excel / Sheets');
      buffer.writeln('');

      // Section 1: USER PROFILE
      buffer.writeln('--- USER PROFILE ---');
      buffer.writeln('ID,Name,Age,WeightKg,HeightCm,Gender,Goal,DailyCalorieTarget,IsOnboarded');
      if (profile != null) {
        buffer.writeln(
          '"${profile.id}","${_escape(profile.name)}",${profile.age},${profile.weightKg},'
          '${profile.heightCm},"${_escape(profile.gender)}","${_escape(profile.goal)}",'
          '${profile.dailyCalorieTarget},${profile.isOnboarded ? "YES" : "NO"}',
        );
      }
      buffer.writeln('');

      // Section 2: WORKOUT SESSIONS
      buffer.writeln('--- WORKOUT SESSIONS ---');
      buffer.writeln('ID,Date,Title,Subtitle,Duration(min),TotalVolume(kg),TotalSets,TotalReps,Completed,Notes,ExerciseIds');
      for (final w in workouts) {
        final exerciseIdsStr = w.exerciseIds.join(';');
        buffer.writeln(
          '"${w.id}","${w.date.toIso8601String()}","${_escape(w.title)}","${_escape(w.subtitle)}",'
          '${w.durationMinutes},${w.totalVolumeKg},${w.totalSets},${w.totalReps},'
          '${w.isCompleted ? "YES" : "NO"},"${_escape(w.notes)}","${_escape(exerciseIdsStr)}"',
        );
      }
      buffer.writeln('');

      // Section 3: WORKOUT SETS DETAIL
      buffer.writeln('--- WORKOUT SETS DETAIL ---');
      buffer.writeln('SetID,WorkoutID,ExerciseID,SetNumber,Weight(kg),Reps,Completed,RPE,CompletedAt');
      for (final w in workouts) {
        final sets = await db.getSetsForWorkout(w.id);
        for (final s in sets) {
          buffer.writeln(
            '"${s.id}","${s.workoutId}","${s.exerciseId}",${s.setNumber},'
            '${s.weightKg},${s.reps},${s.isCompleted ? "YES" : "NO"},${s.rpe},'
            '"${s.completedAt?.toIso8601String() ?? ""}"',
          );
        }
      }
      buffer.writeln('');

      // Section 4: BODYWEIGHT PROGRESSION
      buffer.writeln('--- BODYWEIGHT PROGRESSION ---');
      buffer.writeln('ID,Date,Weight(kg),Notes');
      for (final bw in bodyweight) {
        buffer.writeln(
          '"${bw.id}","${bw.date.toIso8601String()}",${bw.weightKg},"${_escape(bw.notes)}"',
        );
      }
      buffer.writeln('');

      // Section 5: NUTRITION FOOD LOGS
      buffer.writeln('--- NUTRITION FOOD LOGS ---');
      buffer.writeln('ID,DateString,MealType,FoodName,Calories,Protein(g),Carbs(g),Fat(g),LoggedAt');
      for (final f in foods) {
        buffer.writeln(
          '"${f.id}","${f.dateString}","${_escape(f.mealType)}","${_escape(f.foodName)}",'
          '${f.calories},${f.proteinG},${f.carbsG},${f.fatG},"${f.loggedAt.toIso8601String()}"',
        );
      }
      buffer.writeln('');

      // Section 6: CUSTOM ROUTINES
      buffer.writeln('--- CUSTOM ROUTINES ---');
      buffer.writeln('ID,Title,Subtitle,DaysOfWeek,ExerciseIds,EstimatedMinutes,ReminderTime,ReminderEnabled');
      for (final r in customRoutines) {
        final daysStr = r.daysOfWeek.join(';');
        final exStr = r.exerciseIds.join(';');
        buffer.writeln(
          '"${r.id}","${_escape(r.title)}","${_escape(r.subtitle)}","${_escape(daysStr)}",'
          '"${_escape(exStr)}",${r.estimatedMinutes},"${r.reminderTime}",'
          '${r.reminderEnabled ? "YES" : "NO"}',
        );
      }
      buffer.writeln('');

      // Section 7: DAILY PROTOCOL TIMELINE
      buffer.writeln('--- DAILY PROTOCOL TIMELINE ---');
      buffer.writeln('ID,DateString,Time,Title,Subtitle,Category,IconKey,ColorValue,IsCompleted,Protein(g),Carbs(g),Fat(g),Calories');
      for (final item in dailyRoutines) {
        buffer.writeln(
          '"${item.id}","${item.dateString}","${item.time}","${_escape(item.title)}",'
          '"${_escape(item.subtitle)}","${item.category}","${item.iconKey}",'
          '${item.colorValue},${item.isCompleted ? "YES" : "NO"},${item.macroProteinG},'
          '${item.macroCarbsG},${item.macroFatG},${item.calories}',
        );
      }

      await file.writeAsString(buffer.toString());

      return ExcelExportResult(
        success: true,
        filePath: file.path,
        message: 'Successfully exported ${workouts.length} workouts, ${bodyweight.length} weight entries, ${foods.length} food logs to:\n${file.path}',
      );
    } catch (e) {
      return ExcelExportResult(
        success: false,
        filePath: '',
        message: 'Export failed: $e',
      );
    }
  }

  /// Opens file picker to choose a CSV backup and ingests all records into SQLite,
  /// updating / overwriting existing entries while preserving untouched records.
  Future<ExcelImportResult> pickAndImportSpreadsheet() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result.isEmpty) {
        return ExcelImportResult(
          success: false,
          message: 'No file selected.',
        );
      }

      final fileObj = result.first;
      final content = await fileObj.xFile.readAsString();

      if (content.trim().isEmpty) {
        return ExcelImportResult(
          success: false,
          message: 'Selected file is empty.',
        );
      }

      return await importUserDataFromSpreadsheet(content);
    } catch (e) {
      return ExcelImportResult(
        success: false,
        message: 'Import failed: $e',
      );
    }
  }

  /// Ingests CSV content into SQLite, upserting data by primary ID and preserving existing records.
  Future<ExcelImportResult> importUserDataFromSpreadsheet(String fileContent) async {
    final lines = fileContent.split('\n');
    final db = DatabaseService.instance;

    int workoutsImported = 0;
    int setsImported = 0;
    int bodyweightImported = 0;
    int foodsImported = 0;
    int routinesImported = 0;
    int timelineImported = 0;
    bool profileUpdated = false;

    String currentSection = '';

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.contains('--- USER PROFILE ---')) {
        currentSection = 'profile';
        continue;
      } else if (line.contains('--- WORKOUT SESSIONS ---')) {
        currentSection = 'workouts';
        continue;
      } else if (line.contains('--- WORKOUT SETS DETAIL ---')) {
        currentSection = 'sets';
        continue;
      } else if (line.contains('--- BODYWEIGHT PROGRESSION ---')) {
        currentSection = 'bodyweight';
        continue;
      } else if (line.contains('--- NUTRITION FOOD LOGS ---')) {
        currentSection = 'foods';
        continue;
      } else if (line.contains('--- CUSTOM ROUTINES ---')) {
        currentSection = 'routines';
        continue;
      } else if (line.contains('--- DAILY PROTOCOL TIMELINE ---')) {
        currentSection = 'timeline';
        continue;
      }

      // Skip table header lines
      if (line.startsWith('ID,') ||
          line.startsWith('SetID,') ||
          line.startsWith('Date,') ||
          line.startsWith('MealType,')) {
        continue;
      }

      final cols = _parseCsvLine(line);
      if (cols.isEmpty) continue;

      try {
        switch (currentSection) {
          case 'profile':
            if (cols.length >= 8) {
              final profile = UserProfile(
                id: cols[0].isEmpty ? 'current_user' : cols[0],
                name: cols[1],
                age: int.tryParse(cols[2]) ?? 26,
                weightKg: double.tryParse(cols[3]) ?? 80.0,
                heightCm: double.tryParse(cols[4]) ?? 180.0,
                gender: cols.length > 5 ? cols[5] : 'male',
                goal: cols.length > 6 ? cols[6] : 'maintain',
                dailyCalorieTarget: cols.length > 7 ? (int.tryParse(cols[7]) ?? 2500) : 2500,
                isOnboarded: cols.length > 8 ? (cols[8].toUpperCase() == 'YES' || cols[8] == '1') : true,
              );
              await db.saveUserProfile(profile);
              profileUpdated = true;
            }
            break;

          case 'workouts':
            if (cols.length >= 9) {
              final exIds = cols.length > 10 && cols[10].isNotEmpty
                  ? cols[10].split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                  : <String>[];
              final workout = Workout(
                id: cols[0],
                date: DateTime.tryParse(cols[1]) ?? DateTime.now(),
                title: cols[2],
                subtitle: cols[3],
                durationMinutes: int.tryParse(cols[4]) ?? 45,
                totalVolumeKg: double.tryParse(cols[5]) ?? 0.0,
                totalSets: int.tryParse(cols[6]) ?? 0,
                totalReps: int.tryParse(cols[7]) ?? 0,
                isCompleted: cols[8].toUpperCase() == 'YES' || cols[8] == '1',
                notes: cols.length > 9 ? cols[9] : '',
                exerciseIds: exIds,
              );
              await db.upsertWorkout(workout);
              workoutsImported++;
            }
            break;

          case 'sets':
            if (cols.length >= 7) {
              final set = WorkoutSet(
                id: cols[0],
                workoutId: cols[1],
                exerciseId: cols[2],
                setNumber: int.tryParse(cols[3]) ?? 1,
                weightKg: double.tryParse(cols[4]) ?? 0.0,
                reps: int.tryParse(cols[5]) ?? 0,
                isCompleted: cols[6].toUpperCase() == 'YES' || cols[6] == '1',
                rpe: cols.length > 7 ? (double.tryParse(cols[7]) ?? 8.0) : 8.0,
                completedAt: cols.length > 8 && cols[8].isNotEmpty ? DateTime.tryParse(cols[8]) : null,
              );
              await db.upsertWorkoutSet(set);
              setsImported++;
            }
            break;

          case 'bodyweight':
            if (cols.length >= 3) {
              final entry = BodyweightEntry(
                id: cols[0],
                date: DateTime.tryParse(cols[1]) ?? DateTime.now(),
                weightKg: double.tryParse(cols[2]) ?? 80.0,
                notes: cols.length > 3 ? cols[3] : '',
              );
              await db.upsertBodyweightEntry(entry);
              bodyweightImported++;
            }
            break;

          case 'foods':
            if (cols.length >= 8) {
              final food = FoodEntry(
                id: cols[0],
                dateString: cols[1],
                mealType: cols[2],
                foodName: cols[3],
                calories: int.tryParse(cols[4]) ?? 0,
                proteinG: double.tryParse(cols[5]) ?? 0.0,
                carbsG: double.tryParse(cols[6]) ?? 0.0,
                fatG: double.tryParse(cols[7]) ?? 0.0,
                loggedAt: cols.length > 8 && cols[8].isNotEmpty
                    ? (DateTime.tryParse(cols[8]) ?? DateTime.now())
                    : DateTime.now(),
              );
              await db.upsertFoodEntry(food);
              foodsImported++;
            }
            break;

          case 'routines':
            if (cols.length >= 6) {
              final days = cols[3].split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              final exIds = cols[4].split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              final plan = RoutinePlan(
                id: cols[0],
                title: cols[1],
                subtitle: cols[2],
                daysOfWeek: days,
                exerciseIds: exIds,
                estimatedMinutes: int.tryParse(cols[5]) ?? 60,
                reminderTime: cols.length > 6 && cols[6].isNotEmpty ? cols[6] : '07:00',
                reminderEnabled: cols.length > 7 ? (cols[7].toUpperCase() == 'YES' || cols[7] == '1') : false,
              );
              await db.upsertCustomRoutine(plan);
              routinesImported++;
            }
            break;

          case 'timeline':
            if (cols.length >= 9) {
              final item = DailyRoutineItem(
                id: cols[0],
                dateString: cols[1],
                time: cols[2],
                title: cols[3],
                subtitle: cols[4],
                category: cols[5],
                iconKey: cols[6],
                colorValue: int.tryParse(cols[7]) ?? 0xFF00E5FF,
                isCompleted: cols[8].toUpperCase() == 'YES' || cols[8] == '1',
                macroProteinG: cols.length > 9 ? double.tryParse(cols[9]) : null,
                macroCarbsG: cols.length > 10 ? double.tryParse(cols[10]) : null,
                macroFatG: cols.length > 11 ? double.tryParse(cols[11]) : null,
                calories: cols.length > 12 ? int.tryParse(cols[12]) : null,
              );
              await db.upsertDailyRoutineItem(item);
              timelineImported++;
            }
            break;
        }
      } catch (err) {
        // Continue processing other rows even if one line has bad syntax
      }
    }

    final total = workoutsImported +
        setsImported +
        bodyweightImported +
        foodsImported +
        routinesImported +
        timelineImported +
        (profileUpdated ? 1 : 0);

    return ExcelImportResult(
      success: total > 0,
      workoutsImported: workoutsImported,
      setsImported: setsImported,
      bodyweightImported: bodyweightImported,
      foodsImported: foodsImported,
      routinesImported: routinesImported,
      timelineImported: timelineImported,
      profileUpdated: profileUpdated,
      message: total > 0
          ? 'Import complete: $workoutsImported workouts, $setsImported sets, $bodyweightImported weight logs, $foodsImported meals, $routinesImported routines.'
          : 'No valid records found in the imported file.',
    );
  }

  static String _escape(String str) {
    return str.replaceAll('"', '""');
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    final StringBuffer sb = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }
}
