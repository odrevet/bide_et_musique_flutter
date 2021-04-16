import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/search.dart';
import '../models/song.dart';
import '../session.dart';
import '../utils.dart';

Future<List<AccountLink>> fetchSearchAccount(String search) async {
  String url = '$baseUri/recherche-bidonaute.html?bw=$search';

  //Server uses latin-1
  url = removeDiacritics(url);

  final response = await Session.post(url);
  var accounts = <AccountLink>[];

  if (response.statusCode == 302) {
    var location = response.headers['location']!;
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
          id: getIdFromUrl(a.attributes['href']!), name: stripTags(a.innerHtml));
      accounts.add(account);
    }
  } else {
    throw Exception('Failed to load search');
  }

  return accounts;
}

Future<SearchResult> fetchSearchSong(
    String? search, String? type, int? pageCurrent) async {
  SearchResult searchResult = SearchResult();
  String url = '$baseUri/recherche.html?kw=$search&st=$type&Page=$pageCurrent';
  url = removeDiacritics(url); //server uses latin-1
  final response = await http.post(Uri.parse(url));

  if (response.statusCode == 302) {
    var location = response.headers['location']!;
    //when the result is a single song, the host redirect to the song page
    //in our case parse the page and return a list with one song
    searchResult.songLinks
        .add(SongLink(id: getIdFromUrl(location)!, name: search!));
    searchResult.pageCount = 1;
    return searchResult;
  } else if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var result = document.getElementById('resultat')!;
    var trs = result.getElementsByTagName('tr');

    var navbar = document.getElementsByClassName('navbar');
    if (navbar.isEmpty)
      searchResult.pageCount = 1;
    else
      searchResult.pageCount = navbar[0].getElementsByTagName('td').length - 1;

    for (dom.Element tr in trs) {
      if (tr.className == 'p1' || tr.className == 'p0') {
        var tds = tr.getElementsByTagName('td');
        var a = tds[3].children[0];
        searchResult.songLinks.add(SongLink(
            id: getIdFromUrl(a.attributes['href']!)!,
            name: stripTags(a.innerHtml),
            artist: stripTags(tds[2].children[0].innerHtml)));
      }
    }
  } else {
    throw Exception('Erreur lors de la recherche de chanson');
  }
  return searchResult;
}
