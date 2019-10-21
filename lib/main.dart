import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';

import 'drawer.dart';
import 'identification.dart';
import 'nowPlaying.dart';
import 'player.dart';
import 'utils.dart' show handleLink;

enum UniLinksType { string, uri }

void main() => runApp(BideApp());

class BideApp extends StatefulWidget {
  @override
  _BideAppState createState() => _BideAppState();
}

class _BideAppState extends State<BideApp> with WidgetsBindingObserver {
  PlaybackState _state;
  StreamSubscription _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    connect();
    autoLogin();
    initPlatformState();
  }

  // DEEP LINKING
  /////////////////////////////////////////////////////////////////////////
  String _latestLink = 'Unknown';
  Uri _latestUri;
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
        _latestLink = link ?? 'Unknown';
        _latestUri = null;
        try {
          if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        _latestUri = null;
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
    Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
      if (initialLink != null) initialUri = Uri.parse(initialLink);
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
      initialUri = null;
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
      initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestLink = initialLink;
      _latestUri = initialUri;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriUniLinks() async {
    // Attach a listener to the Uri links stream
    _sub = getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _latestUri = uri;
        _latestLink = uri?.toString() ?? 'Unknown';
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestUri = null;
        _latestLink = 'Failed to get latest link: $err.';
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

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestUri = initialUri;
      _latestLink = initialLink;
    });
  }

  /////////////////////////////////////////////////////////////////////////

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

    Widget home;

    Widget body;
    if (_latestLink != null) {
      body = handleLink(_latestLink, context);
    }

    if (body == null)
      home = OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return Scaffold(
              appBar: AppBar(title: Text(title)),
              bottomNavigationBar: BottomAppBar(
                  child: playerControls),
              drawer: DrawerWidget(),
              body: NowPlayingWidget());
        } else {
          return Scaffold(
              appBar: AppBar(title: Text(title)),
              drawer: DrawerWidget(),
              body: Row(
                children: <Widget>[
                  NowPlayingWidget(),
                  Expanded(child: playerControls)
                ],
              ));
        }
      });
    else
      home = Scaffold(
          bottomNavigationBar: BottomAppBar(
              child: playerControls),
          body: body);

    return MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          buttonColor: Colors.orangeAccent,
          secondaryHeaderColor: Colors.deepOrange,
          bottomAppBarColor: Colors.orange,
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
        onPressed: () async {
          bool success = await AudioService.start(
            backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
            resumeOnClick: true,
            androidNotificationChannelName: 'Bide&Musique',
            notificationColor: 0xFFFFFFFF,
            androidNotificationIcon: 'mipmap/ic_launcher',
          );
          if (success) {
            await AudioService.customAction('resetSong');
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
