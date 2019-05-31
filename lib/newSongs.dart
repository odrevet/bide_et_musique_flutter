import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import 'song.dart';
import 'utils.dart';

Future<List<SongLink>> fetchNewSongs() async {
  var songs = <SongLink>[];
  final url = '$baseUri/new_song.rss';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = xml.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.children[2].text;
      var song = SongLink();
      song.id = extractSongId(link);
      var artistTitle = stripTags(item.firstChild.text).split('-');
      song.title = artistTitle[0];
      song.artist = artistTitle[1];
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
              return errorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
