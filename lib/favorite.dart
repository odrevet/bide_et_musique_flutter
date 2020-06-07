import 'dart:async';

import 'package:bide_et_musique/pochettoscopeWidget.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'session.dart';
import 'song.dart';
import 'utils.dart';

class FavoritesResults {
  List<SongLink> songLinks;
  int pageCount;
  int page;

  FavoritesResults({this.songLinks, this.pageCount, this.page});
}

Future<FavoritesResults> fetchFavorites(int accountId, int page) async {
  final url = '$baseUri/account.html?N=$accountId&Page=$page';
  final response = await Session.get(url);

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    //parse bm tables
    //bm table may list favourite songs or messages.
    //either are optional
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    bool hasMessage = Session.accountLink != null &&
        document.getElementsByClassName('titre-message').isNotEmpty;
    bool hasFavorite = (tables.length == 1 && !hasMessage) ||
        (tables.length == 2 && hasMessage);

    //parse favorites
    List<SongLink> favorites = <SongLink>[];
    int pageCount = 0;
    if (hasFavorite) {
      List<dom.Element> navbars = tables[0].getElementsByClassName('navbar');
      if (navbars.isEmpty)
        pageCount = 0;
      else {
        pageCount = navbars[0].getElementsByTagName('td').length - 1;
      }

      List<dom.Element> trs = tables[0].children[0].children;
      print(trs.length);
      if (pageCount > 0) {
        trs.removeAt(0);
        trs.removeLast();
      }

      for (dom.Element tr in trs) {
        SongLink songLink = SongLink();
        dom.Element aTitle = tr.children[4].children[0];

        if (aTitle.toString() == '<html div>')
          aTitle = tr.children[4].children[1];

        songLink.id = getIdFromUrl(aTitle.attributes['href']);
        songLink.name = stripTags(aTitle.innerHtml);
        songLink.artist = stripTags(tr.children[3].innerHtml);
        favorites.add(songLink);
      }
    }

    return FavoritesResults(
        songLinks: favorites, page: page, pageCount: pageCount);
  } else {
    throw Exception('Failed to load account with id $accountId');
  }
}

class FavoriteWidget extends StatefulWidget {
  final int accountId;
  final bool viewPochettoscope;

  FavoriteWidget({this.accountId, this.viewPochettoscope = false, Key key})
      : super(key: key);

  @override
  _FavoriteWidgetState createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  Future<List<SongLink>> _songLinks;
  bool _isLoading;
  int _page;
  int _pageCount;

  @override
  void initState() {
    super.initState();
    _page = 1;
    _isLoading = true;
    /*fetchFavorites(widget.accountId, 0).then((favoritesResults) => {
          setState(() {
            _isLoading = false;
            _songLinks = favoritesResults.songLinks;
            _pageCount = favoritesResults.pageCount;
          })
        });*/
  }

/*  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _page < _pageCount &&
        _isLoading == false) {
      setState(() {
        _page++;
        _isLoading = true;
      });
      fetchFavorites(widget.accountId, _page).then((favoritesResults) => {
            setState(() {
              _isLoading = false;
              _songLinks = [..._songLinks, ...favoritesResults.songLinks];
            })
          });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<SongLink>>(
        future: _songLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return PochettoscopeWidget(songLinks: snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        },
      ),
    );

    //return PochettoscopeWidget(songLinks: _songLinks);
  }
}
