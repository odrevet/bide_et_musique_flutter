import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'song.dart';
import 'utils.dart';
import 'account.dart';

Future<List<Account>> fetchSearchAccount(String search) async {
  String url = '$baseUri/recherche-bidonaute.html?bw=$search';

  //need to transform characters to url encoding
  // cannot use Uri.encodeFull because it will encode from UTF-8 and the
  //target expect CP-1252 (e.g will convert 'é' to '%C3%A9' instead of '%E9')
  //see https://www.w3schools.com/tags/ref_urlencode.asp
  //TODO convert from  CP-1252
  url = url.replaceAll(RegExp(r'é'), '%E9');
  url = url.replaceAll(RegExp(r'è'), '%E8');

  final response = await http.post(url);
  var accounts = <Account>[];

  if (response.statusCode == 302) {
    var location = response.headers['location'];
    print(location);
    //when the result is a single song, the host redirect to the song page
    //in our case parse the page and return a list with one song
    var account = Account(extractAccountId(location), search);
    accounts.add(account);
  } else if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var resultat = document.getElementsByClassName('bmtable')[0];
    var trs = resultat.getElementsByTagName('tr');

    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      var a = tds[0].children[0];
      var account = Account(
          extractAccountId(a.attributes['href']), stripTags(a.innerHtml));
      accounts.add(account);
    }
  } else {
    throw Exception('Failed to load search');
  }

  return accounts;
}

Future<List<Song>> fetchSearchSong(String search, String type) async {
  String url = '$baseUri/recherche.html?kw=$search&st=$type';

  //need to transform characters to url encoding
  // cannot use Uri.encodeFull because it will encode from UTF-8 and the
  //target expect CP-1252 (e.g will convert 'é' to '%C3%A9' instead of '%E9')
  //see https://www.w3schools.com/tags/ref_urlencode.asp
  //TODO convert from  CP-1252
  url = url.replaceAll(RegExp(r'é'), '%E9');
  url = url.replaceAll(RegExp(r'è'), '%E8');

  final response = await http.post(url);
  var songs = <Song>[];

  if (response.statusCode == 302) {
    var location = response.headers['location'];
    print(location);
    //when the result is a single song, the host redirect to the song page
    //in our case parse the page and return a list with one song
    var song = Song();
    song.id = extractSongId(location);
    song.title = search;
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
        song.artist = stripTags(tds[2].children[0].innerHtml);
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
  final TextEditingController _controller = TextEditingController();
  List _searchTypes = [
    'Interprète / Nom du morceau',
    'Interprète',
    'Nom du morceau',
    'Auteur / Compositeur',
    'Label',
    'Paroles',
    'Année',
    'Dans les crédits de la pochette',
    'Dans une émission',
    'Bidonaute'
  ];
  List<DropdownMenuItem<String>> _dropDownMenuItems;

  String _currentItem; //selected index from 1

  _SearchWidgetState();

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = List();
    var i = 1;
    for (String searchType in _searchTypes) {
      items.add(DropdownMenuItem(value: i.toString(), child: Text(searchType)));
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
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Rechercher dans la base'),
        ),
        body: Container(
            padding: EdgeInsets.all(30.0),
            margin: EdgeInsets.only(top: 20.0),
            child: ListView(
              children: [
                DropdownButton(
                  value: this._currentItem,
                  items: _dropDownMenuItems,
                  onChanged: changedDropDownItem,
                ),
                TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Entrez ici votre recherche',
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onSubmitted: (value) {
                      if (this._currentItem == '10') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AccountListingFutureWidget(
                                        fetchSearchAccount(value))));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>

                                Scaffold(
                            appBar: AppBar(
                            title: Text('Recherche de chansons'),
                        ),
                      body: Center(
                      child: SongListingFutureWidget(
                          fetchSearchSong(
                              value, this._currentItem)),
                      ),
                      )

                                    ));
                      }
                    },
                    controller: _controller)
              ],
            )));
  }

  void changedDropDownItem(String searchType) {
    setState(() {
      _currentItem = searchType;
    });
  }
}
