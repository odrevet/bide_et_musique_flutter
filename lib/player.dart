import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/song.dart';

import 'services/song.dart';

import 'utils.dart';

class ScreenState {
  final MediaItem mediaItem;
  final PlaybackState playbackState;

  ScreenState(this.mediaItem, this.playbackState);
}

/*
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
*/

void audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioProcessingState _audioProcessingState;

  //bool get _playing => AudioServiceBackground.state.playing;

  bool _interrupted = false;
  //StreamSubscription<AudioPlaybackState> _playerStateSubscription;
  //StreamSubscription<AudioPlaybackEvent> _eventSubscription;
  StreamSubscription<PlaybackEvent> _eventSubscription;

  Song _song;
  bool _radioMode;
  String _sessionId;
  String _latestId;

  Timer _t;

  void periodicFetchSongNowPlaying() {
    fetchNowPlaying().then((song) async {
      if (_radioMode == true)
        await AudioService.customAction('set_song', song.toJson());
      int delay = (song.duration.inSeconds -
              (song.duration.inSeconds * song.elapsedPcent / 100))
          .ceil();
      _t = Timer(Duration(seconds: delay), () {
        periodicFetchSongNowPlaying();
      });
    });
  }

  //Seeker _seeker;

  //List<MediaItem> get queue => _mediaLibrary.items;
  //int get index => _player.currentIndex;
  //MediaItem get mediaItem => index == null ? null : queue[index];

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        //MediaControl.skipToPrevious,
        if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
        //if (_audioPlayer.playing) pauseControl else playControl,
        MediaControl.stop,
        //stopControl
        //MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        //MediaAction.seekForward,
        //MediaAction.seekBackward,
      ],
      processingState: _getProcessingState(),
      playing: _audioPlayer.playing,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_audioProcessingState] instead.
  AudioProcessingState _getProcessingState() {
    if (_audioProcessingState != null) return _audioProcessingState;
    switch (_audioPlayer.processingState) {
      case ProcessingState.none:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_audioPlayer.processingState}");
    }
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // Broadcast media item changes.
    /*_player.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
    });*/
    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      _broadcastState();
    });
    // Special processing for state transitions.
    _audioPlayer.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _audioProcessingState = null;
          break;
        default:
          break;
      }
    });

    // Load and broadcast the queue
    //AudioServiceBackground.setQueue(queue);
    try {
      /*await _audioPlayer.load(ConcatenatingAudioSource(
        children:
            queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
      ));*/

      // In this example, we automatically start playing on start.
      onPlay();
    } catch (e) {
      print("Error: $e");
      onStop();
    }
  }
  /*
  @override
  void onStart(Map<String, dynamic> params) {
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
          AudioServiceBackground.sendCustomEvent(event.icyMetadata);
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
  }*/

  /*void _handlePlaybackCompleted() {
    onStop();
  }*/

  void playPause() {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  @override
  Future<void> onPlay() async {
    if (_audioProcessingState == null) {
      String url = await _getStreamUrl();
      if (url != _latestId) {
        if (_radioMode == false) {
          Map<String, String> headers = {'Host': host, 'Referer': _song.link};

          if (_sessionId != null) headers['Cookie'] = _sessionId;
          await _audioPlayer.setUrl(url, headers: headers);
        } else {
          await _audioPlayer.setUrl(url);
        }

        _latestId = url;
      }

      AudioServiceBackground.setState(
        controls: [MediaControl.pause, MediaControl.stop],
        processingState: AudioProcessingState.ready,
        playing: true,
      );

      return _audioPlayer.play();
    }
  }

  @override
  Future<void> onPause() {
    return _audioPlayer.pause();
  }


  @override
  Future<void> onSeekTo(Duration position) {
    return _audioPlayer.seek(position);
  }

  /*@override
  Future<void> onClick(MediaButton button) {
    playPause();
  }*/

/*
  @override
  Future<void> onStop() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
    _playing = false;
    _playerStateSubscription.cancel();
    _eventSubscription.cancel();
    await _setState(processingState: AudioProcessingState.stopped);
    await super.onStop();
  }*/

  @override
  Future<void> onStop() async {
    await _audioPlayer.pause();
    await _audioPlayer.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  @override
  Future<void> onAudioFocusLost(AudioInterruption interruption) async {
    // We override the default behaviour to duck when appropriate.
    // First, remember if we were playing when the interruption occurred.
    if (_audioPlayer.playing) _interrupted = true;
    // If another app wants to take over the audio focus, we either pause (e.g.
    // during a phonecall) or duck (e.g. if Maps Navigator starts speaking).
    if (interruption == AudioInterruption.temporaryDuck) {
      _audioPlayer.setVolume(0.5);
    } else {
      onPause();
    }
  }

  @override
  Future<void> onAudioFocusGained(AudioInterruption interruption) async {
    // Restore normal playback depending on whether we paused or ducked.
    switch (interruption) {
      case AudioInterruption.temporaryPause:
        // Resume playback again. But only if we *were* originally playing at
        // the time the phone call came through. If we were paused when the
        // phone call came, we shouldn't suddenly start playing when they hang
        // up.
        if (!_audioPlayer.playing && _interrupted) onPlay();
        break;
      case AudioInterruption.temporaryDuck:
        // Resume normal volume after a duck.
        _audioPlayer.setVolume(1.0);
        break;
      default:
        break;
    }
    _interrupted = false;
  }

  /*Future<void> _setState({
    AudioProcessingState processingState,
    Duration position,
    Duration bufferedPosition,
  }) async {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position;
    }
    await AudioServiceBackground.setState(
      controls: getControls(),
      systemActions: [MediaAction.seekTo],
      processingState:
          processingState ?? AudioServiceBackground.state.processingState,
      playing: _playing,
      position: position,
      bufferedPosition: bufferedPosition ?? position,
      speed: _audioPlayer.speed,
    );
  }*/

  /*List<MediaControl> getControls() {
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
  }*/

  Future<String> _getStreamUrl() async {
    String url;
    if (_radioMode == true) {
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
    dynamic res;
    switch (name) {
      case 'set_song':
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
      case 'set_radio_mode':
        _radioMode = arguments;
        break;
      case 'get_radio_mode':
        res = _radioMode;
        break;
      case 'set_session_id':
        _sessionId = arguments;
        break;
      case 'start_song_listener':
        periodicFetchSongNowPlaying();
        break;
      case 'stop_song_listener':
        _t?.cancel();
        break;
    }
    await super.onCustomAction(name, arguments);
    return res;
  }

  void setNotification() {
    AudioServiceBackground.setMediaItem(MediaItem(
        id: _song.streamLink,
        album: _radioMode ? radioIcon : songIcon,
        title: _song.name.isEmpty ? 'Titre non disponible' : _song.name,
        artist: _song.artist.isEmpty ? 'Artiste non disponible' : _song.artist,
        artUri: _song.coverLink,
        duration: _song.duration ?? null));
  }
}
