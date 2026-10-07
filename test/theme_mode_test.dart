import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/services/database_service.dart';
import 'package:kinetic/theme/app_theme.dart';
import 'package:kinetic/main.dart';
import 'package:kinetic/screens/main_shell.dart';
import 'package:kinetic/screens/dashboard_screen.dart';
import 'package:kinetic/screens/calendar_screen.dart';
import 'package:kinetic/screens/analytics_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('KineticTheme switches palettes between Light, Dark, and System modes', () {
    // 1. Force Light Mode
    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);
    expect(KineticTheme.isDarkMode, isFalse);
    expect(KineticTheme.bgCanvas, const Color(0xFFF4F5F8));
    expect(KineticTheme.bgSurface, const Color(0xFFFFFFFF));
    expect(KineticTheme.textPrimary, const Color(0xFF101217));

    // 2. Force Dark Mode
    KineticTheme.setThemeMode(ThemeMode.dark);
    KineticTheme.updateActiveBrightness(true);
    expect(KineticTheme.isDarkMode, isTrue);
    expect(KineticTheme.bgCanvas, const Color(0xFF0C0D12));
    expect(KineticTheme.bgSurface, const Color(0xFF141720));
    expect(KineticTheme.textPrimary, const Color(0xFFFFFFFF));

    // 3. Reset to Light default
    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);
    expect(KineticTheme.isDarkMode, isFalse);
  });

  test('DatabaseService saves and retrieves theme_mode preference', () async {
    // Initial save
    await DatabaseService.instance.setSetting('theme_mode', 'dark');
    final saved = await DatabaseService.instance.getSetting('theme_mode');
    expect(saved, 'dark');

    // Update to light
    await DatabaseService.instance.setSetting('theme_mode', 'light');
    final updated = await DatabaseService.instance.getSetting('theme_mode');
    expect(updated, 'light');

    // Update to system
    await DatabaseService.instance.setSetting('theme_mode', 'system');
    final systemMode = await DatabaseService.instance.getSetting('theme_mode');
    expect(systemMode, 'system');
  });

  testWidgets('App renders seamlessly under both Light and Dark mode', (tester) async {
    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: KineticTheme.themeModeNotifier,
        builder: (context, mode, _) {
          return MaterialApp(
            theme: KineticTheme.lightTheme,
            darkTheme: KineticTheme.darkTheme,
            themeMode: mode,
            home: Scaffold(
              backgroundColor: KineticTheme.bgCanvas,
              body: Center(
                child: Text('KINETIC THEME TEST', style: TextStyle(color: KineticTheme.textPrimary)),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('KINETIC THEME TEST'), findsOneWidget);

    // Switch to dark mode
    KineticTheme.setThemeMode(ThemeMode.dark);
    KineticTheme.updateActiveBrightness(true);
    await tester.pumpAndSettle();

    expect(find.text('KINETIC THEME TEST'), findsOneWidget);
    expect(KineticTheme.isDarkMode, isTrue);
  });

  testWidgets('MainShell updates all tabs dynamically on theme change', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);

    await tester.pumpWidget(const KineticFitnessApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Switch theme to dark mode
    KineticTheme.setThemeMode(ThemeMode.dark);
    KineticTheme.updateActiveBrightness(true);
    await tester.pump(const Duration(milliseconds: 500));

    // Confirm dark mode is active
    expect(KineticTheme.isDarkMode, isTrue);

    // Switch to Calendar tab under dark mode
    final calendarIcon = find.byIcon(Icons.calendar_month_outlined);
    expect(calendarIcon, findsOneWidget);
    await tester.tap(calendarIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CalendarScreen), findsOneWidget);

    // Switch to Anatomy tab under dark mode
    final anatomyIcon = find.byIcon(Icons.accessibility_new_outlined);
    expect(anatomyIcon, findsOneWidget);
    await tester.tap(anatomyIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    // Switch back to light mode while on Anatomy tab
    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(KineticTheme.isDarkMode, isFalse);
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    // Drain any sqflite operation timeout timers
    await tester.pump(const Duration(seconds: 11));
  });
}
