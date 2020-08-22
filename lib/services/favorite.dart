import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/favorites.dart';
import '../models/song.dart';
import '../session.dart';
import '../utils.dart';

List<SongLink> parseFavoriteTable(dom.Element table) {
  List<SongLink> favorites = [];
  int pageCount;
  List<dom.Element> navbars = table.getElementsByClassName('navbar');

  if (navbars.isEmpty)
    pageCount = 0;
  else {
    pageCount = navbars[0].getElementsByTagName('td').length - 1;
  }

  List<dom.Element> trs = table.children[0].children;
  print(trs.length);
  if (pageCount > 0) {
    trs.removeAt(0);
    trs.removeLast();
  }

  for (dom.Element tr in trs) {
    SongLink songLink = SongLink();
    dom.Element aTitle = tr.children[4].children[0];

    if (aTitle.toString() == '<html div>') aTitle = tr.children[4].children[1];

    songLink.id = getIdFromUrl(aTitle.attributes['href']);
    songLink.name = stripTags(aTitle.innerHtml);
    songLink.artist = stripTags(tr.children[3].innerHtml);
    favorites.add(songLink);
  }

  return favorites;
}

Future<FavoritesResults> fetchFavorites(int accountId, int page) async {
  final String pageUrlParam = page > 0 ? page.toString() : 'all';
  final url = '$baseUri/account.html?N=$accountId&Page=$pageUrlParam';
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

Future<int> addSongToFavorites(String songUrl) async {
  Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
  Session.headers['Host'] = host;
  Session.headers['Origin'] = baseUri;
  Session.headers['Referer'] = songUrl;

  final response = await Session.post(songUrl, body: {'M': 'AS'});

  Session.headers.remove('Referer');
  Session.headers.remove('Content-Type');

  return response.statusCode;
}

Future<int> removeSongFromFavorites(int songId) async {
  final response = await Session.post(
      '$baseUri/account/${Session.accountLink.id}.html',
      body: {'K': songId.toString(), 'Step': '', 'DS.x': '1', 'DS.y': '1'});

  return response.statusCode;
}
