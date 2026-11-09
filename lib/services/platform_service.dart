import 'dart:async';
import 'dart:convert';

import 'package:beatz/models/album.dart';
import 'package:beatz/models/audio_media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Android side (MediaStore queries + MediaPlayer playback).
class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.npkompleet.beatz');
  static const String _fetchAlbumMethod = 'fetchAlbums';
  static const String _fetchSongsFromAlbumMethod = 'fetchSongsFromAlbum';
  static const String _seekMethod = 'seek';
  static const String _pauseMethod = 'pause';
  static const String _resumeMethod = 'resume';
  static const String _playSongMethod = 'play';
  static const String _positionMethod = 'position';
  static const String _songCompleteMethod = 'complete';
  static const String _errorMethod = 'error';

  /// "complete" when the current song finished, "error" when playback failed.
  static final ValueNotifier<String> stopNotifier = ValueNotifier('');

  /// Current playback position in milliseconds.
  static final ValueNotifier<int> positionNotifier = ValueNotifier(0);

  static bool _handlerSet = false;

  static void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler(_callHandler);
  }

  // Method handler for calls executed on the Flutter side of the channel.
  static Future<void> _callHandler(MethodCall call) async {
    switch (call.method) {
      case _songCompleteMethod:
        stopNotifier.value = 'complete';
      case _errorMethod:
        stopNotifier.value = 'error';
      case _positionMethod:
        positionNotifier.value = call.arguments as int;
    }
  }

  /// Throws a [PlatformException] when the library can't be read.
  static Future<List<Album>> fetchAlbums() async {
    final result = await _channel.invokeMethod<String>(_fetchAlbumMethod);
    return compute(parseAlbums, result ?? '[]');
  }

  static List<Album> parseAlbums(String result) => (json.decode(result) as List)
      .map((e) => Album.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Throws a [PlatformException] when the library can't be read.
  static Future<List<AudioMedia>> fetchSongsFromAlbum(int id) async {
    final result = await _channel
        .invokeMethod<String>(_fetchSongsFromAlbumMethod, {'albumId': id});
    return compute(parseAlbumSongs, result ?? '[]');
  }

  static List<AudioMedia> parseAlbumSongs(String result) =>
      (json.decode(result) as List)
          .map((e) => AudioMedia.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Starts playing [url]; completes once playback has started.
  static Future<void> playSong(String url) async {
    _ensureHandler();
    try {
      await _channel.invokeMethod<String>(_playSongMethod, {'songUrl': url});
    } on PlatformException catch (e) {
      debugPrint('play failed: $e');
      stopNotifier.value = 'error';
    }
  }

  static Future<void> seekTo(int playbackPosition) =>
      _channel.invokeMethod<void>(_seekMethod, {'position': playbackPosition});

  static Future<void> pauseSong() => _channel.invokeMethod<void>(_pauseMethod);

  static Future<void> resumeSong() =>
      _channel.invokeMethod<void>(_resumeMethod);

  static void reset() {
    stopNotifier.value = '';
    positionNotifier.value = 0;
  }
}
