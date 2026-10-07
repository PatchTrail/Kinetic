import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'active_workout_screen.dart';
import 'analytics_screen.dart';
import 'calendar_screen.dart';
import 'daily_timeline_screen.dart';
import 'dashboard_screen.dart';
import 'food_tracker_screen.dart';

import 'routine_builder_screen.dart';
import 'exercise_library_screen.dart';
import '../widgets/animated_dot_matrix_background.dart';
import '../widgets/welcome_tour_modal.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  final bool showWelcomeTour;
  const MainShell({Key? key, this.initialTab = 0, this.showWelcomeTour = false}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    KineticTheme.themeModeNotifier.addListener(_onThemeChanged);
    if (widget.showWelcomeTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          WelcomeTourModal.show(context);
        }
      });
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    KineticTheme.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = KineticTheme.isDarkMode;
    final themeKey = 'theme_${isDark ? "dark" : "light"}_${KineticTheme.currentMode.name}';
    final screens = [
      DashboardScreen(
        key: ValueKey('dash_$themeKey'),
        onNavigateTab: (idx) => setState(() => _currentTabIndex = idx),
      ),
      CalendarScreen(
        key: ValueKey('cal_$themeKey'),
      ),
      FoodTrackerScreen(
        key: ValueKey('food_$themeKey'),
      ),
      AnalyticsScreen(
        key: ValueKey('analytics_$themeKey'),
      ),
      DailyTimelineScreen(
        key: ValueKey('timeline_$themeKey'),
      ),
    ];

    return Scaffold(
      backgroundColor: KineticTheme.bgCanvas,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.digit1): () => setState(() => _currentTabIndex = 0),
          const SingleActivator(LogicalKeyboardKey.digit2): () => setState(() => _currentTabIndex = 1),
          const SingleActivator(LogicalKeyboardKey.digit3): () => setState(() => _currentTabIndex = 2),
          const SingleActivator(LogicalKeyboardKey.digit4): () => setState(() => _currentTabIndex = 3),
          const SingleActivator(LogicalKeyboardKey.digit5): () => setState(() => _currentTabIndex = 4),
          const SingleActivator(LogicalKeyboardKey.digit6): () async {
            final w = await DatabaseService.instance.getTodayWorkout();
            if (w != null && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(workout: w)));
            }
          },
          const SingleActivator(LogicalKeyboardKey.digit7): () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()));
          },
          const SingleActivator(LogicalKeyboardKey.digit8): () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()));
          },
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: KineticTheme.borderFaint, width: 1.0),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Animated Dot Matrix Lattice Wave
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedDotMatrixBackground(),
                      ),
                    ),

                    // Current Screen
                    IndexedStack(
                      key: ValueKey('indexed_stack_$themeKey'),
                      index: _currentTabIndex,
                      children: screens,
                    ),

                    // Floating Island Bottom Navigation Dock
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildFloatingDock(),
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

  Widget _buildFloatingDock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEB141720),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: KineticTheme.borderMedium, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockItem(
            index: 0,
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Workouts',
          ),
          _buildDockItem(
            index: 1,
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Calendar',
          ),
          _buildDockItem(
            index: 2,
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant_rounded,
            label: 'Nutrition',
          ),
          _buildDockItem(
            index: 3,
            icon: Icons.accessibility_new_outlined,
            activeIcon: Icons.accessibility_new_rounded,
            label: 'Anatomy',
          ),
          _buildDockItem(
            index: 4,
            icon: Icons.view_timeline_outlined,
            activeIcon: Icons.view_timeline_rounded,
            label: 'Protocol',
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? KineticTheme.accentFlame : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 19,
              color: isSelected ? Colors.black : const Color(0xFF94A3B8),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
