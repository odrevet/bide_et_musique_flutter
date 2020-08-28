import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../utils.dart';
import 'song.dart';

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
            return CoverWithGesture(
                songLink: snapshot.data,
                displayPlaceholder: false,
                fadeInDuration: Duration());
          } else if (snapshot.hasError) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [ErrorDisplay(snapshot.error)]);
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
          String name = songNowPlaying.name;
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
            name += ' • $subtitle';
          }

          return AppBar(title: Text(name), bottom: bottom);
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Erreur"));
        }

        return AppBar(title: Text(""));
      },
    );
  }
}
