import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'session.dart';
import 'song.dart';
import 'utils.dart';
import 'pochettoscopeWidget.dart';

Future<List<SongLink>> fetchPochettoscope() async {
  final url = '$baseUri/le-pochettoscope.html';
  List<SongLink> songLinks = [];
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    for (dom.Element vignette
        in document.getElementsByClassName('vignette75')) {
      var src = vignette.children[1].attributes['src'];
      final idRegex = RegExp(r'/images/thumb75/(\d+).jpg');
      var match = idRegex.firstMatch(src);
      var songLink = SongLink();
      songLink.id = int.parse(match[1]);

      var title = vignette.children[0].children[0].attributes['title'];
      songLink.name = title;
      songLinks.add(songLink);
    }
  } else {
    throw Exception('Failed to load pochette');
  }
  return songLinks;
}

class PochettoScopePage extends StatelessWidget {
  final Widget child;

  PochettoScopePage({this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Le pochettoscope'),
        ),
        body: PochettoscopeWidget(
            onEndReached: fetchPochettoscope));
  }
}


