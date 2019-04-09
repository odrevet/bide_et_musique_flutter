import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';

Future<List<Song>> fetchSearch(String search) async {
  final url = 'http://www.bide-et-musique.com/recherche.html?kw='+search+'&st=1';
  final response = await http.get(url);
  var songs = <Song>[];

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var resultat = document.getElementById('resultat');
    var trs = resultat.getElementsByTagName('tr');
    //trs.removeAt(0); //remove header (result count)
    //if(trs[0].className == 'entete'){trs.removeAt(0);}
    for(dom.Element tr in trs){
      if(tr.className == 'p1' || tr.className == 'p0'){
        var tds = tr.getElementsByTagName('td');
        var a = tds[3].children[0];
        var song = Song();
        song.id = extractSongId(a.attributes['href']);;
        song.title = a.innerHtml;
        songs.add(song);
      }
    }
    return songs;
  } else {
    throw Exception('Failed to load search');
  }
}

class SearchWidget extends StatefulWidget {
  SearchWidget({Key key}) : super(key: key);

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Future<List<Song>> _search;
  final TextEditingController _controller = new TextEditingController();

  _SearchWidgetState();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rechercher dans la base'),
      ),
      body: Center(
        child: FutureBuilder<List<Song>>(
          future: _search,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            return TextField(
                onSubmitted: (value) {_search = fetchSearch(value);},
                controller: _controller);
          },
        ),
      ),
    );
  }

  Widget _buildView(List<Song> songs) {
    var rows = <ListTile>[];
    for (Song song in songs) {
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
        //subtitle: Text(song.artist),
        onTap: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new SongPageWidget(
                      song: song, lyrics: fetchLyrics(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}
