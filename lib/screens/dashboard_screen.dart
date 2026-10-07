import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../models/user_profile.dart';
import '../models/routine_plan.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/routine_number_badge.dart';
import '../widgets/three_month_dot_grid.dart';
import '../widgets/breathing_progress_bar.dart';
import 'active_workout_screen.dart';
import 'calendar_screen.dart';
import 'onboarding_screen.dart';
import 'food_tracker_screen.dart';
import 'routine_builder_screen.dart';
import 'exercise_library_screen.dart';
import '../widgets/field_manual_modal.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Workout? _todayWorkout;
  List<Workout> _pastWorkouts = [];
  Set<String> _completedDates = {};
  Map<String, dynamic> _stats = {};
  double _currentBodyweight = 82.3;
  UserProfile? _userProfile;
  Map<String, dynamic> _nutritionSummary = {};
  List<RoutinePlan> _customRoutines = [];
  Map<String, dynamic>? _volumeDelta;
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  bool _showAndroidMediaBanner = false;

  @override
  void initState() {
    super.initState();
    DatabaseService.dataChangeNotifier.addListener(_loadDashboardData);
    _loadDashboardData();
  }

  @override
  void dispose() {
    DatabaseService.dataChangeNotifier.removeListener(_loadDashboardData);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final today = await DatabaseService.instance.getTodayWorkout();
    final completedOnly = await DatabaseService.instance.getCompletedWorkouts();
    final completedDates = await DatabaseService.instance.getCompletedWorkoutDateStrings();
    final stats = await DatabaseService.instance.getOverallStats();
    final bw = await DatabaseService.instance.getLatestBodyweight();
    final profile = await DatabaseService.instance.getUserProfile();
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nutrition = await DatabaseService.instance.getDailyCalorieSummary(nowStr);
    final customRoutines = await DatabaseService.instance.getCustomRoutines();
    final volumeDelta = await DatabaseService.instance.getVolumeComparisonDelta();

    bool showMediaBanner = false;
    if (Platform.isAndroid) {
      final granted = await MediaService.instance.isAndroidPermissionGranted();
      showMediaBanner = !granted;
    }

    if (!mounted) return;
    setState(() {
      _todayWorkout = today;
      _pastWorkouts = completedOnly;
      _completedDates = completedDates;
      _stats = stats;
      _currentBodyweight = bw;
      _userProfile = profile;
      _nutritionSummary = nutrition;
      _customRoutines = customRoutines;
      _volumeDelta = volumeDelta;
      _showAndroidMediaBanner = showMediaBanner;
      _isLoading = false;
    });
  }

  void _startWorkout([Workout? workout]) {
    final w = workout ?? _todayWorkout;
    if (w == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(workout: w),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _startEmptyWorkout() async {
    final emptyWorkout = await DatabaseService.instance.createCustomWorkout(
      title: 'Quick Workout',
      subtitle: 'Ad-hoc session',
      exerciseIds: ['bench_press', 'weighted_pull_up'],
      estimatedMinutes: 45,
    );
    _startWorkout(emptyWorkout);
  }

  void _openCalendar() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarScreen()),
      ).then((_) => _loadDashboardData());
    }
  }

  void _showCreateWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KineticTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT WORKOUT ROUTINE',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: KineticTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...templates.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KineticTheme.bgSurfaceElevated,
                        foregroundColor: KineticTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: KineticTheme.borderFaint),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final newWorkout = await DatabaseService.instance.createCustomWorkout(
                          title: t['title'] as String,
                          subtitle: t['subtitle'] as String,
                          exerciseIds: t['exercises'] as List<String>,
                          estimatedMinutes: t['minutes'] as int,
                        );
                        _startWorkout(newWorkout);
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: KineticTheme.accentFlame.withOpacity(0.15),
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
                                  t['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${t['subtitle']} · ~${t['minutes']} min",
                                  style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: KineticTheme.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogBodyweightDialog() {
    double tempWeight = _currentBodyweight;
    final controller = TextEditingController(text: tempWeight.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: KineticTheme.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'LOG BODY WEIGHT',
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
              // Direct numeric text input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KineticTheme.accentFlame.withOpacity(0.5)),
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
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            tempWeight = parsed;
                          }
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

              // Quick Stepper Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [-1.0, -0.5, 0.5, 1.0].map((delta) {
                  final label = delta > 0 ? '+$delta' : '$delta';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempWeight = (tempWeight + delta).clamp(30.0, 250.0);
                          controller.text = tempWeight.toStringAsFixed(1);
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: TextStyle(color: KineticTheme.textTertiary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KineticTheme.accentFlame,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final val = double.tryParse(controller.text) ?? tempWeight;
                Navigator.pop(ctx);
                await DatabaseService.instance.logBodyweight(val);
                _loadDashboardData();
              },
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KineticTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DATA & BACKUP MANAGEMENT',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: KineticTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Theme Appearance Tile
                ListTile(
                  tileColor: KineticTheme.bgSurfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: KineticTheme.borderFaint),
                  ),
                  leading: const Icon(Icons.palette_outlined, color: KineticTheme.accentAmber),
                  title: Text('Appearance: ${KineticTheme.currentMode.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: KineticTheme.textPrimary)),
                  subtitle: Text('Switch between Light (Alabaster), Dark (Titanium), or System Auto', style: TextStyle(fontSize: 11, color: KineticTheme.textTertiary)),
                  trailing: Icon(Icons.chevron_right_rounded, color: KineticTheme.textSecondary, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showThemeModeSheet(context);
                  },
                ),
                const SizedBox(height: 10),

                // Export Button
                ListTile(
                  tileColor: KineticTheme.bgSurfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: KineticTheme.borderFaint),
                  ),
                  leading: const Icon(Icons.download_rounded, color: KineticTheme.accentFlame),
                  title: Text('Export Backup (.CSV)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: KineticTheme.textPrimary)),
                  subtitle: Text('Save all workouts, sets, meals & logs to file', style: TextStyle(fontSize: 11, color: KineticTheme.textTertiary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await ExcelService.instance.exportUserDataToSpreadsheet();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success ? KineticTheme.bgSurfaceElevated : Colors.redAccent,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Import Button
                ListTile(
                  tileColor: KineticTheme.bgSurfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: KineticTheme.borderFaint),
                  ),
                  leading: const Icon(Icons.upload_file_rounded, color: KineticTheme.accentJade),
                  title: Text('Import Backup (.CSV)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: KineticTheme.textPrimary)),
                  subtitle: Text('Restore or merge data from an exported spreadsheet', style: TextStyle(fontSize: 11, color: KineticTheme.textTertiary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final res = await ExcelService.instance.pickAndImportSpreadsheet();
                    if (!mounted) return;
                    _loadDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? KineticTheme.bgSurfaceElevated : Colors.orangeAccent,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Purge / Reset Button
                ListTile(
                  tileColor: Colors.red.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  title: const Text('Purge All Data (Reset)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.redAccent)),
                  subtitle: Text('Erase all workouts, meals, weights and start fresh', style: TextStyle(fontSize: 11, color: KineticTheme.textTertiary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPurgeConfirmDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeModeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KineticTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYSTEM APPEARANCE',
                      style: TextStyle(
                        color: KineticTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: KineticTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  ctx: ctx,
                  mode: ThemeMode.system,
                  title: 'SYSTEM DEFAULT (AUTO)',
                  subtitle: 'Automatically mirrors your Linux desktop or Android OS mode',
                  icon: Icons.brightness_auto_rounded,
                  iconColor: KineticTheme.accentCyan,
                ),
                const SizedBox(height: 10),
                _buildThemeOptionTile(
                  ctx: ctx,
                  mode: ThemeMode.light,
                  title: 'LIGHT OS (ALABASTER)',
                  subtitle: 'Pristine chalk/alabaster canvas with crisp dark typography',
                  icon: Icons.light_mode_rounded,
                  iconColor: KineticTheme.accentFlame,
                ),
                const SizedBox(height: 10),
                _buildThemeOptionTile(
                  ctx: ctx,
                  mode: ThemeMode.dark,
                  title: 'DARK OS (TITANIUM)',
                  subtitle: 'Stealth obsidian titanium canvas with glowing accents',
                  icon: Icons.dark_mode_rounded,
                  iconColor: KineticTheme.accentAmber,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext ctx,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = KineticTheme.currentMode == mode;
    return ListTile(
      tileColor: isSelected
          ? KineticTheme.accentFlame.withValues(alpha: 0.12)
          : KineticTheme.bgSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? KineticTheme.accentFlame : KineticTheme.borderFaint,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: KineticTheme.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 10, color: KineticTheme.textTertiary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: KineticTheme.accentFlame, size: 20)
          : null,
      onTap: () async {
        Navigator.pop(ctx);
        KineticTheme.setThemeMode(mode);
        await DatabaseService.instance.setSetting('theme_mode', mode.name);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme set to ${mode.name.toUpperCase()}'),
              backgroundColor: KineticTheme.bgSurfaceElevated,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showPurgeConfirmDialog() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: KineticTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'PURGE ALL APPLICATION DATA?',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'This will permanently delete all logged workouts, workout sets, custom routines, bodyweight history, food logs, and profile info.\n\nThe application will return to an initial fresh onboarding state.',
          style: TextStyle(color: KineticTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('CANCEL', style: TextStyle(color: KineticTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dCtx);
              await DatabaseService.instance.purgeAllUserData();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('PURGE EVERYTHING', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: KineticTheme.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: KineticTheme.accentFlame),
        ),
      );
    }

    final weeklyVol = (_stats['thisWeekVolumeKg'] as num?)?.toDouble() ?? 3200.0;
    // Format to match References/Workouts Screen.jpg ("3.200")
    final tonnageFormatted = weeklyVol >= 1000
        ? (weeklyVol / 1000.0).toStringAsFixed(3).substring(0, 5) // "3.200"
        : weeklyVol.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top App Bar (References/Workouts Screen.jpg)
              _buildTopHeader(),
              const SizedBox(height: 12),

              // Android Media Capsule Setup Banner (if Notification Access not yet granted)
              _buildAndroidMediaBanner(),

              // Dynamic Athlete Bio Profile Card
              _buildUserProfileCard(),
              const SizedBox(height: 14),

              // 2. Filter Category Pills (All, Push, Pull, Legs)
              _buildFilterChips(),
              const SizedBox(height: 14),

              // 3. Row of 2 Side-by-Side Cards (Chest + tricep & Body weight)
              _buildTopTwoCardsRow(),
              const SizedBox(height: 14),

              // 4. Middle Card: 3-Month Dot Matrix + Routine 2 (Back + bicep + legs)
              _buildMiddleConsistencyRoutineCard(),
              const SizedBox(height: 14),

              // Scheduled Routines & Custom Plans Section
              _buildCustomRoutinesSection(),
              const SizedBox(height: 14),

              // 5. Volume Lifted Horizontal Metric Card (References/Workouts Screen.jpg)
              _buildVolumeLiftedCard(tonnageFormatted),
              const SizedBox(height: 14),

              // Daily Ingestion & Nutrition Mini-HUD
              _buildNutritionMiniHudCard(),
              const SizedBox(height: 14),

              // 6. Quick Start Empty Workout Action Card
              _buildQuickStartCard(),
              const SizedBox(height: 18),

              // 7. Recent Logged Sessions Section
              _buildRecentWorkoutsSection(),
              const SizedBox(height: 90), // Bottom navigation dock clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidMediaBanner() {
    if (!Platform.isAndroid || !_showAndroidMediaBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KineticTheme.accentFlame.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KineticTheme.accentFlame.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note_rounded, color: KineticTheme.accentFlame, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENABLE MEDIA CAPSULE',
                  style: TextStyle(
                    color: KineticTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grant Notification Access to control Spotify & music apps during training.',
                  style: TextStyle(
                    color: KineticTheme.textSecondary,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: KineticTheme.accentFlame,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () async {
              await MediaService.instance.requestAndroidPermission();
              await Future.delayed(const Duration(milliseconds: 600));
              final granted = await MediaService.instance.isAndroidPermissionGranted();
              if (mounted) {
                setState(() => _showAndroidMediaBanner = !granted);
              }
            },
            child: const Text(
              'ENABLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, color: KineticTheme.textSecondary, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _showAndroidMediaBanner = false),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard() {
    final name = _userProfile?.name.toUpperCase() ?? 'ATHLETE';
    final goal = _userProfile?.goalLabel ?? 'HYPERTROPHY & MASS';
    final age = _userProfile?.age ?? 26;
    final height = _userProfile?.heightCm.toStringAsFixed(0) ?? '180';
    final targetKcal = _userProfile?.dailyCalorieTarget ?? 2982;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: KineticTheme.accentFlame.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: KineticTheme.accentFlame.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.person, color: KineticTheme.accentFlame, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KineticTheme.accentFlame.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              goal,
                              style: const TextStyle(
                                color: KineticTheme.accentFlame,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: KineticTheme.accentCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: KineticTheme.accentCyan.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Text(
                              (_userProfile?.gender ?? 'male').toUpperCase() == 'FEMALE' ? 'FEMALE ♀' : 'MALE ♂',
                              style: const TextStyle(
                                color: KineticTheme.accentCyan,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.fitness_center, size: 16, color: KineticTheme.textSecondary),
                    tooltip: 'Exercise Catalog',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnboardingScreen(isEditing: true, initialProfile: _userProfile),
                        ),
                      ).then((_) => _loadDashboardData());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KineticTheme.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: KineticTheme.borderMedium),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.edit_outlined, size: 12, color: KineticTheme.accentFlame),
                          SizedBox(width: 4),
                          Text(
                            'EDIT',
                            style: TextStyle(
                              color: KineticTheme.accentFlame,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _showDataManagementSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KineticTheme.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: KineticTheme.borderMedium),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.storage_rounded, size: 12, color: KineticTheme.accentJade),
                          SizedBox(width: 4),
                          Text(
                            'DATA',
                            style: TextStyle(
                              color: KineticTheme.accentJade,
                              fontSize: 9,
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
          ),
          const SizedBox(height: 12),
          Divider(color: KineticTheme.borderFaint, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStatMini('AGE', '$age', 'YRS'),
              _buildProfileStatMini('WEIGHT', _currentBodyweight.toStringAsFixed(1), 'KG'),
              _buildProfileStatMini('HEIGHT', height, 'CM'),
              _buildProfileStatMini('TARGET', '$targetKcal', 'KCAL'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatMini(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: KineticTheme.textTertiary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: KineticTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: KineticTheme.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionMiniHudCard() {
    final consumed = (_nutritionSummary['consumedCalories'] as num?)?.toInt() ?? 0;
    final target = (_nutritionSummary['targetCalories'] as num?)?.toInt() ?? (_userProfile?.dailyCalorieTarget ?? 2600);
    final remaining = (target - consumed).clamp(0, 9999);
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final protein = (_nutritionSummary['proteinG'] as num?)?.toDouble() ?? 0.0;
    final carbs = (_nutritionSummary['carbsG'] as num?)?.toDouble() ?? 0.0;
    final fat = (_nutritionSummary['fatG'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: KineticTheme.accentFlame.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: KineticTheme.accentFlame, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DAILY NUTRITION // INGESTION',
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackerScreen()))
                        .then((_) => _loadDashboardData());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: KineticTheme.accentFlame,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '+ LOG MEAL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$consumed',
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    ' / $target KCAL',
                    style: TextStyle(
                      color: KineticTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Text(
                '$remaining KCAL LEFT',
                style: const TextStyle(
                  color: KineticTheme.accentFlame,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BreathingProgressBar(
            value: ratio,
            height: 8,
            color: KineticTheme.accentFlame,
            backgroundColor: KineticTheme.bgSurfaceElevated,
            showStripes: true,
            showLeadingBeacon: true,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROTEIN: ${protein.toStringAsFixed(0)}G',
                style: const TextStyle(color: KineticTheme.accentCyan, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
              Text(
                'CARBS: ${carbs.toStringAsFixed(0)}G',
                style: const TextStyle(color: KineticTheme.accentEmerald, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
              Text(
                'FATS: ${fat.toStringAsFixed(0)}G',
                style: const TextStyle(color: KineticTheme.accentAmber, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRoutinesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: KineticTheme.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.event_repeat_rounded, color: KineticTheme.accentEmerald, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SCHEDULED ROUTINES & PLANS',
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
                  ).then((_) => _loadDashboardData());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: KineticTheme.accentEmerald,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '+ BUILD PLAN',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_customRoutines.isEmpty)
            Text(
              'No custom routines scheduled yet. Tap "+ BUILD PLAN" to create one and schedule to calendar.',
              style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
            )
          else
            ..._customRoutines.map((plan) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: KineticTheme.borderFaint),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: TextStyle(color: KineticTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${plan.daysOfWeek.join(" · ")}  ·  ⏰ ${plan.reminderTime}',
                                style: const TextStyle(color: KineticTheme.accentEmerald, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KineticTheme.bgSurfaceElevated,
                        foregroundColor: KineticTheme.accentFlame,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: KineticTheme.borderMedium),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final workout = await DatabaseService.instance.createCustomWorkout(
                          title: plan.title,
                          subtitle: plan.subtitle,
                          exerciseIds: plan.exerciseIds,
                          estimatedMinutes: plan.estimatedMinutes,
                        );
                        _startWorkout(workout);
                      },
                      child: const Text('START', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Workouts',
          style: TextStyle(
            color: KineticTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Row(
          children: [
            // Filter / Preferences Button
            IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: KineticTheme.borderMedium),
                ),
                child: Icon(Icons.tune_rounded, color: KineticTheme.textPrimary, size: 18),
              ),
              onPressed: () {
                // Cycle quick filter
                final categories = ['ALL', 'PUSH', 'PULL', 'LEGS'];
                final nextIdx = (categories.indexOf(_selectedCategory) + 1) % categories.length;
                setState(() => _selectedCategory = categories[nextIdx]);
              },
              tooltip: 'Filter Categories',
            ),
            // Theme Mode Switcher
            ValueListenableBuilder<ThemeMode>(
              valueListenable: KineticTheme.themeModeNotifier,
              builder: (context, mode, _) {
                IconData themeIcon;
                Color iconColor;
                if (mode == ThemeMode.dark) {
                  themeIcon = Icons.dark_mode_rounded;
                  iconColor = KineticTheme.accentAmber;
                } else if (mode == ThemeMode.light) {
                  themeIcon = Icons.light_mode_rounded;
                  iconColor = KineticTheme.accentFlame;
                } else {
                  themeIcon = Icons.brightness_auto_rounded;
                  iconColor = KineticTheme.accentCyan;
                }
                return IconButton(
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: KineticTheme.bgSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: KineticTheme.borderMedium),
                    ),
                    child: Icon(themeIcon, color: iconColor, size: 18),
                  ),
                  onPressed: () => _showThemeModeSheet(context),
                  tooltip: 'Appearance: ${mode.name.toUpperCase()}',
                );
              },
            ),
            IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: KineticTheme.borderMedium),
                ),
                child: const Icon(Icons.help_outline_rounded, color: KineticTheme.accentFlame, size: 18),
              ),
              onPressed: () => FieldManualModal.show(context),
              tooltip: 'Field Manual & Guide',
            ),
            const SizedBox(width: 8),
            // Add Routine / Start Session Button
            IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KineticTheme.bgSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: KineticTheme.borderMedium),
                ),
                child: Icon(Icons.add_rounded, color: KineticTheme.textPrimary, size: 22),
              ),
              onPressed: _showCreateWorkoutDialog,
              tooltip: 'New Routine',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final categories = ['ALL', 'PUSH', 'PULL', 'LEGS'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? KineticTheme.accentFlame : KineticTheme.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? KineticTheme.accentFlame : KineticTheme.borderMedium,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : KineticTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopTwoCardsRow() {
    final r1Title = _todayWorkout?.title ?? (_customRoutines.isNotEmpty ? _customRoutines.first.title : 'Start Routine');
    final r1Subtitle = _todayWorkout != null
        ? 'Today · ${_todayWorkout!.subtitle}'
        : (_customRoutines.isNotEmpty ? _customRoutines.first.subtitle : 'Choose or log a workout');
    final r1Progress = _todayWorkout != null && _todayWorkout!.totalSets > 0
        ? (_todayWorkout!.totalReps > 0 ? 1.0 : 0.0)
        : (_customRoutines.isNotEmpty ? 0.35 : 0.0);
    final weightStr = _currentBodyweight > 0 ? _currentBodyweight.toStringAsFixed(1) : '--';
    final weightSubtitle = _currentBodyweight > 0 ? 'Logged weight · Tap to update' : 'No entries · Tap to log';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Card: Routine 1
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_todayWorkout != null) {
                _startWorkout(_todayWorkout);
              } else if (_customRoutines.isNotEmpty) {
                final plan = _customRoutines.first;
                DatabaseService.instance.createCustomWorkout(
                  title: plan.title,
                  subtitle: plan.subtitle,
                  exerciseIds: plan.exerciseIds,
                  estimatedMinutes: plan.estimatedMinutes,
                ).then((w) => _startWorkout(w));
              } else {
                _showCreateWorkoutDialog();
              }
            },
            child: Container(
              height: 175,
              padding: const EdgeInsets.all(16),
              decoration: KineticTheme.cardDecoration(
                backgroundColor: KineticTheme.bgSurface,
                border: Border.all(color: KineticTheme.borderFaint),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoutineNumberBadge(number: 1, progress: r1Progress, size: 40),
                      IconButton(
                        icon: Icon(Icons.more_horiz_rounded, color: KineticTheme.textTertiary, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showCreateWorkoutDialog,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r1Title,
                        style: TextStyle(
                          color: KineticTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        r1Subtitle,
                        style: TextStyle(
                          color: KineticTheme.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KineticTheme.accentFlame.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: KineticTheme.accentFlame.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: KineticTheme.accentFlame, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'START',
                              style: TextStyle(
                                color: KineticTheme.accentFlame,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Card: Body weight
        Expanded(
          child: GestureDetector(
            onTap: _showLogBodyweightDialog,
            child: Container(
              height: 175,
              padding: const EdgeInsets.all(16),
              decoration: KineticTheme.cardDecoration(
                backgroundColor: KineticTheme.bgSurface,
                border: Border.all(color: KineticTheme.borderFaint),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KineticTheme.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.monitor_weight_outlined, size: 12, color: KineticTheme.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'WEIGHT',
                              style: TextStyle(color: KineticTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.tune_rounded, color: KineticTheme.textTertiary, size: 18),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            weightStr,
                            style: TextStyle(
                              color: KineticTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kg',
                            style: TextStyle(
                              color: KineticTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Body weight',
                        style: TextStyle(
                          color: KineticTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weightSubtitle,
                        style: TextStyle(
                          color: KineticTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleConsistencyRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consistency Dot Matrix Top Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONSISTENCY MATRIX',
                style: TextStyle(
                  color: KineticTheme.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: _openCalendar,
                child: const Row(
                  children: [
                    Text(
                      'OPEN CALENDAR',
                      style: TextStyle(
                        color: KineticTheme.accentFlame,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 9, color: KineticTheme.accentFlame),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ThreeMonthDotGrid(
            onTap: _openCalendar,
            completedDates: _completedDates,
          ),
          const SizedBox(height: 16),
          Divider(color: KineticTheme.borderFaint, height: 1),
          const SizedBox(height: 16),

          // Routine 2 Bottom Section
          Builder(
            builder: (context) {
              final hasSecond = _customRoutines.length > 1;
              final hasAny = _customRoutines.isNotEmpty;
              final r2Title = hasSecond
                  ? _customRoutines[1].title
                  : (hasAny ? _customRoutines.first.title : 'Plan a Routine');
              final r2Subtitle = hasSecond
                  ? '${_customRoutines[1].daysOfWeek.join(" · ")} · ${_customRoutines[1].subtitle}'
                  : (hasAny ? '${_customRoutines.first.daysOfWeek.join(" · ")} · ${_customRoutines.first.subtitle}' : 'Tap to set schedule & exercises');

              return GestureDetector(
                onTap: () {
                  if (hasSecond) {
                    final plan = _customRoutines[1];
                    DatabaseService.instance.createCustomWorkout(
                      title: plan.title,
                      subtitle: plan.subtitle,
                      exerciseIds: plan.exerciseIds,
                      estimatedMinutes: plan.estimatedMinutes,
                    ).then((w) => _startWorkout(w));
                  } else if (hasAny) {
                    final plan = _customRoutines.first;
                    DatabaseService.instance.createCustomWorkout(
                      title: plan.title,
                      subtitle: plan.subtitle,
                      exerciseIds: plan.exerciseIds,
                      estimatedMinutes: plan.estimatedMinutes,
                    ).then((w) => _startWorkout(w));
                  } else {
                    _showCreateWorkoutDialog();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    RoutineNumberBadge(number: 2, progress: hasSecond ? 0.55 : 0.0, size: 42, activeColor: const Color(0xFFFF9E00)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r2Title,
                            style: TextStyle(
                              color: KineticTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r2Subtitle,
                            style: TextStyle(
                              color: KineticTheme.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KineticTheme.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KineticTheme.borderFaint),
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: KineticTheme.textPrimary, size: 18),
                ),
              ],
            ),
          );
        },
      ),
    ],
  ),
);
  }

  Widget _buildVolumeLiftedCard(String tonnageDisplay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: KineticTheme.cardDecoration(
        backgroundColor: KineticTheme.bgSurface,
        border: Border.all(color: KineticTheme.borderFaint),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volume lifted',
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      color: KineticTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _volumeDelta != null ? _volumeDelta!['formatted'] as String : '-- vs last week',
                    style: TextStyle(
                      color: _volumeDelta != null && (_volumeDelta!['isPositive'] as bool)
                          ? KineticTheme.accentFlame
                          : KineticTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                tonnageDisplay,
                style: TextStyle(
                  color: KineticTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: TextStyle(
                  color: KineticTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.tune_rounded, color: KineticTheme.textTertiary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return GestureDetector(
      onTap: _startEmptyWorkout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KineticTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KineticTheme.borderMedium, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: KineticTheme.accentFlame.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: KineticTheme.accentFlame.withOpacity(0.4)),
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, color: KineticTheme.accentFlame, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Empty Session',
                    style: TextStyle(
                      color: KineticTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Log custom sets & exercises on the fly',
                    style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: KineticTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT LOGGED SESSIONS',
              style: TextStyle(
                color: KineticTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            if (_pastWorkouts.isNotEmpty)
              Text(
                'SWIPE LEFT TO DELETE',
                style: TextStyle(
                  color: KineticTheme.textTertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_pastWorkouts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.center,
            decoration: KineticTheme.cardDecoration(backgroundColor: KineticTheme.bgSurface),
            child: Column(
              children: [
                Icon(Icons.history_rounded, color: KineticTheme.textTertiary, size: 28),
                SizedBox(height: 6),
                Text(
                  'NO RECENT SESSIONS',
                  style: TextStyle(
                    color: KineticTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Completed workouts will appear here. Swipe left to remove unwanted logs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KineticTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ..._pastWorkouts.map((w) {
            final isDone = w.isCompleted;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey('workout_${w.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'DELETE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: KineticTheme.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'DELETE WORKOUT LOG?',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      content: Text(
                        'Permanently delete "${w.title}" (${w.subtitle})?\nThis session and its sets will be removed from your database and telemetry.',
                        style: TextStyle(color: KineticTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('CANCEL', style: TextStyle(color: KineticTheme.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (direction) async {
                  await DatabaseService.instance.deleteWorkout(w.id);
                  await _loadDashboardData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: KineticTheme.bgSurfaceElevated,
                        content: Text('Session "${w.title}" deleted', style: TextStyle(color: KineticTheme.textPrimary)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () => _startWorkout(w),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: KineticTheme.cardDecoration(
                      backgroundColor: KineticTheme.bgSurface,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDone ? KineticTheme.accentFlame.withValues(alpha: 0.12) : KineticTheme.bgSurfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone ? KineticTheme.accentFlame.withValues(alpha: 0.4) : KineticTheme.borderMedium,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              isDone ? Icons.check_rounded : Icons.play_arrow_rounded,
                              size: 16,
                              color: isDone ? KineticTheme.accentFlame : KineticTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.title,
                                style: TextStyle(
                                  color: KineticTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${w.subtitle} · ${w.durationMinutes} min',
                                style: TextStyle(
                                  color: KineticTheme.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${w.totalVolumeKg.toInt()} kg',
                              style: TextStyle(
                                color: KineticTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${w.totalSets} sets',
                              style: TextStyle(
                                color: KineticTheme.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
