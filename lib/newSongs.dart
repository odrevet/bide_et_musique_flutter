import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import 'session.dart';
import 'song.dart';
import 'utils.dart';

Future<List<SongLink>> fetchNewSongs() async {
  var songs = <SongLink>[];
  final url = '$baseUri/new_song.rss';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = XmlDocument.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.children[2].text;
      var song = SongLink();
      song.id = getIdFromUrl(link);
      var artistTitle = stripTags(item.firstChild.text).split(' - ');
      song.name = artistTitle[1];
      song.artist = artistTitle[0];
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load new songs');
  }
}

class SongsWidget extends StatelessWidget {
  final Future<List<SongLink>> songs;

  SongsWidget({Key key, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Les nouvelles entrées'),
      ),
      body: Center(
        child: FutureBuilder<List<SongLink>>(
          future: songs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SongListingWidget(snapshot.data);
            } else if (snapshot.hasError) {
              return ErrorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
