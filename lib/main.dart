import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer.dart';
import 'player.dart';
import 'nowPlaying.dart';
import 'identification.dart';

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

    //auto login
    autoLogin();
  }

  void autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool rememberIdents = prefs.getBool('rememberIdents') ?? false;
    bool autoConnect = prefs.getBool('autoConnect') ?? false;

    if (rememberIdents && autoConnect) {
      var login = prefs.getString('login') ?? '';
      var password = prefs.getString('password') ?? '';

      sendIdent(login, password);
    }
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
              : [
                  Padding(
                      padding: const EdgeInsets.all(8), child: startButton())
                ],
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
          canvasColor: Color(0xFFF5EEE5),
        ),
        home: home);
  }

  final double _iconSize = 48.0;

  RaisedButton startButton() => RaisedButton.icon(
        icon: Icon(Icons.radio, size: _iconSize),
        label: Text("Écouter la radio",
            style: TextStyle(
              fontSize: 20.0,
            )),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        color: Colors.orangeAccent,
        onPressed: () async {
          bool success = await AudioService.start(
            backgroundTask: backgroundAudioPlayerTask,
            resumeOnClick: true,
            androidNotificationChannelName: 'Bide&Musique',
            notificationColor: 0xFFFFFFFF,
            androidNotificationIcon: 'mipmap/ic_launcher',
          );
          if (success) {
            StreamPlayer().resetSongLink();
            await AudioService.play();
            await AudioService.customAction('setNotification');
          }
        },
      );

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: _iconSize,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: _iconSize,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: _iconSize,
        onPressed: AudioService.stop,
      );
}
