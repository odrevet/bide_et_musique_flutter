import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';

Song songFromTr(dom.Element tr){
  //td 0 program
  //td 1 cover
  //td 2 artist
  //td 3 song
  var song = Song();
  var href = tr.children[3].innerHtml;
  song.id = extractSongId(href);
  song.artist = stripTags(tr.children[2].children[0].innerHtml);
  song.title = stripTags(tr.children[3].innerHtml.replaceAll("\n", ""));
  return song;
}

Future<Map<String, List<Song>>> fetchTitles() async {
  final url = '$baseUri/programmes.php';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    List<dom.Node> tables = document.getElementsByClassName('bmtable');

    // table 0 'Demandez le programme'
    // table 1 'Morceau du moment'
    // table 2 'Les titres à venir'
    // table 3 'Ce qui est passé tout à l'heure'
    var songsNext = <Song>[];
    for (dom.Element tr in tables[2].children[0].children) {
      var song = songFromTr(tr);
      songsNext.add(song);
    }

    var songsPrev = <Song>[];
    var trs = tables[3].children[0].children;
    trs.removeLast();
    for (dom.Element tr in trs) {
      var song = songFromTr(tr);
      songsPrev.add(song);
    }

    return {'next': songsNext, 'prev': songsPrev};
  } else {
    throw Exception('Failed to load program');
  }
}

class ProgrammeWidget extends StatelessWidget {
  final Future<Map<String, List<Song>>> program;

  ProgrammeWidget({Key key, this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demandez le programme'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, List<Song>>>(
          future: program,
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

  Widget _buildView(BuildContext context, Map<String, List<Song>> program) {
    return PageView(
      children: <Widget>[
        SongListingWidget(program['next']),
        SongListingWidget(program['prev']),
      ],
    );
  }
}
