import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'account.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

Future<List<AccountLink>> fetchSearchAccount(String search) async {
  String url = '$baseUri/recherche-bidonaute.html?bw=$search';

  //Server uses latin-1
  url = removeDiacritics(url);

  final response = await Session.post(url);
  var accounts = <AccountLink>[];

  if (response.statusCode == 302) {
    var location = response.headers['location'];
    //when the result is a single song, the host redirect to the song page
    //in our case parse the page and return a list with one song
    var account = AccountLink(id: getIdFromUrl(location), name: search);
    accounts.add(account);
  } else if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');

    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      var a = tds[0].children[0];
      var account = AccountLink(
          id: getIdFromUrl(a.attributes['href']),
          name: stripTags(a.innerHtml));
      accounts.add(account);
    }
  } else {
    throw Exception('Failed to load search');
  }

  return accounts;
}

class SearchResultsWidget extends StatefulWidget {
  final String search;
  final String type;

  SearchResultsWidget(this.search, this.type, {Key key}) : super(key: key);

  @override
  _SearchResultsWidgetState createState() =>
      _SearchResultsWidgetState(this.search, this.type);
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  int _pages;
  int _pageCurrent;
  var _songLinks = <SongLink>[];
  final String search;
  final String type;

  var _controller = ScrollController();

  _SearchResultsWidgetState(this.search, this.type);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    _pageCurrent = 1;
    fetchSearchSong();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _pageCurrent < _pages) {
      setState(() {
        _pageCurrent++;
      });
      fetchSearchSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        controller: _controller,
        itemCount: _songLinks.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.black12,
                child: Image(image: NetworkImage(_songLinks[index].thumbLink)),
              ),
              title: Text(
                _songLinks[index].title,
              ),
              subtitle: Text(_songLinks[index].artist == null
                  ? ''
                  : _songLinks[index].artist),
              onTap: () => launchSongPage(_songLinks[index], context));
        });
  }

  fetchSearchSong() async {
    String url =
        '$baseUri/recherche.html?kw=$search&st=$type&Page=$_pageCurrent';

    //server uses latin-1
    url = removeDiacritics(url);

    final response = await Session.post(url);
    if (response.statusCode == 302) {
      var location = response.headers['location'];
      //when the result is a single song, the host redirect to the song page
      //in our case parse the page and return a list with one song
      var songLink = SongLink();
      songLink.id = getIdFromUrl(location);
      songLink.title = search;
      setState(() {
        _pages = 1;
        _songLinks.add(songLink);
      });
    } else if (response.statusCode == 200) {
      var body = response.body;
      dom.Document document = parser.parse(body);
      var result = document.getElementById('resultat');
      var trs = result.getElementsByTagName('tr');

      //if page is null this mean this is the first time the result page has
      //been fetched, check how many pages this search has
      if (_pages == null) {
        var navbar = document.getElementsByClassName('navbar');
        if (navbar.isEmpty) {
          setState(() {
            _pages = 1;
          });
        } else {
          setState(() {
            _pages = navbar[0].getElementsByTagName('td').length - 1;
          });
        }
      }

      for (dom.Element tr in trs) {
        if (tr.className == 'p1' || tr.className == 'p0') {
          var tds = tr.getElementsByTagName('td');
          var a = tds[3].children[0];

          var songLink = SongLink();
          songLink.id = getIdFromUrl(a.attributes['href']);
          songLink.title = stripTags(a.innerHtml);
          songLink.artist = stripTags(tds[2].children[0].innerHtml);

          setState(() {
            _songLinks.add(songLink);
          });
        }
      }
    } else {
      throw Exception('Failed to load search');
    }
  }
}

/////////////////////////////////////////////////////////////////////

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

  void performSearch() {
    if (this._currentItem == '10') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AccountListingFutureWidget(
                  fetchSearchAccount(_controller.text))));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('Recherche de chansons'),
                    ),
                    body: Center(
                        child: SearchResultsWidget(
                            _controller.text, this._currentItem)),
                  )));
    }
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
              shrinkWrap: true,
              padding: EdgeInsets.all(16.0),
              children: [
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).accentColor, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(24.0)),
                    ),
                    margin: const EdgeInsets.all(15.0),
                    padding: const EdgeInsets.all(3.0),
                    child: DropdownButtonFormField(
                      decoration: InputDecoration.collapsed(hintText: ''),
                      value: this._currentItem,
                      items: _dropDownMenuItems,
                      onChanged: changedDropDownItem,
                    )),
                TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Entrez ici votre recherche',
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onSubmitted: (value) => performSearch(),
                    controller: _controller),
                Container(
                  child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0)),
                      child: Text(
                        'Lancer la recherche',
                      ),
                      onPressed: () => performSearch(),
                      color: Colors.orangeAccent),
                  margin: EdgeInsets.only(top: 20.0),
                )
              ],
            )));
  }

  void changedDropDownItem(String searchType) {
    setState(() {
      _currentItem = searchType;
    });
  }
}
