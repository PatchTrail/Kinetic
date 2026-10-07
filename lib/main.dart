import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:ui';
import 'models/user_profile.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI on desktop platforms (Linux, macOS, Windows)
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  bool isOnboarded = false;
  UserProfile? initialProfile;
  try {
    final profile = await DatabaseService.instance.getUserProfile();
    initialProfile = profile;
    isOnboarded = profile != null && profile.isOnboarded;
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  // Load persisted theme mode setting
  try {
    final savedMode = await DatabaseService.instance.getSetting('theme_mode');
    if (savedMode == 'dark') {
      KineticTheme.setThemeMode(ThemeMode.dark);
    } else if (savedMode == 'light') {
      KineticTheme.setThemeMode(ThemeMode.light);
    } else {
      KineticTheme.setThemeMode(ThemeMode.system);
    }
  } catch (e) {
    debugPrint('Theme setting load notice: $e');
  }

  runApp(KineticFitnessApp(initialOnboarded: isOnboarded, initialProfile: initialProfile));
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class KineticFitnessApp extends StatelessWidget {
  final bool initialOnboarded;
  final UserProfile? initialProfile;
  const KineticFitnessApp({Key? key, this.initialOnboarded = true, this.initialProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: KineticTheme.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'KINETIC // FITNESS OS',
          debugShowCheckedModeBanner: false,
          theme: KineticTheme.lightTheme,
          darkTheme: KineticTheme.darkTheme,
          themeMode: currentMode,
          scrollBehavior: AppScrollBehavior(),
          builder: (context, child) {
            final brightness = MediaQuery.platformBrightnessOf(context);
            final isDark = currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system && brightness == Brightness.dark);
            KineticTheme.updateActiveBrightness(isDark);
            return child!;
          },
          home: initialOnboarded ? const MainShell() : OnboardingScreen(initialProfile: initialProfile),
        );
      },
    );
  }
}
