import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nowPlaying.dart';
import 'song.dart';
import 'utils.dart';

bool radioMode;

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
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioProcessingState _audioProcessingState;
  bool _playing;
  bool _interrupted = false;

  Song _song;
  String _mode;
  String _sessionId;
  String _latestId;

  Timer _t;

  void periodicFetchSongNowPlaying() {
    fetchNowPlaying().then((song) async {
      if (_mode == 'radio')
        await AudioService.customAction('song', song.toJson());
      int delay = (song.duration.inSeconds -
              (song.duration.inSeconds * song.elapsedPcent / 100))
          .ceil();
      _t = Timer(Duration(seconds: delay), () {
        periodicFetchSongNowPlaying();
      });
    });
  }

  StreamSubscription<AudioPlaybackState> _playerStateSubscription;
  StreamSubscription<AudioPlaybackEvent> _eventSubscription;

  @override
  void onStart(Map<String, dynamic> params) {
    periodicFetchSongNowPlaying();
    _playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
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
          break;
        case AudioPlaybackState.connecting:
          _setState(
            processingState: AudioProcessingState.connecting,
            position: event.position,
          );
          break;
        default:
          break;
      }
    });

    onSkipToNext();
  }

  void _handlePlaybackCompleted() {
    onStop();
  }

  void playPause() {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  @override
  void onPlay() async {
    if (_audioProcessingState == null) {
      _playing = true;
      String url = await _getStreamUrl();
      if (url != _latestId) {
        if (_mode == 'song') {
          Map<String, String> headers = {
            'Host': host,
            'Referer': _song.link,
            'Cookie': _sessionId
          };
          await _audioPlayer.setUrl(url, headers: headers);
        } else
          await _audioPlayer.setUrl(url);

        _latestId = url;
      }
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

  @override
  Future<void> onStop() async {
    _t?.cancel();
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    _playing = false;
    _playerStateSubscription.cancel();
    _eventSubscription.cancel();
    await _setState(processingState: AudioProcessingState.stopped);
    await super.onStop();
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
        pauseControl,
        stopControl,
      ];
    } else {
      return [
        playControl,
        stopControl,
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
      case 'session_id':
        _sessionId = arguments;
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
        duration: _song.duration ?? null));
  }
}
