import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'session.dart';
import 'song.dart';
import 'utils.dart';

SongLink songLinkFromTr(dom.Element tr) {
  //td 0 program / date
  //td 1 cover
  //td 2 artist
  //td 3 song
  var songLink = SongLink();
  var href = tr.children[3].innerHtml;
  songLink.id = getIdFromUrl(href);
  songLink.artist = stripTags(tr.children[2].innerHtml).trim();
  var title = stripTags(tr.children[3].innerHtml.replaceAll('\n', ''));
  const String newFlag = '[nouveauté]';
  if (title.contains(newFlag)) {
    songLink.isNew = true;
  }
  songLink.title = title.replaceFirst(newFlag, '').trim();
  return songLink;
}

Future<Map<String, List<SongLink>>> fetchTitles() async {
  final url = '$baseUri/programmes.php';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var songLinksNext = <SongLink>[];
    var tableNext = document.getElementById('BM_next_songs').children[1];
    var trsNext = tableNext.getElementsByTagName('tr');
    int indexNext = 0;
    for (dom.Element tr in trsNext) {
      var songLink = songLinkFromTr(tr);
      songLink.index = indexNext;
      indexNext++;
      songLinksNext.add(songLink);
    }

    var songLinksPast = <SongLink>[];
    var tablePast = document.getElementById('BM_past_songs').children[1];
    var trsPast = tablePast.getElementsByTagName('tr');
    trsPast.removeLast(); //remove the 'show more' button
    int indexPast = 0;
    for (dom.Element tr in trsPast) {
      var songLink = songLinkFromTr(tr);
      songLink.index = indexPast;
      indexPast++;
      songLinksPast.add(songLink);
    }

    return {'next': songLinksNext, 'past': songLinksPast};
  } else {
    throw Exception('Failed to load program');
  }
}

class TitlesWidget extends StatefulWidget {
  TitlesWidget({Key key}) : super(key: key);

  @override
  _TitlesWidgetState createState() => _TitlesWidgetState();
}

class _TitlesWidgetState extends State<TitlesWidget> {
  Timer _timer;
  Future<Map<String, List<SongLink>>> _songLinks;

  @override
  void initState() {
    _songLinks = fetchTitles();
    _timer = Timer.periodic(Duration(seconds: 45), (Timer timer) async {
      setState(() {
        _songLinks = fetchTitles();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Map<String, List<SongLink>>>(
        future: _songLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(snapshot.data);
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text('Ouille ouille ouille !')),
              body: Center(child: Center(child: errorDisplay(snapshot.error))),
            );
          }

          // By default, show a loading spinner
          return Scaffold(
            appBar: AppBar(title: Text('Chargement des titres')),
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildView(Map<String, List<SongLink>> songLinks) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Les titres'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'A venir sur la platine'),
              Tab(text: 'De retour dans leur bac'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SongListingWidget(songLinks['next']),
            SongListingWidget(songLinks['past']),
          ],
        ),
      ),
    );
  }
}
