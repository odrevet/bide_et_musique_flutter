import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'song.dart';
import 'utils.dart';

class NowSong {
  SongLink song;
  String desc; //description formated in HTML
  String date;

  NowSong();
}

Future<List<NowSong>> fetchNowSongs() async {
  var nowSongs = <NowSong>[];
  final url = '$baseUri/morceaux-du-moment.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');
    trs.removeAt(0); //remove heading pagination
    trs.removeLast(); //remove leading pagination
    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      var song = SongLink();
      song.title = tds[3].children[0].innerHtml;
      song.id = extractSongId(tds[3].children[0].attributes['href']);
      var nowSong = NowSong();
      nowSong.date = tds[0].innerHtml.trim();
      nowSong.desc = tds[4].innerHtml;
      nowSong.song = song;
      nowSongs.add(nowSong);
    }
    return nowSongs;
  } else {
    throw Exception('Failed to load now songs');
  }
}

class NowSongsWidget extends StatelessWidget {
  final Future<List<NowSong>> nowSongs;

  NowSongsWidget({Key key, this.nowSongs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chanson du moment'),
      ),
      body: Center(
        child: FutureBuilder<List<NowSong>>(
          future: nowSongs,
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

  Widget _buildView(BuildContext context, List<NowSong> nowSongs) {
    var rows = <ListTile>[];
    for (NowSong nowSong in nowSongs) {
      rows.add(ListTile(
          onTap: () => launchSongPage(nowSong.song, context),
          leading: CircleAvatar(
            child: Image(
                image: NetworkImage(
                    '$baseUri/images/thumb25/${nowSong.song.id}.jpg')),
            backgroundColor: Colors.black12,
          ),
          title: Html(
              data: nowSong.song.title + '<br/>' + nowSong.desc,
              onLinkTap: (url) {
                onLinkTap(url, context);
              }),
          subtitle: Text('Le ${nowSong.date}')));
    }

    return ListView(children: rows);
  }
}
