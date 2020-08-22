import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/account.dart';
import '../session.dart';
import '../utils.dart';

Future<List<AccountLink>> fetchTrombidoscope() async {
  List<AccountLink> accounts = List();

  final url = '$baseUri/trombidoscope.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var table = document.getElementsByClassName('bmtable')[0];
    for (dom.Element td in table.getElementsByTagName('td')) {
      var a = td.children[0];
      var href = a.attributes['href'];
      var id = getIdFromUrl(href);
      var account = AccountLink();
      account.id = id;
      account.name = stripTags(a.innerHtml);
      account.image = a.children[0].attributes['src'];
      accounts.add(account);
    }
  } else {
    throw Exception('Failed to load trombines');
  }

  return accounts;
}
