import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../session.dart';
import 'song.dart';
import 'song_airing_notifier.dart';
import '../utils.dart';

import '../models/song.dart';

SongLink songLinkFromTr(dom.Element tr) {
  var tdInfo = tr.children[0]; //program for next, HH:MM for past
  var tdArtist = tr.children[2];
  var tdSong = tr.children[3];
  String title = stripTags(tdSong.innerHtml.replaceAll('\n', ''));
  const String newFlag = '[nouveauté]';
  dom.Element a;
  bool isNew = false;
  if (title.contains(newFlag)) {
    isNew = true;
    title = title.replaceFirst(newFlag, '');
    a = tdSong.children[1];
  } else {
    //sometimes the td song element is somehow empty (e.g. Seamus)
    if (tdSong.children.isNotEmpty) a = tdSong.children[0];
  }

  return SongLink(
      id: a == null ? null : getIdFromUrl(a.attributes['href']),
      artist: stripTags(tdArtist.innerHtml).trim(),
      name: title.trim(),
      info: stripTags(tdInfo.innerHtml).trim(),
      isNew: isNew);
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
      SongLink songLink = songLinkFromTr(tr);
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
      SongLink songLink = songLinkFromTr(tr);
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
  final SongAiringNotifier _songAiring = SongAiringNotifier();

  TitlesWidget({Key key}) : super(key: key);

  @override
  _TitlesWidgetState createState() => _TitlesWidgetState();
}

class _TitlesWidgetState extends State<TitlesWidget> {
  Future<Map<String, List<SongLink>>> _songLinks;
  VoidCallback listener;

  void updateTitles() {
    setState(() {
      _songLinks = fetchTitles();
    });
  }

  @override
  initState() {
    listener = () {
      if (mounted) updateTitles();
    };

    _songLinks = fetchTitles();
    widget._songAiring.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget._songAiring.removeListener(listener);
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
                body: Center(
                    child: ErrorDisplay(Exception(snapshot.error.toString()))));
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
