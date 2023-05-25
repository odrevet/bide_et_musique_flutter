import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';

class SongAiringTitle extends StatefulWidget {
  @override
  final Future<SongAiring>? _songAiring;
  final Orientation _orientation;

  const SongAiringTitle(this._orientation, this._songAiring, {Key? key})
      : super(key: key);

  @override
  State<SongAiringTitle> createState() => _SongAiringTitleState();
}

class _SongAiringTitleState extends State<SongAiringTitle> {
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
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                children: <TextSpan>[
                  TextSpan(
                    text: '\n$subtitle',
                    style: const TextStyle(
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
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            );
          }

          return title;
        } else if (snapshot.hasError) {
          return const Text("Erreur");
        }

        return const Text("Chargement");
      },
    );
  }
}
