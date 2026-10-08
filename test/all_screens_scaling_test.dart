import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/screens/dashboard_screen.dart';
import 'package:kinetic/screens/calendar_screen.dart';
import 'package:kinetic/screens/food_tracker_screen.dart';
import 'package:kinetic/screens/analytics_screen.dart';
import 'package:kinetic/screens/daily_timeline_screen.dart';
import 'package:kinetic/screens/routine_builder_screen.dart';
import 'package:kinetic/screens/exercise_library_screen.dart';
import 'package:kinetic/screens/onboarding_screen.dart';
import 'package:kinetic/theme/app_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final viewports = [
    const Size(320, 568),
    const Size(360, 640),
  ];

  for (final vp in viewports) {
    group('Screen checks on ${vp.width}x${vp.height}', () {
      testWidgets('DashboardScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: Scaffold(body: DashboardScreen(onNavigateTab: (_) {}))));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('CalendarScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: CalendarScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('FoodTrackerScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: FoodTrackerScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('AnalyticsScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: AnalyticsScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('DailyTimelineScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: DailyTimelineScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('RoutineBuilderScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: RoutineBuilderScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('ExerciseLibraryScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: ExerciseLibraryScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('OnboardingScreen', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        await tester.pumpWidget(MaterialApp(theme: KineticTheme.darkTheme, home: const Scaffold(body: OnboardingScreen())));
        await tester.pump(const Duration(milliseconds: 300));
      });
    });
  }
}
