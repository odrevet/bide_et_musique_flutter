import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_radio/flutter_radio.dart';

enum PlayerState { stopped, playing, paused }

class PlayerWidget extends StatefulWidget {
  PlayerWidget({Key key}) : super(key: key);

  final _PlayerWidgetState playerState = _PlayerWidgetState();

  stop() {
    playerState.stop();
    playerState._controller.stop();
  }

  @override
  State<StatefulWidget> createState() => playerState;
}

class _PlayerWidgetState extends State<PlayerWidget>
    with TickerProviderStateMixin {
  PlayerState playerState = PlayerState.stopped;
  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

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
    audioStart();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5500),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  Future<void> audioStart() async {
    await FlutterRadio.audioStart();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  void play() {
    var url = "http://relay2.bide-et-musique.com:9100";
    FlutterRadio.play(url: url);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  void stop() {
    FlutterRadio.stop();
    setState(() {
      playerState = PlayerState.stopped;
    });
  }
}
