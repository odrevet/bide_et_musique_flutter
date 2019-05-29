import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_radio/flutter_radio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

String streamingId;

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
            var song = SongLink(
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
  SongLink _songLink;
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

  void setSong(SongLink songLink) {
    this._songLink = songLink;
    streamingId = songLink.id;
  }

  void togglePlay() {
    _playing ? pause() : play();
  }

  void setNotification() {
    if (this._songLink == null) {
      streamNotificationUpdater.start();
    } else {
      streamNotificationUpdater.stop();
      var mediaItem = MediaItem(
          id: 'bm_stream',
          album: 'Bide et Musique',
          title: _songLink.title,
          artist: _songLink.artist,
          artUri: '$baseUri/images/pochettes/${_songLink.id}.jpg');
      AudioServiceBackground.setMediaItem(mediaItem);
    }
  }

  Future<String> getStreamUrl() async {
    String url;
    if (this._songLink == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
      url = radioHiQuality == true ? stream_hq : stream_lq;
    } else {
      url = '$baseUri/stream_${this._songLink.id}.php';
    }
    return url;
  }

  void play() async {
    String url = await getStreamUrl();
    FlutterRadio.play(url: url);
    _playing = true;
    await AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing);
  }

  void pause() async {
    String url = await getStreamUrl();
    FlutterRadio.playOrPause(url: url);
    _playing = false;

    await AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused);
  }

  void stop() async {
    FlutterRadio.stop();
    this._songLink = null;
    _playing = false;
    _completer.complete();
    await AudioServiceBackground.setState(
        controls: [], basicState: BasicPlaybackState.stopped);
  }
}

///As Song data cannot be retreive from the stream,
///This Class fetch song information from the web site
class StreamNotificationUpdater {
  Timer timer;

  StreamNotificationUpdater();

  void setMediaItemFromSong(SongLink song) {
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
