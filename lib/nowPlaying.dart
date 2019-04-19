import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';

Future<Song> fetchNowPlaying() async {
  var song = Song();
  final url = '$host/now-top.php';
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Node titreSong = document.getElementsByClassName('titre-song')[0];
    String href = titreSong.children[0].attributes['href'];
    final idRegex = RegExp(r'/song/(\d+).html');
    var match = idRegex.firstMatch(href);
    song.id = match[1];
    song.title = stripTags(titreSong.children[0].innerHtml);
    return song;
  } else {
    throw Exception('Failed to load top');
  }
}

class NowPlayingWidget extends StatefulWidget {
  NowPlayingWidget({Key key}) : super(key: key);

  @override
  _NowPlayingWidgetState createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget> {
  Future<Song> _song;
  Timer timer;

  _NowPlayingWidgetState();

  @override
  void initState() {
    super.initState();
    _song = fetchNowPlaying();
    timer = new Timer.periodic(new Duration(seconds: 45), (Timer timer) async {
      this.setState(() {
        _song = fetchNowPlaying();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Song>(
          future: _song,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SongCardWidget(song: snapshot.data);
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
}
