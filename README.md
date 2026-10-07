# KINETIC // FITNESS OS

> High-performance, cyber-tactical biometric training and nutrition operating system built with Flutter. 100% offline, privacy-first, zero cloud dependencies.

---

## Overview

**Kinetic** is an industrial-minimalist fitness and health telemetry platform engineered for athletes who demand friction-free logging, deterministic precision, and deep biomechanical insights. Designed with a cyber-tactical visual aesthetic, Kinetic treats physical training, circadian habits, and nutrition as mission-critical systems.

---

## Core Systems & Features

### 1. Dynamic 3D Biomechanical Muscle Heatmap
- **Anatomical Mapping**: Renders anterior (front) and posterior (back) muscular anatomy with sex-specific baseline models (Male & Female).
- **Fatigue Telemetry**: Dynamic multi-tier color coding based on recorded training volume and recovery windows:
  - Fresh / Recovered (`#10B981` Emerald)
  - Moderate Load (`#F59E0B` Amber)
  - Severe Fatigue / Peak Stimulus (`#FF3B30` Kinetic Crimson)
- **Direct Muscle Target Selector**: Tap any muscle group (Chest, Lats, Quads, Deltoids, Hamstrings, Core, Arms, Calves) to inspect logged volume and instantly filter exercise protocols.

### 2. High-Friction-Free Workout Engine
- **Active Workout HUD**: Real-time rest timer with tactical audio alert controls, live set completion tracking, and automatic target progression.
- **Interactive Sets Table**: Micro-adjusted reps, RPE (Rate of Perceived Exertion), weight, and previous best reference indicators.
- **Exercise Field Manuals**: Embedded movement execution guides, biomechanical cues, and primary/secondary muscle recruitment maps.
- **Custom Routine Architect**: Build multi-exercise protocols with configurable rest timers, target rep ranges, and session cadence.
- **Deletable Telemetry**: Swipe-to-reveal purge mechanism with cascading database cleanup for accidental entries.

### 3. Food & Macronutrient Tracker
- **Caloric & Macro Budgeting**: Dynamic split tracking for Protein, Carbohydrates, and Fats with precision progress bars.
- **Micronutrient & Hydration Matrix**: Track water intake, sodium, fiber, and micronutrient ratios.
- **Meal Segment Logging**: Granular breakdown across Breakfast, Lunch, Dinner, and Tactical Fueling (Snacks/Pre-Workout).

### 4. Circadian Daily Protocol & Habits
- **Hourly Daily Timeline**: Visual timeline tracking wake windows, morning hydration, training sessions, post-workout nutrition, and sleep hygiene.
- **Habit Streaks & Frequency Matrix**: Multi-month habit consistency dot matrix inspired by hardware displays.

### 5. Floating Music Capsule
- **Dynamic Media Controller**: Bottom-anchored media controller that pops in with responsive scale physics whenever music is active.
- **Notification-Synced Controls**: Play/pause, track skipping, timeline scrubbing, album art render, and quick collapse.

### 6. Adaptive Dual-Mode Cyber Aesthetics
- **Light Theme (Alabaster Tactical)**: High-contrast white/light-grey canvas designed for bright gym environments and outdoor sunlight.
- **Dark Theme (Stealth Titanium)**: Deep OLED black canvas (`#0C0D12`) with subdued titanium panels (`#141720`) and neon accent flares.
- **System Sync & SQLite Persistence**: Automatically matches OS brightness or respects user toggles with persistent state stored in SQLite.

### 7. Telemetry & Data Sovereignty
- **100% Offline SQLite Engine**: Zero accounts, zero remote servers, zero analytics trackers. All data belongs exclusively to the user on-device.
- **One-Tap Excel Export**: Generates structured, timestamped `.xlsx` spreadsheets containing complete workout history, sets, volume, and dates.

---

## Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (v3.29+)
- **Language**: [Dart](https://dart.dev)
- **Local Database**: [SQLite](https://www.sqlite.org/) via `sqflite` (Android) and `sqflite_common_ffi` (Linux desktop)
- **State Management**: Reactive `ValueNotifier` architecture with event-driven shell synchronization
- **Spreadsheet Generation**: `excel` package
- **Sound & Haptics**: Native platform channels
- **Supported Targets**:
  - **Linux Desktop** (x86_64, GTK / Wayland / X11 via Impeller)
  - **Android** (API 24+, ARM64 / Universal APK)

---

## Directory Structure

```text
kinetic/
├── android/               # Android native scaffolding & Gradle build system
├── assets/images/         # 3D anatomical renders & visual assets
├── app-icon/              # High-resolution vector & PNG app branding icons
├── lib/
│   ├── main.dart          # App entrypoint, theme bootstrap & database initialization
│   ├── models/            # Domain models (Workout, Exercise, Nutrition, Profile)
│   ├── screens/           # Core feature views:
│   │   ├── main_shell.dart            # Synchronized navigation shell & dock
│   │   ├── dashboard_screen.dart      # Tactical overview & volume cards
│   │   ├── calendar_screen.dart       # Workout logs & streak history
│   │   ├── food_tracker_screen.dart   # Macro & meal logging
│   │   ├── analytics_screen.dart      # Muscle heatmap & fatigue radar
│   │   ├── daily_timeline_screen.dart # Circadian habit protocol
│   │   ├── active_workout_screen.dart # Live training session HUD
│   │   ├── routine_builder_screen.dart# Routine creation & exercise picker
│   │   └── onboarding_screen.dart     # First-run setup & sex selection
│   ├── services/          # SQLite database service & Excel exporter
│   ├── theme/             # Dynamic Light/Dark cyber-tactical theme palette
│   └── widgets/           # Modular tactical UI components
├── linux/                 # Linux native runner & CMake build system
└── test/                  # Automated widget, database, and telemetry test suite
```

---

## Building & Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured on your `PATH`.
- For **Linux**: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`.
- For **Android**: Android SDK & command-line tools.

### 1. Run Automated Tests
```bash
flutter test
```

### 2. Build for Linux Desktop
```bash
flutter build linux --release
```
The executable bundle will be located at:
```text
build/linux/x64/release/bundle/kinetic
```

### 3. Build for Android
```bash
flutter build apk --release
```
The compiled APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
