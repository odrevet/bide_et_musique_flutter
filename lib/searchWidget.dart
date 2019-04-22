import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import 'song.dart';
import 'utils.dart';

Future<List<Song>> fetchSearch(String search, String type) async {
  final url = '$host/recherche.html?kw=$search&st=$type';
  final response = await http.post(url);
  var songs = <Song>[];

  if (response.statusCode == 302) {
    var location = response.headers['location'];
    print(location);
    //when the result is a single song, the host redirect to the song page
    //in our case parse the page and return a list with one song
    var song = Song();
    song.id = extractSongId(location);
    song.title = 'redirection';

    final url = 'http://www.bide-et-musique.com/song/' + song.id;

    final responseJson = await http.get(url);

    if (responseJson.statusCode == 200) {
      song.title = json.decode(utf8.decode(responseJson.bodyBytes))['name'];
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to song info');
    }

    songs.add(song);
  } else if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var resultat = document.getElementById('resultat');
    var trs = resultat.getElementsByTagName('tr');
    //trs.removeAt(0); //remove header (result count)
    //if(trs[0].className == 'entete'){trs.removeAt(0);}
    for (dom.Element tr in trs) {
      if (tr.className == 'p1' || tr.className == 'p0') {
        var tds = tr.getElementsByTagName('td');
        var a = tds[3].children[0];
        var song = Song();
        song.id = extractSongId(a.attributes['href']);
        song.title = stripTags(a.innerHtml);
        songs.add(song);
      }
    }
  } else {
    throw Exception('Failed to load search');
  }

  return songs;
}

class SearchWidget extends StatefulWidget {
  SearchWidget({Key key}) : super(key: key);

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Future<List<Song>> _search;
  final TextEditingController _controller = new TextEditingController();
  List _searchTypes = [
    'Interprète / Nom du morceau',
    'Interprète',
    'Nom du morceau',
    'Auteur / Compositeur',
    'Label',
    'Paroles',
    'Année',
    'Dans les crédits de la pochette',
    'Dans une émission'
  ];
  List<DropdownMenuItem<String>> _dropDownMenuItems;

  String _currentItem;
  _SearchWidgetState();

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = new List();
    var i = 1;
    for (String searchType in _searchTypes) {
      items.add(new DropdownMenuItem(
          value: i.toString(), child: new Text(searchType)));
      i++;
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _dropDownMenuItems = getDropDownMenuItems();
    this._currentItem = _dropDownMenuItems[0].value;
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

            return Container(
                padding: new EdgeInsets.all(30.0),
                margin: new EdgeInsets.only(top: 20.0),
                child: ListView(children: [
                  DropdownButton(
                    value: this._currentItem,
                    items: _dropDownMenuItems,
                    onChanged: changedDropDownItem,
                  ),
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Entrez ici votre recherche',
                        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0)),
                      ),
                      onSubmitted: (value) {
                        _search = fetchSearch(value, this._currentItem);
                      },
                      controller: _controller)
                ],)
                 );
          },
        ),
      ),
    );
  }

  void changedDropDownItem(String searchType) {
    setState(() {
      _currentItem = searchType;
    });
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
                      song: song,
                      songInformations: fetchSongInformations(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}
