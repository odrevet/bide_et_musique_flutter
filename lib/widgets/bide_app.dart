import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/identification.dart';
import '../utils.dart' show ErrorDisplay;
import '../widgets/drawer.dart';
import '../widgets/now_playing.dart';
import '../widgets/player.dart';
import '../widgets/song.dart';
import '../widgets/song_airing_notifier.dart';
import '../player.dart' show audioHandler;

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  Future<SongNowPlaying>? _songNowPlaying;
  Exception? _e;
  late SongAiringNotifier _songAiring;

  void initSongFetch() {
    _e = null;
    _songAiring = SongAiringNotifier();
    _songAiring.addListener(() {
      setState(() {
        _songNowPlaying = _songAiring.songNowPlaying;
        if (_songNowPlaying == null)
          _e = _songAiring.e;
        else {
          audioHandler.customAction('get_radio_mode').then((radioMode) {
            if (radioMode == true)
              _songAiring.songNowPlaying!.then((song) async {
                await audioHandler.customAction('set_song', song.toJson());
              });
          });
        }
      });
    });
    _songAiring.periodicFetchSongNowPlaying();
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    autoLogin();
    initSongFetch();

    super.initState();
  }

  void autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool rememberIdents = prefs.getBool('rememberIdents') ?? false;
    bool autoConnect = prefs.getBool('autoConnect') ?? false;

    if (rememberIdents && autoConnect) {
      var login = prefs.getString('login') ?? '';
      var password = prefs.getString('password') ?? '';

      sendIdentifiers(login, password);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        _songAiring.periodicFetchSongNowPlaying();
        await AudioService.customAction('stop_song_listener', Map());
        break;
      case AppLifecycleState.inactive:
        await AudioService.customAction('start_song_listener', Map());
        break;
      default:
        break;
    }
  }

  Widget refreshNowPlayingSongButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ErrorDisplay(_e),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _songAiring.periodicFetchSongNowPlaying();
            },
            label: Text('Ré-essayer maintenant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    Widget? body;
    Widget nowPlayingWidget;

    FlutterStatusbarcolor.setStatusBarColor(Colors.orange);
    FlutterStatusbarcolor.setNavigationBarColor(Colors.orange);

    if (_e != null && _songNowPlaying == null)
      nowPlayingWidget = refreshNowPlayingSongButton();
    else if (_songNowPlaying == null)
      nowPlayingWidget = Center(child: CircularProgressIndicator());
    else
      nowPlayingWidget = NowPlayingCard(_songNowPlaying!);

    //no url match from deep link or not launched from deep link
    if (body == null)
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: SongNowPlayingAppBar(orientation, _songNowPlaying!),
              bottomNavigationBar: SizedBox(
                  height: 60,
                  child: BottomAppBar(
                      child: PlayerWidget(orientation, _songNowPlaying!))),
              drawer: DrawerWidget(),
              body: nowPlayingWidget);
        } else {
          return Scaffold(
              appBar: SongNowPlayingAppBar(orientation, _songNowPlaying!),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  Expanded(child: nowPlayingWidget),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        FutureBuilder<SongNowPlaying>(
                            future: _songNowPlaying,
                            builder: (BuildContext context,
                                AsyncSnapshot<SongNowPlaying> snapshot) {
                              if (snapshot.hasData)
                                return SongInformations(
                                    song: snapshot.data, compact: true);
                              else
                                return CircularProgressIndicator();
                            }),
                        PlayerWidget(orientation, _songNowPlaying!),
                      ],
                    ),
                  )
                ],
              ));
        }
      });
    else {
      home = Scaffold(
          bottomNavigationBar: SizedBox(
              height: 60,
              child: BottomAppBar(
                  child: PlayerWidget(Orientation.portrait, _songNowPlaying!))),
          body: body);
    }

    return MaterialApp(
        title: 'Bide&Musique',
        theme: ThemeData(
            primarySwatch: Colors.orange,
            secondaryHeaderColor: Colors.deepOrange,
            bottomAppBarColor: Colors.orange,
            canvasColor: Color.fromARGB(0xE5, 0xF5, 0xEE, 0xE5),
            dialogBackgroundColor: Color.fromARGB(0xE5, 0xF5, 0xEE, 0xE5),
            buttonTheme: ButtonThemeData(
                buttonColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)))),
        home: home);
  }
}
