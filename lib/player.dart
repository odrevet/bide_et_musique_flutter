import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'song.dart';
import 'utils.dart';

enum PlayerMode { radio, song, off }

abstract class PlayerSongType {
  static PlayerMode playerMode = PlayerMode.off;
}

class PlayerState {
  final MediaItem mediaItem;
  final PlaybackState playbackState;

  PlayerState(this.mediaItem, this.playbackState);
}

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_stat_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_stat_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_stat_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

void audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  //final _queue = <MediaItem>[];
  //int _queueIndex = -1;
  AudioPlayer _audioPlayer = AudioPlayer();
  Completer _completer = Completer();
  AudioProcessingState _audioProcessingState;
  bool _playing;
  bool _interrupted = false;

  Song _song;
  String _mode;
  String _latestId;

  /*bool get hasNext => _queueIndex + 1 < _queue.length;

  bool get hasPrevious => _queueIndex > 0;

  MediaItem get mediaItem => _queue[_queueIndex];*/

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    var playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    var eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final bufferingState =
          event.buffering ? AudioProcessingState.buffering : null;
      switch (event.state) {
        case AudioPlaybackState.paused:
          _setState(
            processingState: bufferingState ?? AudioProcessingState.ready,
            position: event.position,
          );
          break;
        case AudioPlaybackState.playing:
          _setState(
            processingState: bufferingState ?? AudioProcessingState.ready,
            position: event.position,
          );
          AudioServiceBackground.sendCustomEvent(event.icyMetadata);
          break;
        case AudioPlaybackState.connecting:
          _setState(
            processingState: _audioProcessingState ?? AudioProcessingState.connecting,
            position: event.position,
          );
          break;
        default:
          break;
      }
    });

    //AudioServiceBackground.setQueue(_queue);
    onSkipToNext();
    await _completer.future;
    playerStateSubscription.cancel();
    eventSubscription.cancel();
  }

  void _handlePlaybackCompleted() {
    onStop();
    /*if (hasNext) {
      onSkipToNext();
    } else {
      onStop();
    }*/
  }

  void playPause() {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  /*@override
  Future<void> onSkipToNext() => _skip(1);

  @override
  Future<void> onSkipToPrevious() => _skip(-1);

  Future<void> _skip(int offset) async {
    final newPos = _queueIndex + offset;
    if (!(newPos >= 0 && newPos < _queue.length)) return;
    if (_playing == null) {
      // First time, we want to start playing
      _playing = true;
    } else if (_playing) {
      // Stop current item
      await _audioPlayer.stop();
    }
    // Load next item
    _queueIndex = newPos;
    AudioServiceBackground.setMediaItem(mediaItem);
    _skipState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    await _audioPlayer.setUrl(mediaItem.id);
    _skipState = null;
    // Resume playback if we were playing
    if (_playing) {
      onPlay();
    } else {
      _setState(processingState: AudioProcessingState.ready);
    }
  }*/

  @override
  void onPlay() async {
    String url = await _getStreamUrl();
    if (url != _latestId) {
      await _audioPlayer.setUrl(url);
      _latestId = url;
    }

    if (_audioProcessingState == null) {
      _playing = true;
      _audioPlayer.play();
    }
  }

  @override
  void onPause() {
    if (_audioProcessingState == null) {
      _playing = false;
      _audioPlayer.pause();
    }
  }

  @override
  void onSeekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  /*@override
  Future<void> onFastForward() async {
    await _seekRelative(fastForwardInterval);
  }

  @override
  Future<void> onRewind() async {
    await _seekRelative(rewindInterval);
  }

  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _audioPlayer.playbackEvent.position + offset;
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    await _audioPlayer.seek(_audioPlayer.playbackEvent.position + offset);
  }*/

  @override
  Future<void> onStop() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    _playing = false;
    _setState(processingState: AudioProcessingState.stopped);
    _completer.complete();
  }

  /* Handling Audio Focus */
  @override
  void onAudioFocusLost(AudioInterruption interruption) {
    if (_playing) _interrupted = true;
    switch (interruption) {
      case AudioInterruption.pause:
      case AudioInterruption.temporaryPause:
      case AudioInterruption.unknownPause:
        onPause();
        break;
      case AudioInterruption.temporaryDuck:
        _audioPlayer.setVolume(0.5);
        break;
    }
  }

  @override
  void onAudioFocusGained(AudioInterruption interruption) {
    switch (interruption) {
      case AudioInterruption.temporaryPause:
        if (!_playing && _interrupted) onPlay();
        break;
      case AudioInterruption.temporaryDuck:
        _audioPlayer.setVolume(1.0);
        break;
      default:
        break;
    }
    _interrupted = false;
  }

  @override
  void onAudioBecomingNoisy() {
    onPause();
  }

  void _setState({
    AudioProcessingState processingState,
    Duration position,
    Duration bufferedPosition,
  }) {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position;
    }
    AudioServiceBackground.setState(
      controls: getControls(),
      systemActions: [MediaAction.seekTo],
      processingState:
          processingState ?? AudioServiceBackground.state.processingState,
      playing: _playing,
      position: position,
      bufferedPosition: bufferedPosition ?? position,
      speed: _audioPlayer.speed,
    );
  }

  List<MediaControl> getControls() {
    if (_playing) {
      return [
        //skipToPreviousControl,
        pauseControl,
        stopControl,
        //skipToNextControl
      ];
    } else {
      return [
        //skipToPreviousControl,
        playControl,
        stopControl,
        //skipToNextControl
      ];
    }
  }

    Future<String> _getStreamUrl() async {
    String url;
    if (this._mode == 'radio') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
      int relay = prefs.getInt('relay') ?? 1;
      int port = radioHiQuality ? 9100 : 9200;
      url = 'http://relay$relay.$site:$port';
    } else {
      url = _song.streamLink;
    }
    return url;
  }

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    switch (name) {
      case 'song':
        Map songMap = arguments;
        this._song = Song(
            id: songMap['id'],
            name: songMap['name'],
            artist: songMap['artist'],
            duration: songMap['duration'] == null
                ? null
                : Duration(seconds: songMap['duration']));
        this.setNotification();
        break;
      case 'mode':
        _mode = arguments;
        break;
    }
    super.onCustomAction(name, arguments);
  }

  void setNotification() {
    AudioServiceBackground.setMediaItem(MediaItem(
        id: _song.streamLink,
        album: '',
        title: _song.name.isEmpty ? 'Titre non disponible' : _song.name,
        artist: _song.artist.isEmpty ? 'Artiste non disponible' : _song.artist,
        artUri: _song.coverLink,
        duration: _song.duration));
  }
}

