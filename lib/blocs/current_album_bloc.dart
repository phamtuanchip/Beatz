import 'dart:async';
import 'dart:collection';

import 'package:beatz/blocs/bloc_provider.dart';
import 'package:beatz/models/audio_media.dart';
import 'package:beatz/services/platform_service.dart';
import 'package:beatz/utils/time_util.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class CurrentAlbumBloc extends BlocBase {
  List<AudioMedia> _albumSongsList = [];
  final int _songIndex = 0;
  int _duration = 0;
  String _durationString = '00:00';

  /// One of "", "play", "pause", "resume", "stop", "error".
  final playState = ValueNotifier<String>('');

  /// [title, artist] of the current song, empty until songs are loaded.
  final songInfo = ValueNotifier<List<String>>([]);

  // Stream to handle displaying songs
  final BehaviorSubject<List<AudioMedia>> _listController =
      BehaviorSubject<List<AudioMedia>>();
  Stream<List<AudioMedia>> get albumSongsListStream => _listController.stream;

  // Stream to handle playing songs
  final StreamController<int> _playController = StreamController<int>();
  StreamSink<int> get startSong => _playController.sink;

  // Stream to handle updating the slider: [progress 0..1, position, duration]
  final StreamController<List<String>> _uiController =
      StreamController<List<String>>();
  Stream<List<String>> get uiStream => _uiController.stream;

  final StreamController<double> _seekerController =
      StreamController<double>.broadcast();
  StreamSink<double> get seekTo => _seekerController.sink;

  CurrentAlbumBloc(int albumId) {
    _fetchAlbumSongs(albumId);
    _playController.stream.listen(_startPlaying);
    _seekerController.stream.listen(_doSeek);
    playState.addListener(_pauseAndResume);
    PlatformService.stopNotifier.addListener(_onStopped);
    PlatformService.positionNotifier.addListener(_onPosition);
  }

  Future<void> _fetchAlbumSongs(int id) async {
    try {
      _albumSongsList = await PlatformService.fetchSongsFromAlbum(id);
    } catch (e) {
      if (!_listController.isClosed) _listController.addError(e);
      return;
    }
    if (_listController.isClosed) return;
    _listController.add(UnmodifiableListView<AudioMedia>(_albumSongsList));
    if (_albumSongsList.isEmpty) return;
    final song = _albumSongsList[_songIndex];
    songInfo.value = [song.title, song.artist];
    _duration = song.duration;
    _durationString = TimeUtil.convertTimeToString(_duration);
  }

  Future<void> _startPlaying(int _) async {
    if (_albumSongsList.isEmpty) return;
    PlatformService.reset();
    playState.value = 'play';
    await PlatformService.playSong(_albumSongsList[_songIndex].uri);
  }

  void _onPosition() {
    if (_uiController.isClosed || _duration <= 0) return;
    final position = PlatformService.positionNotifier.value;
    _uiController.add([
      (position / _duration).clamp(0.0, 1.0).toString(),
      TimeUtil.convertTimeToString(position),
      _durationString,
    ]);
  }

  void _onStopped() {
    switch (PlatformService.stopNotifier.value) {
      case 'complete':
        playState.value = 'stop';
      case 'error':
        playState.value = 'error';
    }
  }

  void _pauseAndResume() {
    if (playState.value == 'pause') {
      PlatformService.pauseSong();
    } else if (playState.value == 'resume') {
      PlatformService.resumeSong();
    }
  }

  void _doSeek(double position) {
    if (_duration > 0) PlatformService.seekTo((position * _duration).floor());
  }

  @override
  void dispose() {
    PlatformService.stopNotifier.removeListener(_onStopped);
    PlatformService.positionNotifier.removeListener(_onPosition);
    if (playState.value == 'play' || playState.value == 'resume') {
      PlatformService.pauseSong();
    }
    _listController.close();
    _playController.close();
    _uiController.close();
    _seekerController.close();
    playState.dispose();
    songInfo.dispose();
  }
}
