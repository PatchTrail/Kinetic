import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';

class FloatingMusicCapsule extends StatefulWidget {
  const FloatingMusicCapsule({super.key});

  @override
  State<FloatingMusicCapsule> createState() => _FloatingMusicCapsuleState();
}

class _FloatingMusicCapsuleState extends State<FloatingMusicCapsule>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final AnimationController _discController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _sizeAnimation;

  MediaTrackInfo? _displayedTrack;

  @override
  void initState() {
    super.initState();

    // Listen to theme mode changes to dynamically update colors
    KineticTheme.themeModeNotifier.addListener(_handleThemeChanged);

    // 1. Pop-in spring animation controller
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 250),
    );

    // Bouncy pop-in scale: starts from 0.70, overshoots with easeOutBack to ~1.05, then settles at 1.0
    _scaleAnimation = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );

    // Smooth opacity fade
    _fadeAnimation = CurvedAnimation(
      parent: _popController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    // Subtle upward pop slide
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _popController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Smooth height expansion / collapse
    _sizeAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 2. Vinyl disc rotation controller
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Initial state check
    final initialTrack = MediaService.instance.currentTrackNotifier.value;
    if (initialTrack != null) {
      _displayedTrack = initialTrack;
      if (initialTrack.isPlaying) {
        _discController.repeat();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popController.forward();
        }
      });
    }

    // Subscribe to track notifications
    MediaService.instance.currentTrackNotifier.addListener(_handleTrackChanged);
  }

  void _handleThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTrackChanged() {
    final track = MediaService.instance.currentTrackNotifier.value;
    if (track != null) {
      setState(() {
        _displayedTrack = track;
      });
      if (track.isPlaying) {
        if (!_discController.isAnimating) {
          _discController.repeat();
        }
      } else {
        _discController.stop();
      }

      if (!_popController.isCompleted) {
        _popController.forward();
      }
    } else {
      _discController.stop();
      _popController.reverse().then((_) {
        if (mounted && MediaService.instance.currentTrackNotifier.value == null) {
          setState(() {
            _displayedTrack = null;
          });
        }
      });
    }
  }

  DecorationImage? _buildAlbumImage(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('file://')) {
        final filePath = Uri.parse(url).toFilePath();
        final file = File(filePath);
        if (file.existsSync()) {
          return DecorationImage(image: FileImage(file), fit: BoxFit.cover);
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    KineticTheme.themeModeNotifier.removeListener(_handleThemeChanged);
    MediaService.instance.currentTrackNotifier.removeListener(_handleTrackChanged);
    _popController.dispose();
    _discController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_popController, KineticTheme.themeModeNotifier]),
      builder: (context, _) {
        if (_displayedTrack == null && _popController.isDismissed) {
          return const SizedBox.shrink();
        }

        final track = _displayedTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final albumImg = _buildAlbumImage(track.artUrl);

        return SizeTransition(
          sizeFactor: _sizeAnimation,
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: KineticTheme.bgSurface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: track.isPlaying
                          ? KineticTheme.accentFlame.withValues(alpha: 0.5)
                          : KineticTheme.borderMedium,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      if (track.isPlaying)
                        BoxShadow(
                          color: KineticTheme.accentFlame.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Spinning Vinyl / Album Icon
                      RotationTransition(
                        turns: _discController,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: KineticTheme.bgSurfaceElevated,
                            border: Border.all(
                              color: KineticTheme.accentFlame.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            image: albumImg,
                          ),
                          child: albumImg == null
                              ? Center(
                                  child: Icon(
                                    track.isPlaying ? Icons.music_note_rounded : Icons.graphic_eq_rounded,
                                    size: 16,
                                    color: KineticTheme.accentFlame,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Artist with crossfade switcher on track change
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                          child: Column(
                            key: ValueKey('${track.title}_${track.artist}'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: KineticTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                track.artist.isNotEmpty ? track.artist : 'Playing on device',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: KineticTheme.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Transport Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 20),
                            color: KineticTheme.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => MediaService.instance.previous(),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => MediaService.instance.playPause(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: KineticTheme.accentFlame,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                track.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 20),
                            color: KineticTheme.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => MediaService.instance.next(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: KineticTheme.textTertiary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => MediaService.instance.clearTrack(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
