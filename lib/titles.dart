import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'song.dart';
import 'utils.dart';
import 'session.dart';

SongLink songLinkFromTr(dom.Element tr) {
  //td 0 program / date
  //td 1 cover
  //td 2 artist
  //td 3 song
  var songLink = SongLink();
  var href = tr.children[3].innerHtml;
  songLink.id = extractSongId(href);
  songLink.artist = stripTags(tr.children[2].innerHtml);
  var title = stripTags(tr.children[3].innerHtml.replaceAll('\n', ''));
  const String newFlag = '[nouveauté]';
  if (title.contains(newFlag)) {
    songLink.isNew = true;
  }
  songLink.title = title.replaceFirst(newFlag, '').trimLeft();
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

class TitlesWidget extends StatelessWidget {
  final Future<Map<String, List<SongLink>>> program;

  TitlesWidget({Key key, this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Map<String, List<SongLink>>>(
        future: program,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
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

  Widget _buildView(
      BuildContext context, Map<String, List<SongLink>> songLinks) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Les titres'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'A venir sur la platine'),
              Tab(text: 'De retrour dans leur bac'),
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
