import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:diacritic/diacritic.dart';

import '../models/account.dart';
import '../models/exchange.dart';
import '../session.dart';
import '../utils.dart';

int getAccountIdFromUrl(str) {
  final idRegex = RegExp(r'/bidebox_send.html\?T=(\d+)');
  var match = idRegex.firstMatch(str);
  if (match != null) {
    return int.parse(match[1]);
  } else {
    return null;
  }
}

Future<List<Exchange>> fetchExchanges() async {
  List<Exchange> messages = [];

  String url = '$baseUri/bidebox_list.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    if (tables.isEmpty) {
      return messages;
    }

    dom.Element table = tables[0];
    var trs = table.children[0].children;
    trs.removeLast();
    trs.removeLast();
    for (var tr in trs) {
      var message = Exchange();
      int id =
          getAccountIdFromUrl(tr.children[0].children[0].attributes['href']);
      message.recipient = AccountLink(id: id, name: tr.children[0].text.trim());
      List<String> secondTdText = tr.children[1].text.split('\n');
      message.sentCount = secondTdText[2].trim();
      message.receivedCount = secondTdText[3].trim();
      messages.add(message);
    }
  } else {
    throw Exception('Failed to load bideboxes');
  }

  return messages;
}

Future<bool> sendMessage(String message, int destId) async {
  final url = '$baseUri/bidebox_send.html';

  if (message.isNotEmpty) {
    var response = await Session.post(url, body: {
      'Message': removeDiacritics(message),
      'T': destId.toString(),
      'R': '',
      'M': 'S'
    });
    return response.statusCode == 200;
  }

  return false;
}