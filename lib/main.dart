import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';

import 'models/song.dart';

import 'widgets/drawer.dart';
import 'services/identification.dart';
import 'widgets/now_playing.dart';
import 'widgets/player.dart';
import 'widgets/song_airing_notifier.dart';
import 'utils.dart' show handleLink, ErrorDisplay;

enum UniLinksType { string, uri }

void main() => runApp(BideApp());

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  Future<SongNowPlaying> _songNowPlaying;
  Exception _e;
  SongAiringNotifier _songAiring;

  void initSongFetch() {
    _e = null;
    _songAiring = SongAiringNotifier();
    _songAiring.addListener(() {
      setState(() {
        _songNowPlaying = _songAiring.songNowPlaying;
        if (_songNowPlaying == null)
          _e = _songAiring.e;
        else {
          AudioService.customAction('get_radio_mode').then((radioMode) {
            if (radioMode == true)
              _songAiring.songNowPlaying.then((song) async {
                await AudioService.customAction('set_song', song.toJson());
              });
          });
        }
      });
    });
    _songAiring.periodicFetchSongNowPlaying();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    autoLogin();
    initPlatformState();
    initSongFetch();

    super.initState();
  }

  // DEEP LINKING
  /////////////////////////////////////////////////////////////////////////
  String _deepLink;
  UniLinksType _type = UniLinksType.string;
  StreamSubscription _sub;

  Future<Null> initUniLinks() async {
    // Attach a listener to the stream
    _sub = getLinksStream().listen((String link) {
      // Parse the link and warn the user, if it is not correct
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
    });
  }

  initPlatformState() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    } else {
      await initPlatformStateForUriUniLinks();
    }
  }

  /// An implementation using a [String] link
  initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _deepLink = link ?? null;
      });
    }, onError: (err) {
      print('Failed to get deep link: $err.');
      if (!mounted) return;
      setState(() {
        _deepLink = null;
      });
    });

    // Get the latest link
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
    }

    if (!mounted) return;

    setState(() {
      _deepLink = initialLink;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriUniLinks() async {
    // Attach a listener to the Uri links stream
    _sub = getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _deepLink = uri?.toString() ?? null;
      });
    }, onError: (err) {
      print('Failed to get latest link: $err.');
      if (!mounted) return;
      setState(() {
        _deepLink = null;
      });
    });

    // Attach a second listener to the stream
    getUriLinksStream().listen((Uri uri) {
      print('got uri: ${uri?.path} ${uri?.queryParametersAll}');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest Uri
    Uri initialUri;
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialUri = await getInitialUri();
      print('initial uri: ${initialUri?.path}'
          ' ${initialUri?.queryParametersAll}');
      initialLink = initialUri?.toString();
    } on PlatformException {
      initialUri = null;
      initialLink = 'Failed to get initial uri.';
    } on FormatException {
      initialUri = null;
      initialLink = 'Bad parse the initial link as Uri.';
    }

    if (!mounted) return;

    setState(() {
      _deepLink = initialLink;
    });
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
    WidgetsBinding.instance.removeObserver(this);
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        _songAiring.periodicFetchSongNowPlaying();
        await AudioService.customAction('stop_song_listener');
        break;
      case AppLifecycleState.inactive:
        await AudioService.customAction('start_song_listener');
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
          RaisedButton.icon(
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
    Widget body;
    Widget nowPlayingWidget;

    FlutterStatusbarcolor.setStatusBarColor(Colors.orange);
    FlutterStatusbarcolor.setNavigationBarColor(Colors.orange);

    if (_e != null && _songNowPlaying == null)
      nowPlayingWidget = refreshNowPlayingSongButton();
    else if (_songNowPlaying == null)
      nowPlayingWidget = Center(child: CircularProgressIndicator());
    else
      nowPlayingWidget = NowPlayingCard(_songNowPlaying);

    //if the app is launched from deep linking, try to fetch the widget that
    //match the url
    if (_deepLink != null) {
      body = handleLink(_deepLink, context);
    }

    //no url match from deep link or not launched from deep link
    if (body == null)
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: AppBar(title: Text("Bide et Musique")), // SongNowPlayingAppBar(orientation, _songNowPlaying),
              bottomNavigationBar: SizedBox(
                  height: 60,
                  child: BottomAppBar(
                      child: PlayerWidget(orientation, _songNowPlaying))),
              drawer: DrawerWidget(),
              body: nowPlayingWidget);
        } else {
          return Scaffold(
              appBar: AppBar(title: Text("Bide et Musique")), //SongNowPlayingAppBar(orientation, _songNowPlaying),
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
                        PlayerWidget(orientation, _songNowPlaying),
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
                  child: PlayerWidget(Orientation.portrait, _songNowPlaying))),
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
        home: AudioServiceWidget(
          child: home,
        ));
  }
}
