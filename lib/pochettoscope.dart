import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';

Future<List<Song>> fetchPochettoscope() async {
  var songs = <Song>[];
  final url = 'http://www.bide-et-musique.com/le-pochettoscope.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    for (dom.Element vignette in document.getElementsByClassName('vignette75')) {
      var src = vignette.children[1].attributes['src'];
      final idRegex = RegExp(r'/images/thumb75/(\d+).jpg');
      var match = idRegex.firstMatch(src);
      var song = Song();
      song.id = match[1];
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load trombines');
  }
}

class PochettoscopeWidget extends StatelessWidget {
  final Future<List<Song>> songs;
  final _font = TextStyle(
      fontSize: 18.0,
      background: Paint()..color = Color.fromARGB(180, 150, 150, 100));

  PochettoscopeWidget({Key key, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le pochettoscope'),
      ),
      body: Center(
        child: FutureBuilder<List<Song>>(
          future: songs,
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

  Widget _buildView(List<Song> songs) {
    var rows = <Container>[];
    for (Song song in songs) {
      rows.add(
        Container(
          //child: Text(song.title, style: _font),
          decoration: new BoxDecoration(
              color: Colors.orangeAccent,
              image: new DecorationImage(
                fit: BoxFit.contain,
                alignment: FractionalOffset.topCenter,
                image: new NetworkImage(
                    'http://www.bide-et-musique.com/images/thumb75/' +
                        song.id +
                        '.jpg'),
              )),
        ),
      );
    }

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
