import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_radio/flutter_radio.dart';
import 'utils.dart';
import 'song.dart';
import 'nowPlaying.dart';

Future<void> audioStart() async {
  await FlutterRadio.audioStart();
}

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

void backgroundAudioPlayerTask() async {
  StreamPlayer player = StreamPlayer();
  AudioServiceBackground.run(
      onStart: player.start,
      onPlay: player.play,
      onPause: player.pause,
      onStop: player.stop,
      onClick: (MediaButton button) => player.togglePlay(),
      onCustomAction: (String name, dynamic arguments) {
        switch (name) {
          case 'song':
            Map songMap = arguments;
            var song = Song(
                id: songMap['id'],
                title: songMap['title'],
                artist: songMap['artist']);
            player.setSong(song);
            break;
          case 'setNotification':
            player.setNotification();
            break;
        }
      });
}

class StreamPlayer {
  Song _song;
  bool _playing;
  Completer _completer = Completer();
  StreamNotificationUpdater streamNotificationUpdater =
      StreamNotificationUpdater();

  Future<void> start() async {
    audioStart();
    await _completer.future;
  }

  Future<void> audioStart() async {
    await FlutterRadio.audioStart();
  }

  void setSong(Song song) {
    this._song = song;
  }

  void togglePlay() {
    _playing ? pause() : play();
  }

  void setNotification() {
    if (this._song == null) {
      streamNotificationUpdater.start();
    } else {
      streamNotificationUpdater.stop();
      var mediaItem = MediaItem(
          id: 'bm_stream',
          album: 'Bide et Musique',
          title: _song.title,
          artist: _song.artist,
          artUri: '$baseUri/images/pochettes/${_song.id}.jpg');
      AudioServiceBackground.setMediaItem(mediaItem);
    }
  }

  String getStreamUrl() {
    String url;
    if (this._song == null) {
      url = 'http://relay2.bide-et-musique.com:9100';
    } else {
      url = '$baseUri/stream_${this._song.id}.php';
    }
    return url;
  }

  void play() async {
    String url = getStreamUrl();
    FlutterRadio.play(url: url);
    _playing = true;
    AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
  }

  void pause() {
    String url = getStreamUrl();
    FlutterRadio.playOrPause(url: url);
    _playing = false;

    AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused);
  }

  void stop() {
    FlutterRadio.stop();
    this._song = null;
    AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.stopped);
    _playing = false;
    _completer.complete();
  }
}

/**
 * Song data cannot be retreive in the stream info
 * This Class fetch song informations from the web site
 */
class StreamNotificationUpdater {
  Timer timer;

  StreamNotificationUpdater();

  void setMediaItemFromSong(Song song) {
    var mediaItem = MediaItem(
        id: 'bm_stream',
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
