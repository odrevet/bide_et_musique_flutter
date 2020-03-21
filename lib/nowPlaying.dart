import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'program.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class SongNowPlaying extends Song {
  final int elapsedPcent;
  final int nbListeners;
  final Program program;

  SongNowPlaying.fromJson(Map<String, dynamic> json)
      : elapsedPcent = json['now']['elapsed_pcent'],
        nbListeners = json['now']['nb_listeners'],
        program = Program(
            id: json['now']['program']['id'],
            name: json['now']['program']['name']),
        super.fromJson(json);
}

Future<SongNowPlaying> fetchNowPlaying() async {
  final url = '$baseUri/wapi/song/now';
  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);
      return SongNowPlaying.fromJson(decodedJson);
    } catch (e) {
      print('ERROR $e');
    }
  } else {
    print('Response was ${responseJson.statusCode}');
  }
}

class NowPlayingWidget extends StatefulWidget {
  Future<Song> _song;

  NowPlayingWidget(this._song, {Key key}) : super(key: key);

  @override
  _NowPlayingWidgetState createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget> {
  _NowPlayingWidgetState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Song>(
        future: widget._song,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SongCardWidget(songLink: snapshot.data);
          } else if (snapshot.hasError) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  errorDisplay(snapshot.error),
                  RaisedButton.icon(
                    icon: Icon(Icons.refresh),
                    onPressed: () => setState(() {
                      widget._song = fetchNowPlaying();
                    }),
                    label: Text('Ré-essayer maintenant'),
                  )
                ]);
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
