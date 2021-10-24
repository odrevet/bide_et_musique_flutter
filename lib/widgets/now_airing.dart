import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../utils.dart';
import 'cover.dart';

class NowAiringCard extends StatefulWidget {
  final Future<Song> _song;

  NowAiringCard(this._song, {Key? key}) : super(key: key);

  @override
  _NowAiringCardState createState() => _NowAiringCardState();
}

class _NowAiringCardState extends State<NowAiringCard> {
  _NowAiringCardState();

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

class SongNowAiringAppBar extends StatefulWidget with PreferredSizeWidget {
  @override
  final Size preferredSize;
  final Future<SongNowAiring>? _songNowAiring;
  final Orientation _orientation;

  SongNowAiringAppBar(this._orientation, this._songNowAiring, {Key? key})
      : preferredSize = Size.fromHeight(50.0),
        super(key: key);

  @override
  _SongNowAiringAppBarState createState() => _SongNowAiringAppBarState();
}

class _SongNowAiringAppBarState extends State<SongNowAiringAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongNowAiring>(
      future: widget._songNowAiring,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SongNowAiring songNowAiring = snapshot.data!;

          String? subtitle = songNowAiring.artist!;
          if (songNowAiring.year != 0) subtitle += ' • ${songNowAiring.year!}';
          subtitle += ' • ${songNowAiring.program.name!}';

          Widget title;

          if (widget._orientation == Orientation.portrait) {
            title = RichText(
              softWrap: false,
              overflow: TextOverflow.fade,
              text: TextSpan(
                text: songNowAiring.name,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                children: <TextSpan>[
                  TextSpan(
                    text: '\n$subtitle',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontSize: 14),
                  ),
                ],
              ),
            );
          } else {
            title = Text(
              '${songNowAiring.name} • $subtitle',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            );
          }

          return AppBar(title: title);
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Erreur"));
        }

        return AppBar(title: Text(""));
      },
    );
  }
}
