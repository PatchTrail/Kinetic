import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/services/media_service.dart';
import 'package:kinetic/widgets/floating_music_capsule.dart';
import 'package:kinetic/theme/app_theme.dart';

void main() {
  setUp(() {
    MediaService.instance.currentTrackNotifier.value = null;
  });

  tearDown(() {
    MediaService.instance.currentTrackNotifier.value = null;
  });

  testWidgets('FloatingMusicCapsule pops in with scale animation and collapses when cleared', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingMusicCapsule(),
          ),
        ),
      ),
    );

    // Initially null track -> SizedBox.shrink()
    expect(find.text('Levitating'), findsNothing);

    // Simulate media player starting playback
    MediaService.instance.currentTrackNotifier.value = const MediaTrackInfo(
      title: 'Levitating',
      artist: 'Dua Lipa',
      isPlaying: true,
    );

    // Initial tick starts the forward pop animation
    await tester.pump();
    expect(find.text('Levitating'), findsOneWidget);
    expect(find.text('Dua Lipa'), findsOneWidget);

    // Advance animation mid-way (200ms) - verifying no exceptions during curve interpolation
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
    expect(find.byType(SizeTransition), findsOneWidget);

    // Advance to completion (another 300ms)
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Levitating'), findsOneWidget);

    // Tap play/pause button
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(MediaService.instance.currentTrackNotifier.value?.isPlaying, isFalse);

    // Tap close button to dismiss
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    // Verify reverse collapse animation runs cleanly
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));

    expect(MediaService.instance.currentTrackNotifier.value, isNull);
  });

  testWidgets('FloatingMusicCapsule dynamically updates styling when theme changes', (tester) async {
    KineticTheme.setThemeMode(ThemeMode.light);
    KineticTheme.updateActiveBrightness(false);

    MediaService.instance.currentTrackNotifier.value = const MediaTrackInfo(
      title: 'Stronger',
      artist: 'Kanye West',
      isPlaying: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingMusicCapsule(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Stronger'), findsOneWidget);

    // Switch to Dark mode
    KineticTheme.setThemeMode(ThemeMode.dark);
    KineticTheme.updateActiveBrightness(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Stronger'), findsOneWidget);
  });
}
