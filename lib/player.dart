import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart' show site;
import 'models/song.dart';

late AudioHandler audioHandler;

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

/// An [AudioHandler] for playing a single item.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  Song? _song;
  bool _radioMode = false;

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }


  Future<String> _getStreamUrl() async {
    String url;
    if (_radioMode == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
      int relay = 2; //prefs.getInt('relay') ?? 1;
      int port = 9300; //radioHiQuality ? 9100 : 9200;
      url = 'https://relay$relay.$site:$port';
      url = 'https://relay2.bide-et-musique.com:9300/bm.mp3?type=http&nocache=20';
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
    } /*else if (url != _latestId) {
      Map<String, String> headers = {'Host': host, 'Referer': _song.link};
      if (_sessionId != null) headers['Cookie'] = _sessionId;
      await _audioPlayer.setUrl(url, headers: headers);
    }*/

    //_latestId = url;
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
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
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
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'set_song':
        Map songMap = extras!;
        this._song = Song(
            id: songMap['id'],
            name: songMap['name'],
            artist: songMap['artist'],
            duration: songMap['duration'] == null
                ? null
                : Duration(seconds: songMap['duration']));
        this.setNotification();
        break;
      case 'set_radio_mode':
        _radioMode = extras!['radio_mode'];
        break;
    }
  }

  void setNotification() {
    var item = MediaItem(
      id: _song!.streamLink,
      album: "Bide et Musique",
      title: _song!.name,
      artist: _song!.artist,
      duration: _song!.duration,
      artUri: Uri.parse(_song!.coverLink),
    );

    mediaItem.add(item);
    _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
  }
}
