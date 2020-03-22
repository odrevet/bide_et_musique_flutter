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
            name: stripTags(json['now']['program']['name'])),
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

class NowPlayingCard extends StatefulWidget {
  Future<Song> _song;

  NowPlayingCard(this._song, {Key key}) : super(key: key);

  @override
  _NowPlayingCardState createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard> {
  _NowPlayingCardState();

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

class SongNowPlayingAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Future<SongNowPlaying> _songNowPlaying;

  SongNowPlayingAppBar(this._songNowPlaying, {Key key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _SongNowPlayingAppBarState createState() => _SongNowPlayingAppBarState();
}

class _SongNowPlayingAppBarState extends State<SongNowPlayingAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongNowPlaying>(
      future: widget._songNowPlaying,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SongNowPlaying songNowPlaying = snapshot.data;
          return AppBar(
              title: Text(songNowPlaying.title),
              bottom: PreferredSize(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 75.0),
                    child: Align(
                        alignment: FractionalOffset.centerLeft,
                        child: Text(
                            '${songNowPlaying.artist} • ${songNowPlaying.year}  • ${songNowPlaying.program.name}')),
                  ),
                  preferredSize: null));
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Erreur"));
        }

        // By default, show a loading spinner
        return AppBar(title: Text("Chargement"));
      },
    );
  }
}
