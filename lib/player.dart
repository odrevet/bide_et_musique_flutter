import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/song.dart';
import 'utils.dart' show site, host;

late AudioHandler audioHandler;

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

/// An [AudioHandler] for playing a single item.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  //Timer? _t;
  Song? _song;
  bool _radioMode = false;
  String? _sessionId;
  String? _latestId;

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Future<String> _getStreamUrl() async {
    String url;
    if (_radioMode == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int relay = prefs.getInt('relay') ?? 1;
      int port = 9300;
      url = 'https://relay$relay.$site:$port/bm.mp3?type=http&nocache=20';
    } else {
      url = _song!.streamLink;
    }
    return url;
  }

  @override
  Future<void> play() async {
    String url = await _getStreamUrl();

    if (_radioMode) {
      _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    } else if (url != _latestId) {
      url = _song!.streamLink;
      Map<String, String> headers = {'Host': host, 'Referer': _song!.link};

      if (_sessionId != null) {
        headers['Cookie'] = _sessionId!;
      }

      _player.setAudioSource(AudioSource.uri(Uri.parse(url), headers: headers));
    }

    _latestId = url;
    return _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (!_radioMode) MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        if (!_radioMode) MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: _radioMode ? const [1] : const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'set_song':
        Map songMap = extras!;
        _song = Song(
            id: songMap['id'],
            name: songMap['name'],
            artist: songMap['artist'],
            duration: songMap['duration'] == null ? null : Duration(seconds: songMap['duration']));
        setNotification();
        break;
      case 'set_radio_mode':
        _radioMode = extras!['radio_mode'];
        break;
      case 'get_radio_mode':
        return _radioMode;
      case 'set_session_id':
        _sessionId = extras!['session_id'];
        break;
      default:
        return super.customAction(name, extras);
    }
  }

  void setNotification() {
    var item = MediaItem(
      id: _song!.streamLink,
      album: "Bide et Musique",
      title: _song!.name,
      artist: _song!.artist,
      duration: _radioMode ? null : _song!.duration,
      artUri: Uri.parse(_song!.coverLink),
    );

    mediaItem.add(item);
  }
}
