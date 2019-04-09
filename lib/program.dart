import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';

Future<Map<String, List<Song>>> fetchTitles() async {
  final url = 'http://www.bide-et-musique.com/programmes.php';
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
      //td 0 program
      //td 1 cover
      //td 2 artist
      //td 3 song
      var song = Song();

      var href = tr.children[3].innerHtml;
      final idRegex = RegExp(r'/song/(\d+).html');
      var match = idRegex.firstMatch(href);
      song.id = match[1];

      song.artist = stripTags(tr.children[2].children[0].innerHtml);
      song.title = stripTags(tr.children[3].children[0].innerHtml);

      songsNext.add(song);
    }

    var songsPrev = <Song>[];

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
    var rows = <ListTile>[];
    List<Song> songsNext = program['next'];
    for (Song song in songsNext) {
      rows.add(ListTile(
        leading: new CircleAvatar(
          backgroundColor: Colors.black12,
          child: new Image(
              image: new NetworkImage(
                  'http://bide-et-musique.com/images/thumb25/' +
                      song.id +
                      '.jpg')),
        ),
        title: Text(
          song.title,
        ),
        subtitle: Text(song.artist),
        onTap: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new SongPageWidget(
                      song: song,
                      songInformations: fetchSongInformations(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}
