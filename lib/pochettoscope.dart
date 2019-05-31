import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'song.dart';
import 'utils.dart';

Future<List<SongLink>> fetchPochettoscope() async {
  var songs = <SongLink>[];
  final url = '$baseUri/le-pochettoscope.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    for (dom.Element vignette
        in document.getElementsByClassName('vignette75')) {
      var src = vignette.children[1].attributes['src'];
      final idRegex = RegExp(r'/images/thumb75/(\d+).jpg');
      var match = idRegex.firstMatch(src);
      var song = SongLink();
      song.id = match[1];

      var title = vignette.children[0].children[0].attributes['title'];
      song.title = title;
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load pochette');
  }
}

class PochettoscopeWidget extends StatefulWidget {
  PochettoscopeWidget({Key key}) : super(key: key);

  @override
  _PochettoscopeWidgetState createState() => _PochettoscopeWidgetState();
}

class _PochettoscopeWidgetState extends State<PochettoscopeWidget> {
  Future<List<SongLink>> _songLinks;

  @override
  void initState() {
    super.initState();
    _songLinks = fetchPochettoscope();
  }

  @override
  Widget build(BuildContext context) {
    var refreshButton = IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () {
          this.setState(() {
            _songLinks = fetchPochettoscope();
          });
        });

    return Scaffold(
      appBar: AppBar(
        title: Text('Le pochettoscope'),
        actions: <Widget>[refreshButton],
      ),
      body: Center(
        child: FutureBuilder<List<SongLink>>(
          future: this._songLinks,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return errorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<SongLink> songs) {
    var rows = <Container>[];
    for (SongLink song in songs) {
      rows.add(Container(child: SongCardWidget(song: song)));
    }

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
