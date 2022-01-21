import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../player.dart' show audioHandler;
import '../services/identification.dart';
import '../widgets/drawer.dart';
import '../widgets/error_display.dart';
import '../widgets/now_airing.dart';
import '../widgets/player.dart';
import '../widgets/song_airing_notifier.dart';
import '../widgets/song_information.dart';

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  Future<SongAiring>? _songNowAiring;
  Exception? _e;
  late SongAiringNotifier _songAiring;

  void initSongFetch() {
    _e = null;
    _songAiring = SongAiringNotifier();
    _songAiring.addListener(() {
      setState(() {
        _songNowAiring = _songAiring.songAiring;
        if (_songNowAiring == null)
          _e = _songAiring.e;
        else {
          audioHandler.customAction('get_radio_mode').then((radioMode) {
            if (radioMode == true) {
              _songAiring.songAiring!.then((song) async {
                await audioHandler.customAction('set_song', song.toJson());
              });
            }
          });
        }
      });
    });
    _songAiring.periodicFetchSongNowAiring();
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
        _songAiring.periodicFetchSongNowAiring();
        //await audioHandler.customAction('stop_song_listener', Map());
        break;
      default:
        break;
    }
  }

  Widget refreshNowAiringSongButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ErrorDisplay(_e),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _songAiring.periodicFetchSongNowAiring();
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
    Widget nowAiringWidget;

    if (_e != null && _songNowAiring == null)
      nowAiringWidget = refreshNowAiringSongButton();
    else if (_songNowAiring == null)
      nowAiringWidget = Center(child: CircularProgressIndicator());
    else
      nowAiringWidget = NowAiringCard(_songNowAiring!);

    //no url match from deep link or not launched from deep link
    if (body == null)
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: SongNowAiringAppBar(orientation, _songNowAiring),
              bottomNavigationBar: SizedBox(
                  height: 60,
                  child: BottomAppBar(
                      child: PlayerWidget(orientation, _songNowAiring))),
              drawer: DrawerWidget(),
              body: nowAiringWidget);
        } else {
          return Scaffold(
              appBar: SongNowAiringAppBar(orientation, _songNowAiring),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  Expanded(child: nowAiringWidget),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        FutureBuilder<SongAiring>(
                            future: _songNowAiring,
                            builder: (BuildContext context,
                                AsyncSnapshot<SongAiring> snapshot) {
                              if (snapshot.hasData)
                                return SongInformations(
                                    song: snapshot.data, compact: true);
                              else
                                return CircularProgressIndicator();
                            }),
                        PlayerWidget(orientation, _songNowAiring!),
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
                  child: PlayerWidget(Orientation.portrait, _songNowAiring!))),
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
