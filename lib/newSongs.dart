import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'utils.dart';
import 'song.dart';

Future<List<Song>> fetchNewSongs() async {
  var songs = <Song>[];
  final url = '$baseUri/new_song.rss';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = xml.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.children[2].text;
      var song = Song();
      song.id = extractSongId(link);
      song.title = item.firstChild.text;
      song.artist = '';
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load new songs');
  }
}

class SongsWidget extends StatelessWidget {
  final Future<List<Song>> songs;

  SongsWidget({Key key, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Les nouvelles entrées'),
      ),
      body: Center(
        child: FutureBuilder<List<Song>>(
          future: songs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Song> songs) {
    var rows = <ListTile>[];
    for (Song song in songs) {
      rows.add(ListTile(
        leading:  CircleAvatar(
          backgroundColor: Colors.black12,
          child:  Image(
              image:
                   NetworkImage('$baseUri/images/thumb25/${song.id}.jpg')),
        ),
        title: Text(
          song.title,
        ),
        subtitle: Text(song.artist),
        onTap: () {
          Navigator.push(
              context,
               MaterialPageRoute(
                  builder: (context) =>  SongPageWidget(
                      song: song,
                      songInformations: fetchSongInformations(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}
