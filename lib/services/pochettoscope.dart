import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/song.dart';
import '../session.dart';
import '../utils.dart';

Future<List<SongLink>> fetchPochettoscope() async {
  const url = '$baseUri/le-pochettoscope.html';
  List<SongLink> songLinks = [];
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    for (dom.Element vignette
        in document.getElementsByClassName('vignette75')) {
      var src = vignette.children[1].attributes['src']!;
      final idRegex = RegExp(r'/images/thumb75/(\d+).jpg');
      var match = idRegex.firstMatch(src)!;
      var title = vignette.children[0].children[0].attributes['title']!;
      var songLink = SongLink(id: int.parse(match[1]!), name: title);
      songLinks.add(songLink);
    }
  } else {
    throw Exception('Failed to load pochette');
  }
  return songLinks;
}
