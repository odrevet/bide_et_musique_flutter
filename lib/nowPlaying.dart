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
  try {
    final responseJson = await Session.get(url);
    if (responseJson.statusCode == 200) {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);
      return SongNowPlaying.fromJson(decodedJson);
    } else {
      throw ('Response was ${responseJson.statusCode}');
    }
  } catch (e) {
    print('ERROR $e');
    rethrow;
  }
}

class InheritedSongNowPlaying extends InheritedWidget {
  const InheritedSongNowPlaying(
      {Key key, @required this.songNowPlaying, @required Widget child})
      : super(key: key, child: child);

  final Future<SongNowPlaying> songNowPlaying;

  static InheritedSongNowPlaying of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedSongNowPlaying>();
  }

  @override
  bool updateShouldNotify(InheritedSongNowPlaying old) =>
      songNowPlaying != old.songNowPlaying;
}

class NowPlayingCard extends StatefulWidget {
  final Future<Song> _song;

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
            return Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 20.0,
                  ),
                ]),
                child: SongCardWidget(songLink: snapshot.data));
          } else if (snapshot.hasError) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [errorDisplay(snapshot.error)]);
          }

          return Container();
        },
      ),
    );
  }
}

class SongNowPlayingAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Future<SongNowPlaying> _songNowPlaying;
  final Orientation _orientation;

  SongNowPlayingAppBar(this._orientation, this._songNowPlaying, {Key key})
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
          String title = songNowPlaying.title;
          String subtitle = songNowPlaying.artist;
          Widget bottom;

          if (songNowPlaying.year != 0) subtitle += ' • ${songNowPlaying.year}';
          subtitle += ' • ${songNowPlaying.program.name}';

          if (widget._orientation == Orientation.portrait) {
            bottom = PreferredSize(
                child: Padding(
                  padding: const EdgeInsets.only(left: 75.0),
                  child: Align(
                      alignment: FractionalOffset.centerLeft,
                      child: Text(subtitle)),
                ),
                preferredSize: null);
          } else {
            title += ' • $subtitle';
          }

          return AppBar(title: Text(title), bottom: bottom);
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Erreur"));
        }

        return AppBar(title: Text(""));
      },
    );
  }
}

class NowPlayingSongPosition extends StatefulWidget {
  final Future<SongNowPlaying> _songNowPlaying;

  NowPlayingSongPosition(this._songNowPlaying);

  _NowPlayingSongPositionState createState() => _NowPlayingSongPositionState();
}

class _NowPlayingSongPositionState extends State<NowPlayingSongPosition> {
  var _currentPosition;
  Timer _timer;
  int _currentSongId;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongNowPlaying>(
      future: widget._songNowPlaying,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SongNowPlaying songNowPlaying = snapshot.data;
          if (_currentSongId != songNowPlaying.id) {
            _currentPosition = (songNowPlaying.duration.inSeconds *
                    songNowPlaying.elapsedPcent /
                    100)
                .ceil();
            if (_timer != null && _timer.isActive) _timer.cancel();
            _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
              setState(() {
                if (_currentPosition >= songNowPlaying.duration.inSeconds) {
                  _timer.cancel();
                } else {
                  _currentPosition += 1;
                }
              });
            });
          }

          _currentSongId = songNowPlaying.id;
          return Text(
              '$_currentPosition /  ${songNowPlaying.duration.inSeconds}');
        } else if (snapshot.hasError) {
          return Text('?? m ?? s / ?? m ?? s');
        }
        return Text('-- m -- s/ -- m -- s');
      },
    );
  }
}
