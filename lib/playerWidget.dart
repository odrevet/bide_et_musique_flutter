import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayer/audioplayer.dart';

enum PlayerState { stopped, playing, paused }

class PlayerWidget extends StatefulWidget {
  PlayerWidget({Key key}) : super(key: key);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;

  get isPaused => playerState == PlayerState.paused;

  StreamSubscription _audioPlayerStateSubscription;

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
          onPressed: isPlaying || isPaused ? () => stop() : null,
          iconSize: 80.0,
          icon: new Icon(Icons.stop),
          color: Colors.orange);
    } else {
      playStopButton = new IconButton(
          onPressed: isPlaying ? null : () => play(),
          iconSize: 80.0,
          icon: new Icon(Icons.play_arrow),
          color: Colors.orange);
    }

    return new Container(
        padding: new EdgeInsets.all(16.0),
        child: new Column(mainAxisSize: MainAxisSize.min, children: [
          new Row(mainAxisSize: MainAxisSize.min, children: [
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
  }

  @override
  void dispose() {
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  void initAudioPlayer() {
    audioPlayer = new AudioPlayer();
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
    }, onError: (msg) {
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
