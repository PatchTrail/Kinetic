import 'package:flutter/material.dart';

/// Kinetic Design System - Precision High-Contrast Field OS
/// Supports Light OS (Alabaster Field), Dark OS (Stealth Titanium), and System Auto.
class KineticTheme {
  // Theme Mode State & Notifier
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  static bool _isDark = false;

  static bool get isDarkMode => _isDark;
  static ThemeMode get currentMode => themeModeNotifier.value;

  static void updateActiveBrightness(bool isDark) {
    _isDark = isDark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  // Pure Surface Colors - Adaptive Light / Dark
  // Light: Pristine chalk/alabaster canvas (Color Choices - 1)
  // Dark: Deep stealth obsidian canvas
  static Color get bgCanvas => _isDark ? const Color(0xFF0C0D12) : const Color(0xFFF4F5F8);

  // Light: Crisp stark white cards
  // Dark: Stealth titanium cards
  static Color get bgSurface => _isDark ? const Color(0xFF141720) : const Color(0xFFFFFFFF);

  // Light: Elevated pill/container
  // Dark: Elevated titanium container
  static Color get bgSurfaceElevated => _isDark ? const Color(0xFF1C202C) : const Color(0xFFEDF0F5);

  // Light: Hover / Highlight state
  // Dark: Elevated highlight state
  static Color get bgSurfaceHighlight => _isDark ? const Color(0xFF262C3D) : const Color(0xFFE2E6EE);

  // Inset secondary surface
  static Color get bgCardSubtle => _isDark ? const Color(0xFF181C26) : const Color(0xFFF8F9FB);

  // Border & Hairlines
  static Color get borderFaint => _isDark ? const Color(0xFF232736) : const Color(0xFFE2E5EB);
  static Color get borderMedium => _isDark ? const Color(0xFF32384A) : const Color(0xFFCBD2DE);
  static const Color borderActive = Color(0xFFFF451A);

  // Vibrant Accents (punchy, high-contrast, energetic in both modes)
  static const Color accentFlame = Color(0xFFFF451A); // Electric Vermilion (Color Choices - 1)
  static const Color accentAmber = Color(0xFFFF9E0B); // Radiant Amber
  static const Color accentJade = Color(0xFF00C875);  // Vibrant Mint / Jade Green (Color Choices - 3)
  static const Color accentEmerald = Color(0xFF00C875);
  static const Color accentCyan = Color(0xFF00B4D8);  // Electric Azure
  static const Color accentViolet = Color(0xFF8B5CF6); // Vivid Electric Purple
  static const Color accentCrimson = Color(0xFFEF4444);

  // Typography Colors - High Contrast Guaranteed!
  // Light: Pitch Obsidian
  // Dark: Pure White / Crisp Luminous Chalk
  static Color get textPrimary => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF101217);

  // Light: Clean Slate
  // Dark: Luminous Slate
  static Color get textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF555C6B);

  // Light: Subtle Graphite
  // Dark: Medium Slate
  static Color get textTertiary => _isDark ? const Color(0xFF64748B) : const Color(0xFF8A92A2);

  // Light: Muted Slate
  // Dark: Dark Slate
  static Color get textMonochromeMuted => _isDark ? const Color(0xFF475569) : const Color(0xFFBAC0CD);

  // Reusable Card BoxDecorations
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    Border? border,
    double borderRadius = 20.0,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? bgSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: borderFaint, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 3),
          blurRadius: 12,
        ),
        if (glow)
          BoxShadow(
            color: accentFlame.withValues(alpha: 0.22),
            offset: const Offset(0, 0),
            blurRadius: 20,
            spreadRadius: 2,
          ),
      ],
    );
  }

  // Segmented / Pill Decoration
  static BoxDecoration pillDecoration({
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? bgSurfaceElevated,
      borderRadius: BorderRadius.circular(100.0),
      border: Border.all(
        color: borderColor ?? borderMedium,
        width: 1.0,
      ),
    );
  }

  // ThemeData Definition - Modern High-Contrast Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F5F8),
      primaryColor: accentFlame,
      colorScheme: const ColorScheme.light(
        primary: accentFlame,
        secondary: accentJade,
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSurface: Color(0xFF101217),
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F5F8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF101217),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // ThemeData Definition - Modern Stealth Titanium Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0D12),
      primaryColor: accentFlame,
      colorScheme: const ColorScheme.dark(
        primary: accentFlame,
        secondary: accentJade,
        surface: Color(0xFF141720),
        onPrimary: Colors.white,
        onSurface: Color(0xFFFFFFFF),
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0C0D12),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class AppTheme {
  static Color get background => KineticTheme.bgCanvas;
  static Color get surfaceDark => KineticTheme.bgSurface;
  static Color get cardBackground => KineticTheme.bgSurfaceElevated;
  static Color get cardBorder => KineticTheme.borderMedium;
  static Color get divider => KineticTheme.borderFaint;
  static Color get textPrimary => KineticTheme.textPrimary;
  static Color get textSecondary => KineticTheme.textSecondary;
  static Color get textMuted => KineticTheme.textTertiary;
  static const Color accentOrange = KineticTheme.accentFlame;
  static const Color accentGreen = KineticTheme.accentJade;
}
