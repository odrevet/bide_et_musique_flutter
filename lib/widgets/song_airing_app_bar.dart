import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';

class SongAiringAppBar extends StatefulWidget with PreferredSizeWidget {
  @override
  final Size preferredSize;
  final Future<SongAiring>? _songAiring;
  final Orientation _orientation;

  SongAiringAppBar(this._orientation, this._songAiring, {Key? key})
      : preferredSize = Size.fromHeight(50.0),
        super(key: key);

  @override
  _SongAiringAppBarState createState() => _SongAiringAppBarState();
}

class _SongAiringAppBarState extends State<SongAiringAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongAiring>(
      future: widget._songAiring,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SongAiring songAiring = snapshot.data!;

          String? subtitle = songAiring.artist!;
          if (songAiring.year != 0) subtitle += ' • ${songAiring.year!}';
          subtitle += ' • ${songAiring.program.name!}';

          Widget title;

          if (widget._orientation == Orientation.portrait) {
            title = RichText(
              softWrap: false,
              overflow: TextOverflow.fade,
              text: TextSpan(
                text: songAiring.name,
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
              '${songAiring.name} • $subtitle',
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
