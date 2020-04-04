import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nowPlaying.dart';
import 'song.dart';
import 'utils.dart';

enum PlayerMode { radio, song, off }

abstract class PlayerState {
  static PlayerMode playerMode = PlayerMode.off;
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
  AudioServiceBackground.run(() => StreamPlayer());
}

class SongAiringNotifier extends ChangeNotifier {
  static final SongAiringNotifier _singleton = SongAiringNotifier._internal();

  factory SongAiringNotifier() {
    return _singleton;
  }

  SongAiringNotifier._internal();

  Future<SongNowPlaying> songNowPlaying;
  Exception e;

  void periodicFetchSongNowPlaying() {
    try {
      songNowPlaying = fetchNowPlaying();
      songNowPlaying.then((s) async {
        notifyListeners();
        int delay = (s.duration.inSeconds -
                (s.duration.inSeconds * s.elapsedPcent / 100))
            .ceil();
        Timer(Duration(seconds: delay), () {
          periodicFetchSongNowPlaying();
        });
      }, onError: (e) {
        this.e = e;
        songNowPlaying = null;
        notifyListeners();
      });
    } catch (e) {
      this.e = e;
      songNowPlaying = null;
      notifyListeners();
    }
  }
}

class StreamPlayer extends BackgroundAudioTask {
  Song _song;
  String _mode;
  AudioPlayer audioPlayer = AudioPlayer();
  Completer _completer = Completer();
  BasicPlaybackState _skipState;
  bool _playing = false;
  String latestId;

  //final _queue = <MediaItem>[];
  //int _queueIndex = -1;
  //bool get hasNext => _queueIndex + 1 < _queue.length;
  //bool get hasPrevious => _queueIndex > 0;
  //MediaItem get mediaItem => _queue[_queueIndex];

  BasicPlaybackState _stateToBasicState(AudioPlaybackState state) {
    switch (state) {
      case AudioPlaybackState.none:
        return BasicPlaybackState.none;
      case AudioPlaybackState.stopped:
        return BasicPlaybackState.stopped;
      case AudioPlaybackState.paused:
        return BasicPlaybackState.paused;
      case AudioPlaybackState.playing:
        return BasicPlaybackState.playing;
      /*case AudioPlaybackState.buffering:
        return BasicPlaybackState.buffering;*/
      case AudioPlaybackState.connecting:
        return _skipState ?? BasicPlaybackState.connecting;
      case AudioPlaybackState.completed:
        return BasicPlaybackState.stopped;
      default:
        throw Exception("Illegal state");
    }
  }

  @override
  Future<void> onStart() async {
    var playerStateSubscription = audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    var eventSubscription = audioPlayer.playbackEventStream.listen((event) {
      final state = _stateToBasicState(event.state);
      if (state != BasicPlaybackState.stopped) {
        _setState(
          state: state,
          position: event.position.inMilliseconds,
        );
      }
    });

    //AudioServiceBackground.setQueue(_queue);
    //await onSkipToNext();
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
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing)
      onPause();
    else
      onPlay();
  }

/*
  @override
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
        ? BasicPlaybackState.skippingToNext
        : BasicPlaybackState.skippingToPrevious;
    await _audioPlayer.setUrl(mediaItem.id);
    _skipState = null;
    // Resume playback if we were playing
    if (_playing) {
      onPlay();
    } else {
      _setState(state: BasicPlaybackState.paused);
    }
  }
*/
  @override
  void onPlay() async {
    String url = await _getStreamUrl();

    if (url != latestId ||
        AudioServiceBackground.state.basicState != BasicPlaybackState.paused) {
      await audioPlayer.setUrl(url);
    }

    audioPlayer.play();
    _playing = true;
    latestId = url;
    await AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
  }

  @override
  void onPause() async {
    audioPlayer.pause();
    _playing = false;

    await AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused);
  }

  @override
  void onStop() async {
    audioPlayer.stop();
    this._song = null;
    _playing = false;
    _completer.complete();
    await AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.stopped);
  }

  @override
  void onSeekTo(int position) {
    audioPlayer.seek(Duration(milliseconds: position));
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  void _setState({@required BasicPlaybackState state, int position}) {
    if (position == null) {
      position = audioPlayer.playbackEvent.position.inMilliseconds;
    }
    AudioServiceBackground.setState(
      controls: getControls(state),
      systemActions: [MediaAction.seekTo],
      basicState: state,
      position: position,
    );
  }

  List<MediaControl> getControls(BasicPlaybackState state) {
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
  void onCustomAction(String name, dynamic arguments) {
    switch (name) {
      case 'song':
        Map songMap = arguments;
        this._song = Song(
            id: songMap['id'],
            title: songMap['title'],
            artist: songMap['artist'],
            info: songMap['info'],
            duration: songMap['duration'] == null
                ? null
                : Duration(seconds: songMap['duration']));
        break;
      case 'mode':
        _mode = arguments;
        break;
      case 'resetSong':
        this._song = null;
        break;
      case 'setNotification':
        this.setNotification();
        break;
    }
    super.onCustomAction(name, arguments);
  }

  void setNotification() {
    AudioServiceBackground.setMediaItem(MediaItem(
        id: _song.streamLink,
        album: 'Bide et Musique',
        genre: _song.info,
        title: _song.name.isEmpty ? 'Titre non disponible' : _song.name,
        artist: _song.artist.isEmpty ? 'Artiste non disponible' : _song.artist,
        artUri: _song.coverLink,
        duration: _song.duration?.inMilliseconds));
  }
}
