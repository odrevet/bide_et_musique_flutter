import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'drawerWidget.dart';
import 'playerWidget.dart';
import 'nowPlaying.dart';

void main() => runApp(new BideApp());

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => new _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  PlaybackState _state;
  StreamSubscription _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    connect();
    AudioService.start(
      backgroundTask: backgroundAudioPlayerTask,
      resumeOnClick: true,
      androidNotificationChannelName: 'Bide&Musique',
      notificationColor: 0xFFFED152,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  }

  @override
  void dispose() {
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        connect();
        break;
      case AppLifecycleState.paused:
        disconnect();
        break;
      default:
        break;
    }
  }

  void connect() async {
    await AudioService.connect();
    if (_playbackStateSubscription == null) {
      _playbackStateSubscription = AudioService.playbackStateStream
          .listen((PlaybackState playbackState) {
        setState(() {
          _state = playbackState;
        });
      });
    }
  }

  void disconnect() {
    if (_playbackStateSubscription != null) {
      _playbackStateSubscription.cancel();
      _playbackStateSubscription = null;
    }
    AudioService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    var playerControls = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _state?.basicState == BasicPlaybackState.playing
          ? [pauseButton(), stopButton()]
          : _state?.basicState == BasicPlaybackState.paused
              ? [playButton(), stopButton()]
              : [playButton()],
    );

    var title = 'Bide&Musique';

    var home = Scaffold(
        appBar: AppBar(title: Text(title)),
        bottomNavigationBar:
            BottomAppBar(child: playerControls, color: Colors.orange),
        drawer: DrawerWidget(),
        body: NowPlayingWidget());

    return MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          secondaryHeaderColor: Colors.deepOrange,
          canvasColor: Color.fromARGB(190, 245, 240, 220),
        ),
        home: home);
  }

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: AudioService.stop,
      );
}
