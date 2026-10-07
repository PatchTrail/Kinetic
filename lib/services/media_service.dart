import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MediaTrackInfo {
  final String title;
  final String artist;
  final String album;
  final bool isPlaying;
  final String? artUrl;

  const MediaTrackInfo({
    required this.title,
    required this.artist,
    this.album = '',
    this.isPlaying = true,
    this.artUrl,
  });

  MediaTrackInfo copyWith({
    String? title,
    String? artist,
    String? album,
    bool? isPlaying,
    String? artUrl,
  }) {
    return MediaTrackInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      isPlaying: isPlaying ?? this.isPlaying,
      artUrl: artUrl ?? this.artUrl,
    );
  }
}

class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ValueNotifier<MediaTrackInfo?> currentTrackNotifier = ValueNotifier<MediaTrackInfo?>(null);
  Timer? _pollTimer;
  String? _activeMprisBus;

  void startListening() {
    _checkMpris();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkMpris();
    });
  }

  void stopListening() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkMpris() async {
    if (!Platform.isLinux) return;

    try {
      final res = await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.DBus',
        '--type=method_call',
        '--print-reply',
        '/org/freedesktop/DBus',
        'org.freedesktop.DBus.ListNames',
      ]);

      if (res.exitCode != 0) return;

      final output = res.stdout.toString();
      final lines = output.split('\n');
      String? playerBus;

      for (final line in lines) {
        if (line.contains('org.mpris.MediaPlayer2.')) {
          final match = RegExp(r'"(org\.mpris\.MediaPlayer2\.[^"]+)"').firstMatch(line);
          if (match != null) {
            playerBus = match.group(1);
            break;
          }
        }
      }

      if (playerBus == null) {
        // No native MPRIS player running right now.
        // If we previously had one, set to null
        if (_activeMprisBus != null) {
          _activeMprisBus = null;
          currentTrackNotifier.value = null;
        }
        return;
      }

      _activeMprisBus = playerBus;

      // Query PlaybackStatus
      final statusRes = await Process.run('dbus-send', [
        '--session',
        '--dest=$playerBus',
        '--type=method_call',
        '--print-reply',
        '/org/mpris/MediaPlayer2',
        'org.freedesktop.DBus.Properties.Get',
        'string:org.mpris.MediaPlayer2.Player',
        'string:PlaybackStatus',
      ]);

      final isPlaying = statusRes.stdout.toString().contains('"Playing"');

      // Query Metadata
      final metaRes = await Process.run('dbus-send', [
        '--session',
        '--dest=$playerBus',
        '--type=method_call',
        '--print-reply',
        '/org/mpris/MediaPlayer2',
        'org.freedesktop.DBus.Properties.Get',
        'string:org.mpris.MediaPlayer2.Player',
        'string:Metadata',
      ]);

      final metaOutput = metaRes.stdout.toString();

      String title = 'Unknown Track';
      final titleMatch = RegExp(r'string\s+"xesam:title"\s+variant\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (titleMatch != null) {
        title = titleMatch.group(1) ?? title;
      }

      String artist = 'Unknown Artist';
      final artistMatch = RegExp(r'string\s+"xesam:artist"\s+variant\s+array\s+\[\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (artistMatch != null) {
        artist = artistMatch.group(1) ?? artist;
      }

      String album = '';
      final albumMatch = RegExp(r'string\s+"xesam:album"\s+variant\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (albumMatch != null) {
        album = albumMatch.group(1) ?? '';
      }

      currentTrackNotifier.value = MediaTrackInfo(
        title: title,
        artist: artist,
        album: album,
        isPlaying: isPlaying,
      );
    } catch (_) {
      // D-bus call or parsing error
    }
  }

  Future<void> playPause() async {
    final curr = currentTrackNotifier.value;
    if (curr == null) return;

    if (_activeMprisBus != null && Platform.isLinux) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.PlayPause',
      ]);
      await _checkMpris();
    } else {
      // Local toggle
      currentTrackNotifier.value = curr.copyWith(isPlaying: !curr.isPlaying);
    }
  }

  Future<void> next() async {
    if (_activeMprisBus != null && Platform.isLinux) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.Next',
      ]);
      await _checkMpris();
    }
  }

  Future<void> previous() async {
    if (_activeMprisBus != null && Platform.isLinux) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.Previous',
      ]);
      await _checkMpris();
    }
  }

  /// Helper to test or simulate a track in dev/offline mode
  void simulateTrack({required String title, required String artist}) {
    currentTrackNotifier.value = MediaTrackInfo(
      title: title,
      artist: artist,
      album: 'Workout Mix',
      isPlaying: true,
    );
  }

  void clearTrack() {
    currentTrackNotifier.value = null;
  }
}
