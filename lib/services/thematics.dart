import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/program.dart';
import '../session.dart';
import '../utils.dart';

Future<List<ProgramLink>> fetchThematics() async {
  var programLinks = <ProgramLink>[];
  final url = '$baseUri/programmes-thematiques.html';

  final response = await Session.get(url);

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');
    trs.removeAt(0);

    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      var a = tds[0].children[0];
      int? id = getIdFromUrl(a.attributes['href']!);
      String name = stripTags(a.innerHtml);
      String songCount = tds[1].innerHtml;

      var programLink = ProgramLink(id: id, name: name, songCount: songCount);
      programLinks.add(programLink);
    }
  } else {
    throw Exception('Failed to load thematics');
  }

  programLinks
      .sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
  return programLinks;
}
