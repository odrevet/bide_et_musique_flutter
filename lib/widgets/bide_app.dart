import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../player.dart' show audioHandler;
import '../services/identification.dart';
import '../widgets/airing_card.dart';
import '../widgets/drawer.dart';
import '../widgets/error_display.dart';
import '../widgets/player.dart';
import '../widgets/song_airing_notifier.dart';
import '../widgets/song_airing_title.dart';
import '../widgets/song_information.dart';

class BideApp extends StatefulWidget {
  const BideApp({Key? key}) : super(key: key);

  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  Future<SongAiring>? _songAiring;
  Exception? _e;
  late SongAiringNotifier _songAiringNotifier;

  void initSongFetch() {
    _e = null;
    _songAiringNotifier = SongAiringNotifier();
    _songAiringNotifier.addListener(() {
      setState(() {
        _songAiring = _songAiringNotifier.songAiring;
        if (_songAiring == null) {
          _e = _songAiringNotifier.e;
        } else {
          audioHandler.customAction('get_radio_mode').then((radioMode) {
            if (radioMode == true) {
              _songAiringNotifier.songAiring!.then((song) async {
                await audioHandler.customAction('set_song', song.toJson());
              });
            }
          });
        }
      });
    });
    _songAiringNotifier.periodicFetchSongAiring();
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
        _songAiringNotifier.periodicFetchSongAiring();
        break;
      default:
        break;
    }
  }

  Widget refreshAiringSongButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ErrorDisplay(_e),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _songAiringNotifier.periodicFetchSongAiring();
            },
            label: const Text('Ré-essayer maintenant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    Widget? body;
    Widget airingWidget;

    if (_e != null && _songAiring == null) {
      airingWidget = refreshAiringSongButton();
    } else if (_songAiring == null) {
      airingWidget = const Center(child: CircularProgressIndicator());
    } else {
      airingWidget = AiringCard(_songAiring!);
    }

    //no url match from deep link or not launched from deep link
    if (body == null) {
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: AppBar(title: SongAiringTitle(orientation, _songAiring)),
              bottomNavigationBar: SizedBox(
                  height: 60,
                  child: BottomAppBar(
                      child: PlayerWidget(orientation, _songAiring))),
              drawer: DrawerWidget(),
              body: airingWidget);
        } else {
          return Scaffold(
              appBar: AppBar(title: SongAiringTitle(orientation, _songAiring)),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  Expanded(child: airingWidget),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        FutureBuilder<SongAiring>(
                            future: _songAiring,
                            builder: (BuildContext context,
                                AsyncSnapshot<SongAiring> snapshot) {
                              if (snapshot.hasData) {
                                return SongInformations(
                                    song: snapshot.data, compact: true);
                              } else {
                                return const CircularProgressIndicator();
                              }
                            }),
                        PlayerWidget(orientation, _songAiring!),
                      ],
                    ),
                  )
                ],
              ));
        }
      });
    } else {
      home = Scaffold(
          bottomNavigationBar: SizedBox(
              height: 60,
              child: BottomAppBar(
                  child: PlayerWidget(Orientation.portrait, _songAiring!))),
          body: body);
    }

    return MaterialApp(
        title: 'Bide&Musique',
        theme: ThemeData(
            primarySwatch: Colors.orange,
            secondaryHeaderColor: Colors.deepOrange,
            bottomAppBarColor: Colors.orange,
            canvasColor: const Color.fromARGB(0xE5, 0xF5, 0xEE, 0xE5),
            dialogBackgroundColor: const Color.fromARGB(0xE5, 0xF5, 0xEE, 0xE5),
            buttonTheme: ButtonThemeData(
                buttonColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)))),
        home: home);
  }
}
