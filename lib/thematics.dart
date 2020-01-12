import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'program.dart';
import 'session.dart';
import 'utils.dart';

class ProgramLink {
  String id;
  String name;
  String songCount;

  ProgramLink({this.id, this.name, this.songCount});
}

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
      String id = extractProgramId(a.attributes['href']);
      String name = stripTags(a.innerHtml);
      String songCount = tds[1].innerHtml;

      var programLink = ProgramLink(id: id, name: name, songCount: songCount);
      programLinks.add(programLink);
    }
  } else {
    throw Exception('Failed to load thematics');
  }

  return programLinks;
}

class ThematicPageWidget extends StatelessWidget {
  final Future<List<ProgramLink>> programLinks;

  ThematicPageWidget({Key key, this.programLinks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<ProgramLink>>(
        future: programLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          var loadingMessage = 'Chargement';

          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<ProgramLink> programLinks) {
    Widget listView = ListView.builder(
      itemCount: programLinks.length,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(programLinks[index].name),
            subtitle: Text(programLinks[index].songCount),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProgramPageWidget(
                          program: fetchProgram(programLinks[index].id))));
            });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Programmations thématiques'),
      ),
      body: listView,
    );
  }
}
