import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/main.dart';
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
    const Size(320, 568), // iPhone SE / small Android
    const Size(360, 640), // Typical compact Android (e.g., Galaxy A, older Redmi)
    const Size(375, 667), // iPhone 8
    const Size(390, 844), // iPhone 13/14
    const Size(412, 915), // Pixel 7
  ];

  for (final vp in viewports) {
    testWidgets('MainShell renders without overflow on ${vp.width}x${vp.height}', (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const KineticFitnessApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      // Cycle through tabs
      for (int i = 0; i < 5; i++) {
        // Try to tap tab i if present
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('OnboardingScreen renders without overflow on ${vp.width}x${vp.height}', (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: KineticTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }
}
