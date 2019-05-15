import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';

Song songFromTr(dom.Element tr) {
  //td 0 program / date
  //td 1 cover
  //td 2 artist
  //td 3 song
  var song = Song();
  var href = tr.children[3].innerHtml;
  song.id = extractSongId(href);
  song.artist = stripTags(tr.children[2].innerHtml);
  song.title = stripTags(tr.children[3].innerHtml.replaceAll("\n", ""));
  return song;
}

Future<Map<String, List<Song>>> fetchTitles() async {
  final url = '$baseUri/programmes.php';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    
    var songsNext = <Song>[];
    var tableNext = document.getElementById('BM_next_songs').children[1];
    var trsNext = tableNext.getElementsByTagName('tr');
    for (dom.Element tr in trsNext) {
      var song = songFromTr(tr);
      songsNext.add(song);
    }

    var songsPast = <Song>[];
    var tablePast = document.getElementById('BM_past_songs').children[1];
    var trsPast = tablePast.getElementsByTagName('tr');
    trsPast.removeLast();   //remove show more button
    for (dom.Element tr in trsPast) {
      var song = songFromTr(tr);
      songsPast.add(song);
    }

    return {'next': songsNext, 'past': songsPast};
  } else {
    throw Exception('Failed to load program');
  }
}

class ProgrammeWidget extends StatelessWidget {
  final Future<Map<String, List<Song>>> program;

  ProgrammeWidget({Key key, this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Map<String, List<Song>>>(
        future: program,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return Scaffold(
            appBar: AppBar(title: Text("Chargement des programmes")),
            body: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Map<String, List<Song>> program) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Demandez le programme"),
          bottom: TabBar(
            tabs: [
              Tab(text: "A venir sur la platine"),
              Tab(text: "De retrour dans leur bac"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SongListingWidget(program['next']),
            SongListingWidget(program['past']),
          ],
        ),
      ),
    );
  }
}
