import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'session.dart';
import 'song.dart';
import 'utils.dart';

class PochettoscopeWidget extends StatefulWidget {
  PochettoscopeWidget({Key key}) : super(key: key);

  @override
  _PochettoscopeWidgetState createState() => _PochettoscopeWidgetState();
}

class _PochettoscopeWidgetState extends State<PochettoscopeWidget> {
  var _songLinks = <SongLink>[];
  var _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    fetchPochettoscope();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      fetchPochettoscope();
    }
  }

  fetchPochettoscope() async {
    final url = '$baseUri/le-pochettoscope.html';
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
        songLink.title = title;

        setState(() {
          _songLinks.add(songLink);
        });
      }
    } else {
      throw Exception('Failed to load pochette');
    }
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
        appBar: AppBar(
          title: Text('Le pochettoscope'),
        ),
        body: GridView.builder(
            itemCount: _songLinks.length,
            controller: _controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 2 : 3),
            itemBuilder: (BuildContext context, int index) {
              var songLink = _songLinks[index];
              return SongCardWidget(songLink: songLink);
            }));
  }
}
