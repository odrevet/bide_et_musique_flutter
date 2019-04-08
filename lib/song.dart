import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:audioplayer/audioplayer.dart';
import 'utils.dart';

class Song {
  String id;
  String title;
  String artist;

  Song();
}

class SongCardWidget extends StatelessWidget {
  Song song;
  SongCardWidget({Key key, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (context) => new SongPageWidget(
                    song: song, lyrics: fetchLyrics(song.id))));
      },
      child: Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: new NetworkImage(
              'http://www.bide-et-musique.com/images/pochettes/' +
                  song.id +
                  '.jpg'),
        )),
      ),
    );
  }
}

Future<String> fetchLyrics(String songId) async {
  final url = 'http://www.bide-et-musique.com/song/' + songId + '.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var lyricsHTML = document.getElementsByClassName('paroles')[0].innerHtml;
    return stripTags(lyricsHTML);
  } else {
    throw Exception('Failed to load post');
  }
}

class SongPageWidget extends StatelessWidget {
  Song song;
  Future<String> lyrics;

  SongPageWidget({Key key, this.song, this.lyrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: lyrics,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(String lyrics) {
    return new Container(
      child: Center(
          child: Column(
        children: <Widget>[
          Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: Container(
                    decoration: new BoxDecoration(
                        image: new DecorationImage(
                      fit: BoxFit.fill,
                      alignment: FractionalOffset.topCenter,
                      image: new NetworkImage(
                          'http://www.bide-et-musique.com/images/pochettes/' +
                              song.id +
                              '.jpg'),
                    )),
                  )),
                  Expanded(
                    child: Text('TODO'),//SongPlayerWidget(song.id),
                  ),
                ],
              )),
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
                child: Text(lyrics,
                    style: new TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w600))),
          ),
        ],
      )),
    );
  }
}

////////////////////////////////
enum PlayerState { stopped, playing, paused }

class SongPlayerWidget extends StatefulWidget {
  final String _songId;
  SongPlayerWidget(this._songId, {Key key}) : super(key: key);

  @override
  _SongPlayerWidgetState createState() => _SongPlayerWidgetState(this._songId);
}

class _SongPlayerWidgetState extends State<SongPlayerWidget> {
  final String _songId;

  Duration duration;
  Duration position;
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  StreamSubscription _audioPlayerStateSubscription;

  _SongPlayerWidgetState(this._songId);

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
          new Row(mainAxisSize: MainAxisSize.min, children: [playStopButton]),
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
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = audioPlayer.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        setState(() {
          position = duration;
        });
      }
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer
        .play('http://www.bide-et-musique.com/stream_' + this._songId + '.php');
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = new Duration();
    });
  }
}
