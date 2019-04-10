import 'dart:async';
import 'dart:ui';
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

/// information available on the song page
class SongInformations {
  String year;
  String length;
  String label;
  String reference;
  String presentation;
  String lyrics;

  SongInformations();
}

String extractSongId(str) {
  final idRegex = RegExp(r'/song/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
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
                    song: song,
                    songInformations: fetchSongInformations(song.id))));
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

Future<SongInformations> fetchSongInformations(String songId) async {
  final url = 'http://www.bide-et-musique.com/song/' + songId + '.html';
  var songInformations = SongInformations();
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var divs = document.getElementsByClassName('paroles');
    var lyricsHTML = divs.isEmpty ? 'Paroles indisponible' : divs[0].innerHtml;
    songInformations.lyrics = stripTags(lyricsHTML);

    var informations = document.getElementsByClassName('informations')[0];
    var ps = informations.getElementsByTagName('p');
    songInformations.year = ps[1].children[1].children[0].innerHtml;
    //songInformations.length = ps[3].innerHtml;
    songInformations.label = ps[4].children[1].children[0].innerHtml;
    songInformations.reference = ps[5].children[1].innerHtml;

    return songInformations;
  } else {
    throw Exception('Failed to load song page');
  }
}

class SongPageWidget extends StatelessWidget {
  Song song;
  Future<SongInformations> songInformations;
  final _fontLyrics = TextStyle(fontSize: 20.0);

  SongPageWidget({Key key, this.song, this.songInformations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: Center(
        child: FutureBuilder<SongInformations>(
          future: songInformations,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
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

  void _openCoverViewerDialog(BuildContext context) {
    var urlCover =
        'http://www.bide-et-musique.com/images/pochettes/' + song.id + '.jpg';
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new Image.network(urlCover);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(BuildContext context, SongInformations songInformations) {
    var urlCover =
        'http://www.bide-et-musique.com/images/pochettes/' + song.id + '.jpg';
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
                      child: InkWell(
                          onTap: () {
                            _openCoverViewerDialog(context);
                          },
                          child: new Image.network(urlCover))),
                  Expanded(
                    child: Text(
                        'Année : ' +
                            songInformations.year +
                            '\n' +
                            'Label : ' +
                            songInformations.label +
                            '\n'
                            'Reference : ' +
                            songInformations.reference,
                        style: _fontLyrics),
                  ),
                  //SongPlayerWidget(song.id),
                ],
              )),
          Expanded(
            flex: 7,
            child: Container(
              child: Stack(children: [
                new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: new Container(
                    decoration: new BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                ),
                SingleChildScrollView(
                    child: Text(songInformations.lyrics, style: _fontLyrics)),
              ]),
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                fit: BoxFit.fill,
                alignment: FractionalOffset.topCenter,
                image: new NetworkImage(urlCover),
              )),
            ),
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
