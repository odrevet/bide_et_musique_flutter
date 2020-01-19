import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nowPlaying.dart';
import 'song.dart';
import 'utils.dart';

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

///As Song data cannot be retrieve from the stream,
///This Class fetch song from the web site
class StreamNotificationUpdater {
  Timer timer;

  StreamNotificationUpdater();

  void setMediaItemFromSongLink(SongLink songLink) {
    var mediaItem = MediaItem(
        id: songLink.id,
        album: songLink.program,
        title: songLink.title,
        artist: songLink.artist,
        artUri: '$baseUri/images/pochettes/${songLink.id}.jpg');
    AudioServiceBackground.setMediaItem(mediaItem);
  }

  void start() {
    fetchNowPlaying().then((song) {
      setMediaItemFromSongLink(song);
    });

    timer = Timer.periodic(Duration(seconds: 45), (Timer timer) async {
      fetchNowPlaying().then((song) {
        setMediaItemFromSongLink(song);
      });
    });
  }

  void stop() {
    if (timer != null) timer.cancel();
  }

  void dispose() {
    stop();
  }
}


class StreamPlayer extends BackgroundAudioTask {
  Song _song;
  AudioPlayer _audioPlayer = new AudioPlayer();
  Completer _completer = Completer();
  StreamNotificationUpdater streamNotificationUpdater =
  StreamNotificationUpdater();
  BasicPlaybackState _skipState;
  bool _playing;
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
      case AudioPlaybackState.buffering:
        return BasicPlaybackState.buffering;
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
    var playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackCompleted();
    });
    var eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
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
    await _audioPlayer.setUrl(url);
    _audioPlayer.play();
    _playing = true;
    await AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
  }

  @override
  void onPause() async {
    _audioPlayer.pause();
    _playing = false;

    await AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused);
  }

  @override
  void onStop() async {
    _audioPlayer.stop();
    this._song = null;
    _playing = false;
    _completer.complete();
    await AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.stopped);
  }

  @override
  void onSeekTo(int position) {
    _audioPlayer.seek(Duration(milliseconds: position));
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  void _setState({@required BasicPlaybackState state, int position}) {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position.inMilliseconds;
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
    if (this._song == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
      int relay = prefs.getInt('relay') ?? 1;
      int port = radioHiQuality ? 9100 : 9200;

      url = 'http://relay$relay.$site:$port';
    } else {
      url = '$baseUri/stream_${this._song.id}.php';
    }
    return url;
  }

  @override
  void onCustomAction(String name, arguments) {
    switch (name) {
      case 'song':
        Map songMap = arguments;
        this._song = Song(
            id: songMap['id'],
            title: songMap['title'],
            artist: songMap['artist'],
            duration: Duration(seconds: songMap['duration']));
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
    if (this._song == null) {
      streamNotificationUpdater.start();
    } else {
      streamNotificationUpdater.stop();
      var title = _song.title.isEmpty ? 'Titre non disponible' : _song.title;
      var artist =
      _song.artist.isEmpty ? 'Artiste non disponible' : _song.artist;

      var mediaItem = MediaItem(
          id: _song.id,
          album: 'Bide et Musique',
          title: title,
          artist: artist,
          artUri: _song.coverLink);
      AudioServiceBackground.setMediaItem(mediaItem);
    }
  }
}
