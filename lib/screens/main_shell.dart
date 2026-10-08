import 'dart:math' as math;
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
import '../widgets/floating_music_capsule.dart';
import '../services/media_service.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  final bool showWelcomeTour;
  const MainShell({Key? key, this.initialTab = 0, this.showWelcomeTour = false}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentTabIndex;
  final ScrollController _dockScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    KineticTheme.themeModeNotifier.addListener(_onThemeChanged);
    MediaService.instance.startListening();
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

  void _onSelectTab(int index) {
    setState(() => _currentTabIndex = index);
    DatabaseService.notifyDataChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dockScrollController.hasClients) {
        final maxScroll = _dockScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          final target = (index / 4.0) * maxScroll;
          _dockScrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _dockScrollController.dispose();
    KineticTheme.themeModeNotifier.removeListener(_onThemeChanged);
    MediaService.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = KineticTheme.isDarkMode;
    final themeKey = 'theme_${isDark ? "dark" : "light"}_${KineticTheme.currentMode.name}';
    final screens = [
      DashboardScreen(
        key: ValueKey('dash_$themeKey'),
        onNavigateTab: (idx) => _onSelectTab(idx),
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
          const SingleActivator(LogicalKeyboardKey.digit1): () => _onSelectTab(0),
          const SingleActivator(LogicalKeyboardKey.digit2): () => _onSelectTab(1),
          const SingleActivator(LogicalKeyboardKey.digit3): () => _onSelectTab(2),
          const SingleActivator(LogicalKeyboardKey.digit4): () => _onSelectTab(3),
          const SingleActivator(LogicalKeyboardKey.digit5): () => _onSelectTab(4),
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

                    // Floating Music Capsule (Dynamic pop-in when media plays)
                    Builder(
                      builder: (context) {
                        final bottomInset = MediaQuery.of(context).padding.bottom;
                        final capsuleBottom = math.max(bottomInset + 8.0, 16.0) + 62.0;
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: capsuleBottom),
                            child: FloatingMusicCapsule(key: ValueKey('capsule_$themeKey')),
                          ),
                        );
                      },
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
    final isDark = KineticTheme.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockBottomMargin = math.max(bottomInset + 8.0, 16.0);

    return Container(
      key: ValueKey('dock_${isDark ? "dark" : "light"}'),
      margin: EdgeInsets.only(
        bottom: dockBottomMargin,
        left: isNarrow ? 8 : 12,
        right: isNarrow ? 8 : 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141720) : const Color(0xFFFFFFFF)).withValues(alpha: isDark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF32384A) : const Color(0xFFCBD2DE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _dockScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildDockItem(
                    index: 0,
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Workouts',
                    isNarrow: isNarrow,
                    isDark: isDark,
                  ),
                  _buildDockItem(
                    index: 1,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    isNarrow: isNarrow,
                    isDark: isDark,
                  ),
                  _buildDockItem(
                    index: 2,
                    icon: Icons.restaurant_outlined,
                    activeIcon: Icons.restaurant_rounded,
                    label: 'Nutrition',
                    isNarrow: isNarrow,
                    isDark: isDark,
                  ),
                  _buildDockItem(
                    index: 3,
                    icon: Icons.accessibility_new_outlined,
                    activeIcon: Icons.accessibility_new_rounded,
                    label: 'Anatomy',
                    isNarrow: isNarrow,
                    isDark: isDark,
                  ),
                  _buildDockItem(
                    index: 4,
                    icon: Icons.view_timeline_outlined,
                    activeIcon: Icons.view_timeline_rounded,
                    label: 'Protocol',
                    isNarrow: isNarrow,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isNarrow,
    required bool isDark,
  }) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => _onSelectTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isNarrow ? 9 : 12) : (isNarrow ? 6 : 8),
          vertical: isNarrow ? 6 : 8,
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
              size: isNarrow ? 17 : 19,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            if (isSelected) ...[
              SizedBox(width: isNarrow ? 4 : 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 9 : 10,
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
