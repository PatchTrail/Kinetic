import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  static const MethodChannel _androidChannel = MethodChannel('com.kinetic.kinetic/media_service');

  final ValueNotifier<MediaTrackInfo?> currentTrackNotifier = ValueNotifier<MediaTrackInfo?>(null);
  Timer? _pollTimer;
  String? _activeMprisBus;
  String? _dismissedTrackKey;
  bool _androidInitialized = false;

  void startListening() {
    if (Platform.isLinux) {
      _checkMpris();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _checkMpris();
      });
    } else if (Platform.isAndroid) {
      _initAndroidChannel();
      _queryAndroidTrack();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _queryAndroidTrack();
      });
    }
  }

  void stopListening() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (Platform.isAndroid) {
      try {
        _androidChannel.invokeMethod('stopListening');
      } catch (_) {}
    }
  }

  // --- ANDROID INTEGRATION ---

  void _initAndroidChannel() {
    if (_androidInitialized) return;
    _androidInitialized = true;

    _androidChannel.setMethodCallHandler((call) async {
      if (call.method == 'onTrackChanged') {
        _handleAndroidTrackData(call.arguments);
      }
    });

    try {
      _androidChannel.invokeMethod('startListening');
    } catch (_) {}
  }

  Future<void> _queryAndroidTrack() async {
    try {
      final res = await _androidChannel.invokeMethod('getTrackInfo');
      _handleAndroidTrackData(res);
    } catch (_) {}
  }

  void _handleAndroidTrackData(dynamic raw) {
    if (raw == null || raw is! Map) {
      if (currentTrackNotifier.value != null) {
        currentTrackNotifier.value = null;
      }
      return;
    }

    final map = Map<String, dynamic>.from(raw);
    final title = (map['title'] as String?)?.trim() ?? '';
    final artist = (map['artist'] as String?)?.trim() ?? '';
    final album = (map['album'] as String?)?.trim() ?? '';
    final isPlaying = map['isPlaying'] as bool? ?? false;
    final artUrl = map['artUrl'] as String?;

    if (title.isEmpty) {
      if (currentTrackNotifier.value != null) {
        currentTrackNotifier.value = null;
      }
      return;
    }

    final trackKey = '${title}_$artist';
    if (_dismissedTrackKey != null) {
      if (_dismissedTrackKey == trackKey) {
        return;
      } else {
        _dismissedTrackKey = null;
      }
    }

    final prev = currentTrackNotifier.value;
    if (prev == null ||
        prev.title != title ||
        prev.artist != artist ||
        prev.isPlaying != isPlaying ||
        prev.artUrl != artUrl) {
      currentTrackNotifier.value = MediaTrackInfo(
        title: title,
        artist: artist,
        album: album,
        isPlaying: isPlaying,
        artUrl: artUrl,
      );
    }
  }

  Future<bool> isAndroidPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _androidChannel.invokeMethod<bool>('isPermissionGranted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestAndroidPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _androidChannel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  // --- LINUX MPRIS INTEGRATION ---

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
      final playerBuses = <String>[];

      for (final line in lines) {
        if (line.contains('org.mpris.MediaPlayer2.')) {
          final match = RegExp(r'"(org\.mpris\.MediaPlayer2\.[^"]+)"').firstMatch(line);
          if (match != null) {
            playerBuses.add(match.group(1)!);
          }
        }
      }

      if (playerBuses.isEmpty) {
        if (_activeMprisBus != null || currentTrackNotifier.value != null) {
          _activeMprisBus = null;
          _dismissedTrackKey = null;
          currentTrackNotifier.value = null;
        }
        return;
      }

      String? activePlayingBus;
      String? fallbackPausedBus;
      bool isPlaying = false;

      for (final bus in playerBuses) {
        final statusRes = await Process.run('dbus-send', [
          '--session',
          '--dest=$bus',
          '--type=method_call',
          '--print-reply',
          '/org/mpris/MediaPlayer2',
          'org.freedesktop.DBus.Properties.Get',
          'string:org.mpris.MediaPlayer2.Player',
          'string:PlaybackStatus',
        ]);
        if (statusRes.exitCode == 0) {
          final out = statusRes.stdout.toString();
          if (out.contains('"Playing"')) {
            activePlayingBus = bus;
            isPlaying = true;
            break;
          } else if (fallbackPausedBus == null && out.contains('"Paused"')) {
            fallbackPausedBus = bus;
          }
        }
      }

      final chosenBus = activePlayingBus ?? fallbackPausedBus;
      if (chosenBus == null) {
        if (_activeMprisBus != null || currentTrackNotifier.value != null) {
          _activeMprisBus = null;
          _dismissedTrackKey = null;
          currentTrackNotifier.value = null;
        }
        return;
      }

      _activeMprisBus = chosenBus;

      // Query Metadata
      final metaRes = await Process.run('dbus-send', [
        '--session',
        '--dest=$chosenBus',
        '--type=method_call',
        '--print-reply',
        '/org/mpris/MediaPlayer2',
        'org.freedesktop.DBus.Properties.Get',
        'string:org.mpris.MediaPlayer2.Player',
        'string:Metadata',
      ]);

      if (metaRes.exitCode != 0) return;
      final metaOutput = metaRes.stdout.toString();

      String title = '';
      final titleMatch = RegExp(r'string\s+"xesam:title"\s+variant\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (titleMatch != null) {
        title = titleMatch.group(1)?.trim() ?? '';
      }

      String artist = '';
      final artistMatch = RegExp(r'string\s+"xesam:artist"\s+variant\s+array\s+\[\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (artistMatch != null) {
        artist = artistMatch.group(1)?.trim() ?? '';
      }

      String album = '';
      final albumMatch = RegExp(r'string\s+"xesam:album"\s+variant\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (albumMatch != null) {
        album = albumMatch.group(1)?.trim() ?? '';
      }

      String? artUrl;
      final artMatch = RegExp(r'string\s+"mpris:artUrl"\s+variant\s+string\s+"([^"]+)"').firstMatch(metaOutput);
      if (artMatch != null) {
        artUrl = artMatch.group(1)?.trim();
      }

      if (title.isEmpty) {
        if (currentTrackNotifier.value != null) {
          currentTrackNotifier.value = null;
        }
        return;
      }

      final trackKey = '${title}_$artist';
      if (_dismissedTrackKey != null) {
        if (_dismissedTrackKey == trackKey) {
          // User explicitly dismissed this track; do not re-open unless song changes
          return;
        } else {
          _dismissedTrackKey = null;
        }
      }

      final prev = currentTrackNotifier.value;
      if (prev == null ||
          prev.title != title ||
          prev.artist != artist ||
          prev.isPlaying != isPlaying ||
          prev.artUrl != artUrl) {
        currentTrackNotifier.value = MediaTrackInfo(
          title: title,
          artist: artist,
          album: album,
          isPlaying: isPlaying,
          artUrl: artUrl,
        );
      }
    } catch (_) {
      // D-bus call or parsing error
    }
  }

  // --- PLAYBACK CONTROLS ---

  Future<void> playPause() async {
    final curr = currentTrackNotifier.value;
    if (curr == null) return;

    if (Platform.isLinux && _activeMprisBus != null) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.PlayPause',
      ]);
      await _checkMpris();
    } else if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('playPause');
        await _queryAndroidTrack();
      } catch (_) {}
    } else {
      // Local toggle
      currentTrackNotifier.value = curr.copyWith(isPlaying: !curr.isPlaying);
    }
  }

  Future<void> next() async {
    if (Platform.isLinux && _activeMprisBus != null) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.Next',
      ]);
      await _checkMpris();
    } else if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('next');
        await _queryAndroidTrack();
      } catch (_) {}
    }
  }

  Future<void> previous() async {
    if (Platform.isLinux && _activeMprisBus != null) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=$_activeMprisBus',
        '--type=method_call',
        '/org/mpris/MediaPlayer2',
        'org.mpris.MediaPlayer2.Player.Previous',
      ]);
      await _checkMpris();
    } else if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('previous');
        await _queryAndroidTrack();
      } catch (_) {}
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
    final curr = currentTrackNotifier.value;
    if (curr != null) {
      _dismissedTrackKey = '${curr.title}_${curr.artist}';
    }
    currentTrackNotifier.value = null;
  }
}
