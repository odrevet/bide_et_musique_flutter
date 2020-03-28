import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

import 'drawer.dart';
import 'identification.dart';
import 'nowPlaying.dart';
import 'playerWidget.dart';
import 'utils.dart' show handleLink, errorDisplay;

enum UniLinksType { string, uri }

void main() => runApp(BideApp());

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  PlayerWidget _playerWidget;
  PlaybackState _playbackState;
  StreamSubscription _playbackStateSubscription;
  Future<SongNowPlaying> _songNowPlaying;
  Timer _timer;

  @override
  void initState() {
    periodicFetchSongNowPLaying();
    WidgetsBinding.instance.addObserver(this);
    connect();
    autoLogin();
    initPlatformState();
    _playerWidget = PlayerWidget(_songNowPlaying);

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

    // Attach a second listener to the stream
    getLinksStream().listen((String link) {
      print('got link: $link');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
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
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    if (_sub != null) _sub.cancel();
    _timer.cancel();
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
          _playbackState = playbackState;
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

  void periodicFetchSongNowPLaying() {
    try {
      setState(() {
        _songNowPlaying = fetchNowPlaying();
      });

      _songNowPlaying.then((songNowPlaying) {
        int delay = (songNowPlaying.duration.inSeconds -
                (songNowPlaying.duration.inSeconds *
                    songNowPlaying.elapsedPcent /
                    100))
            .ceil();
        Timer(Duration(seconds: delay), () {
          periodicFetchSongNowPLaying();
        });
      }, onError: (e) {
        _e = e;
        setState(() {
          _songNowPlaying = null;
        });
      });
    } catch (e) {
      _e = e;
      setState(() {
        _songNowPlaying = null;
      });
    }
  }

  var _e;

  Widget refreshNowPlayingSongButton() {
    return Center(
      child: Column(
        children: <Widget>[
          errorDisplay(_e),
          RaisedButton.icon(
            icon: Icon(Icons.refresh),
            onPressed: () => periodicFetchSongNowPLaying(),
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
    Widget nowPlayingWidget = _songNowPlaying == null
        ? refreshNowPlayingSongButton()
        : NowPlayingCard(_songNowPlaying);

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
              appBar: SongNowPlayingAppBar(_songNowPlaying),
              bottomNavigationBar: BottomAppBar(child: _playerWidget
                  /* Row(
                children: <Widget>[
                  _playerWidget, NowPlayingSongPosition(_songNowPlaying)
                  //NowPlayingPosition(_songNowPlaying)
                ],
              )*/
                  ),
              drawer: DrawerWidget(),
              body: nowPlayingWidget);
        } else {
          return Scaffold(
              appBar: SongNowPlayingAppBar(_songNowPlaying),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  Expanded(child: nowPlayingWidget),
                  Expanded(child: _playerWidget)
                ],
              ));
        }
      });
    else
      home = Scaffold(
          bottomNavigationBar: BottomAppBar(child: _playerWidget), body: body);

    return InheritedPlaybackState(
        playbackState: _playbackState,
        child: MaterialApp(
            title: 'Bide&Musique',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              buttonColor: Colors.orangeAccent,
              secondaryHeaderColor: Colors.deepOrange,
              bottomAppBarColor: Colors.orange,
              canvasColor: Color(0xFFF5EEE5),
            ),
            home: home));
  }
}
