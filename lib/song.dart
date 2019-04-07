import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
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
      child: SingleChildScrollView(
          child: Text(lyrics,
              style: new TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w600))),
    );
  }
}
