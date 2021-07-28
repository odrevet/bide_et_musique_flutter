import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/song.dart';
import '../session.dart';
import '../utils.dart';
import 'favorite.dart';

Future<Account> fetchAccount(int? accountId) async {
  Account account = Account();
  account.id = accountId;

  final url = '$baseUri/account.html?N=$accountId&Page=all';
  //own account page looks differant of other account pages
  //so we never fetch this special own account page, we fetch it
  //without identification and parse it like any other page
  final bool ownAccount = accountId == Session.accountLink.id;
  final response =
      ownAccount ? await http.get(Uri.parse(url)) : await Session.get(url);

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var txtpresentation =
        document.getElementsByClassName('txtpresentation')[0].innerHtml.trim();
    account.presentation = txtpresentation;
    account.name =
        document.getElementsByClassName('titre-utilisateur')[0].innerHtml;

    dom.Element divInfo = document.getElementById('gd-encartblc2')!;
    List<dom.Element> ps = divInfo.getElementsByTagName('p');
    account.type = stripTags(ps[1].innerHtml);
    account.inscription = stripTags(ps[2].innerHtml);
    account.messageForum = stripTags(ps[3].innerHtml);
    account.comments = stripTags(ps[4].innerHtml);

    //set avatar path
    var img = divInfo.getElementsByTagName('img');
    if (img.isEmpty)
      account.image = '';
    else
      account.image = img[0].attributes['src'];

    //bm tables list favourite songs or messages, either are optional
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    bool hasMessage =
        document.getElementsByClassName('titre-message').isNotEmpty;
    bool hasFavorite = (tables.length == 1 && !hasMessage) ||
        (tables.length == 2 && hasMessage);

    //parse favorites
    if (hasFavorite)
      account.favorites = parseFavoriteTable(tables[0]);
    else
      account.favorites = [];

    //parse message
    List<Message> messages = [];
    if (hasMessage) {
      int index = hasFavorite ? 1 : 0;
      dom.Element table = tables[index];
      for (dom.Element tr in table.getElementsByTagName('tr')) {
        var message = Message();
        dom.Element td = tr.children[0];
        List<String> header =
            td.getElementsByClassName('txtred')[0].text.split('\n');
        message.body = td.getElementsByTagName('p')[0].text;
        message.recipient = header[1].trim();
        message.date = header[2].trim();
        messages.add(message);
      }
    }
    account.messages = messages;

    return account;
  } else {
    throw Exception('Failed to load account ');
  }
}

Future<List<SongLink>> fetchVotes() async {
  var songLinks = <SongLink>[];
  final url = '$baseUri/mes-votes.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var tables = document.getElementsByClassName('bmtable');

    if (tables.isEmpty) {
      return songLinks;
    }

    var table = tables[0];
    var trs = table.children[0].children;
    trs.removeAt(0); //remove header
    for (var tr in trs) {
      var song = SongLink(
          id: getIdFromUrl(tr.children[3].children[0].attributes['href']!)!,
          name: stripTags(tr.children[3].innerHtml),
          artist: stripTags(tr.children[2].innerHtml));
      songLinks.add(song);
    }
  } else {
    throw Exception('Failed to load votes');
  }

  return songLinks;
}

Future<Account> fetchAccountSession() async {
  var account = Account();
  account.id = Session.accountLink.id;
  final url = '$baseUri/account.html?N=${account.id}&Page=all';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    //parse bm tables
    //bm table may list favourite songs or messages.
    //either are optional
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    bool hasMessage =
        document.getElementsByClassName('titre-message').isNotEmpty;
    bool hasFavorite = (tables.length == 1 && !hasMessage) ||
        (tables.length == 2 && hasMessage);

    //parse favorites
    if (hasFavorite)
      account.favorites = parseFavoriteTable(tables[0]);
    else
      account.favorites = [];

    return account;
  } else {
    throw Exception('Failed to load account $account');
  }
}
