import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_radio/flutter_radio.dart';
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

class StreamPlayer extends BackgroundAudioTask {
  Song _song;
  bool _playing;
  Completer _completer = Completer();
  StreamNotificationUpdater streamNotificationUpdater =
      StreamNotificationUpdater();

  @override
  Future<void> onStart() async {
    audioStart();
    await _completer.future;
  }

  @override
  void onPlay() async {
    String url = await _getStreamUrl();
    FlutterRadio.play(url: url);
    _playing = true;
    await AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
  }

  @override
  void onPause() async {
    String url = await _getStreamUrl();
    FlutterRadio.playOrPause(url: url);
    _playing = false;

    await AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused);
  }

  @override
  void onStop() async {
    FlutterRadio.stop();
    this._song = null;
    _playing = false;
    _completer.complete();
    await AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.stopped);
  }

  Future<void> audioStart() async {
    await FlutterRadio.audioStart();
  }

  void setSong(Song song) {
    this._song = song;
  }

  void togglePlay() {
    _playing ? onPause() : onPlay();
  }

  String getSongLinkId() {
    return _song == null ? null : _song.id;
  }

  void _resetSong() {
    _song = null;
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
          artUri: '$baseUri/images/pochettes/${_song.id}.jpg');
      AudioServiceBackground.setMediaItem(mediaItem);
    }
  }

  Future<String> _getStreamUrl() async {
    String url;
    if (this._song == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
      url = radioHiQuality == true ? stream_hq : stream_lq;
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
        this.setSong(Song(
            id: songMap['id'],
            title: songMap['title'],
            artist: songMap['artist']));
        break;
      case 'resetSong':
        _resetSong();
        break;
      case 'setNotification':
        this.setNotification();
        break;
    }
    super.onCustomAction(name, arguments);
  }
}

///As Song data cannot be retreive from the stream,
///This Class fetch song from the web site
class StreamNotificationUpdater {
  Timer timer;

  StreamNotificationUpdater();

  void setMediaItemFromSong(SongLink song) {
    var mediaItem = MediaItem(
        id: song.id,
        album: song.program,
        title: song.title,
        artist: song.artist,
        artUri: '$baseUri/images/pochettes/${song.id}.jpg');
    AudioServiceBackground.setMediaItem(mediaItem);
  }

  void start() {
    fetchNowPlaying().then((song) {
      setMediaItemFromSong(song);
    });

    timer = Timer.periodic(Duration(seconds: 45), (Timer timer) async {
      fetchNowPlaying().then((song) {
        setMediaItemFromSong(song);
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
