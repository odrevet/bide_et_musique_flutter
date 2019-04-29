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
            Material(child: _buildPlayer()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    var playStopButton;
    if (isPlaying) {
      playStopButton = IconButton(
          onPressed: isPlaying || isPaused
              ? () {
                  _controller.stop();
                  stop();
                }
              : null,
          iconSize: 80.0,
          icon: Icon(Icons.stop),
          color: Colors.orange);
    } else {
      playStopButton = IconButton(
          onPressed: isPlaying
              ? null
              : () {
                  _controller.repeat();
                  play();
                },
          iconSize: 80.0,
          icon: Icon(Icons.play_arrow),
          color: Colors.orange);
    }

    return Container(
        child: Column(children: [
      Row(children: [
        RotationTransition(
          turns: _animation,
          child: Column(
            children: <Widget>[
              Image.asset('assets/vinyl_record.png', height: 80, width: 80),
            ],
          ),
        ),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
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
              TextSpan(
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5500),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
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
