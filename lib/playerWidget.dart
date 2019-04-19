import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum PlayerState { stopped, playing, paused }

class PlayerWidget extends StatefulWidget {
  PlayerWidget({Key key}) : super(key: key);

  final _PlayerWidgetState playerState = _PlayerWidgetState();

  stop(){
    playerState.stop();
    playerState._controller.stop();
  }


  @override
  //_PlayerWidgetState createState() => _PlayerWidgetState();
  State<StatefulWidget> createState() => playerState;
}

class _PlayerWidgetState extends State<PlayerWidget>
    with TickerProviderStateMixin {
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;

  get isPaused => playerState == PlayerState.paused;

  StreamSubscription _audioPlayerStateSubscription;

  AnimationController _controller;
  Animation _animation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Material(child: _buildPlayer()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    var playStopButton;
    if (isPlaying) {
      playStopButton = new IconButton(
          onPressed: isPlaying || isPaused
              ? () {
                  _controller.stop();
                  stop();
                }
              : null,
          iconSize: 80.0,
          icon: new Icon(Icons.stop),
          color: Colors.orange);
    } else {
      playStopButton = new IconButton(
          onPressed: isPlaying
              ? null
              : () {
                  _controller.repeat();
                  play();
                },
          iconSize: 80.0,
          icon: new Icon(Icons.play_arrow),
          color: Colors.orange);
    }

    return new Container(
        child: new Column(children: [
      new Row(children: [
        RotationTransition(
          turns: _animation,
          child: Column(
            children: <Widget>[
              Image.asset('assets/vinyl_record.png', height: 80, width: 80),
            ],
          ),
        ),
        RichText(
          text: new TextSpan(
            style: new TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                  text: 'ECOUTEZ',
                  style: TextStyle(
                    fontSize: 30.0,
                    color: Colors.orange,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  )),
              new TextSpan(
                  text: '\nLa radio',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.yellow,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  )),
            ],
          ),
        ),
        playStopButton
      ])
    ]));
  }

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5500),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    _controller.dispose();
    super.dispose();
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  void initAudioPlayer() {
    audioPlayer = new AudioPlayer();
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {}, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
      });
    });
  }

  Future play() async {
    await audioPlayer.play("http://relay2.bide-et-musique.com:9100");
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
    });
  }
}
