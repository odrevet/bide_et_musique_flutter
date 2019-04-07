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

      var title = vignette.children[0].children[0].attributes['title'];
      song.title = title;
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load pochette');
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

  Widget _buildView(BuildContext context, List<Song> songs) {
    var rows = <GestureDetector>[];
    for (Song song in songs) {
      rows.add(
          GestureDetector(
            onTap: () { print("Container was tapped"); },
            child: SongCardWidget(song: song)
          )
      );
    }

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
