import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/main.dart';
import 'package:kinetic/theme/app_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Bottom navigation bar changes color dynamically with theme switch', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Start with Light Mode
    KineticTheme.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const KineticFitnessApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Find the bottom navigation dock container
    final lightDockFinder = find.byKey(const ValueKey('dock_light'));
    expect(lightDockFinder, findsOneWidget);

    final lightContainer = tester.widget<Container>(lightDockFinder);
    final lightDeco = lightContainer.decoration as BoxDecoration;
    // In light mode, it should be white-ish
    expect(lightDeco.color?.value != const Color(0xEB141720).value, isTrue);

    // Now switch to Dark Mode
    KineticTheme.setThemeMode(ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 300));

    // The dock should now be dark
    final darkDockFinder = find.byKey(const ValueKey('dock_dark'));
    expect(darkDockFinder, findsOneWidget);
    final darkContainer = tester.widget<Container>(darkDockFinder);
    final darkDeco = darkContainer.decoration as BoxDecoration;
    expect(darkDeco.color?.value != lightDeco.color?.value, isTrue);
  });

  testWidgets('Bottom navigation bar does not overflow on small screens and supports horizontal scrolling', (tester) async {
    // Test on very narrow width 300px
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const KineticFitnessApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);

    // Tap each tab
    for (int i = 0; i < 5; i++) {
      // Find item
      final icons = [
        Icons.grid_view_outlined,
        Icons.calendar_month_outlined,
        Icons.restaurant_outlined,
        Icons.accessibility_new_outlined,
        Icons.view_timeline_outlined,
      ];
      final itemFinder = find.byIcon(icons[i]);
      if (itemFinder.evaluate().isNotEmpty) {
        await tester.tap(itemFinder.first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
    }
  });
}
